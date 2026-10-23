import { Injectable } from '@nestjs/common';
import { and, desc, eq, inArray, isNotNull, lt, ne, sql } from 'drizzle-orm';
import { alias } from 'drizzle-orm/pg-core';
import { Match, matches, matchPlayers, users } from '../../drizzle/schema';
import { Database } from '../db/database';

export interface NewPlayer {
  userId: string;
  /** Hash do token DESTE jogador (§4.3): vazar `match_players` não vaza token utilizável. */
  tokenHash: string;
}

export interface NewMatch {
  id: string;
  players: NewPlayer[];
  serverHost: string;
  serverPort: number;
  seed: number;
  now: Date;
}

export interface PlayerResult {
  userId: string;
  heroId: string;
  kills: number;
  deaths: number;
  finalLevel: number;
  damageDealt: number;
  damageTaken: number;
  monstersKilled: number;
  chestsOpened: number;
  bossKill: boolean;
  setActive?: string | null;
  levelAtPhase1End?: number | null;
  avgPingMs?: number | null;
  teleportCount?: number | null;
}

/** `MatchResult` do game server (ARCHITECTURE-LAUNCHER §4.2 passo 7). */
export interface MatchResult {
  winnerUserId: string | null;
  endReason: string;
  durationS: number;
  players: PlayerResult[];
}

/** Lado de uma conta numa partida terminada. `heroId` nulo = a partida acabou sem estatística (abortada). */
export interface HistorySide {
  heroId: string | null;
  kills: number;
  finalLevel: number;
}

/** O oponente é identificado pelo herói e pelo `#nickname` (nulo em conta anterior ao F35), nunca pelo e-mail. */
export interface HistoryOpponent extends HistorySide {
  nickname: string | null;
}

/** Uma partida terminada vista por uma conta. O oponente é só o lado dele: sem id, e-mail nem token. */
export interface HistoryEntry {
  matchId: string;
  status: 'finished' | 'aborted';
  playedAt: Date;
  endReason: string | null;
  durationS: number | null;
  winnerUserId: string | null;
  me: HistorySide & { deaths: number; bossKill: boolean; setActive: string | null };
  opponent: HistoryOpponent | null;
}

export interface WinLossRecord {
  wins: number;
  losses: number;
}

const ACTIVE = ['assigned', 'running'] as const;
const TERMINAL = ['finished', 'aborted'] as const;

/** Todas as transições são condicionais ao estado de origem: `false` = a partida já estava em outro estado. */
export abstract class MatchesRepository {
  abstract createAssigned(match: NewMatch): Promise<void>;
  abstract findById(id: string): Promise<Match | null>;
  abstract playerIds(matchId: string): Promise<string[]>;
  /** `null` = a conta não está na partida. */
  abstract playerTokenHash(matchId: string, userId: string): Promise<string | null>;
  /** Conta em `assigned` ou `running` (I8 vale também para a partida em curso). */
  abstract userHasActiveMatch(userId: string): Promise<boolean>;
  abstract markRunning(id: string, now: Date): Promise<boolean>;
  abstract touchHeartbeat(id: string, now: Date): Promise<boolean>;
  abstract finish(id: string, result: MatchResult, now: Date): Promise<boolean>;
  abstract abort(id: string, reason: string, now: Date): Promise<boolean>;
  abstract findAssignedBefore(createdBefore: Date): Promise<Match[]>;
  abstract findRunningWithHeartbeatBefore(heartbeatBefore: Date): Promise<Match[]>;
  /** Boot do backend: os containers sumiram, então nenhuma partida ativa continua. */
  abstract abortAllActive(reason: string, now: Date): Promise<number>;
  /** Partidas terminadas (finished/aborted) da conta, a mais recente primeiro. */
  abstract historyOf(userId: string, limit: number): Promise<HistoryEntry[]>;
  /** Vitórias e derrotas da conta em TODAS as partidas terminadas (aborted e sem vencedor não contam). */
  abstract recordOf(userId: string): Promise<WinLossRecord>;
}

@Injectable()
export class DrizzleMatchesRepository extends MatchesRepository {
  constructor(private readonly database: Database) {
    super();
  }

  async createAssigned(match: NewMatch): Promise<void> {
    await this.database.db.transaction(async (tx) => {
      await tx.insert(matches).values({
        id: match.id,
        serverHost: match.serverHost,
        serverPort: match.serverPort,
        seed: match.seed,
        createdAt: match.now,
      });
      await tx
        .insert(matchPlayers)
        .values(match.players.map(({ userId, tokenHash }) => ({ matchId: match.id, userId, tokenHash })));
    });
  }

  async findById(id: string): Promise<Match | null> {
    const [match] = await this.database.db.select().from(matches).where(eq(matches.id, id));
    return match ?? null;
  }

  async playerIds(matchId: string): Promise<string[]> {
    const rows = await this.database.db
      .select({ userId: matchPlayers.userId })
      .from(matchPlayers)
      .where(eq(matchPlayers.matchId, matchId));
    return rows.map((row) => row.userId);
  }

  async playerTokenHash(matchId: string, userId: string): Promise<string | null> {
    const [row] = await this.database.db
      .select({ tokenHash: matchPlayers.tokenHash })
      .from(matchPlayers)
      .where(and(eq(matchPlayers.matchId, matchId), eq(matchPlayers.userId, userId)));
    return row?.tokenHash ?? null;
  }

  async userHasActiveMatch(userId: string): Promise<boolean> {
    const rows = await this.database.db
      .select({ id: matches.id })
      .from(matchPlayers)
      .innerJoin(matches, eq(matches.id, matchPlayers.matchId))
      .where(and(eq(matchPlayers.userId, userId), inArray(matches.status, [...ACTIVE])))
      .limit(1);
    return rows.length > 0;
  }

  async markRunning(id: string, now: Date): Promise<boolean> {
    const rows = await this.database.db
      .update(matches)
      .set({ status: 'running', startedAt: now, lastHeartbeatAt: now })
      .where(and(eq(matches.id, id), eq(matches.status, 'assigned')))
      .returning({ id: matches.id });
    return rows.length > 0;
  }

  async touchHeartbeat(id: string, now: Date): Promise<boolean> {
    const rows = await this.database.db
      .update(matches)
      .set({ lastHeartbeatAt: now })
      .where(and(eq(matches.id, id), eq(matches.status, 'running')))
      .returning({ id: matches.id });
    return rows.length > 0;
  }

  finish(id: string, result: MatchResult, now: Date): Promise<boolean> {
    return this.database.db.transaction(async (tx) => {
      const rows = await tx
        .update(matches)
        .set({
          status: 'finished',
          endedAt: now,
          winnerUserId: result.winnerUserId,
          endReason: result.endReason,
          durationS: result.durationS,
        })
        .where(and(eq(matches.id, id), eq(matches.status, 'running')))
        .returning({ id: matches.id });
      if (rows.length === 0) return false;
      for (const { userId, ...stats } of result.players) {
        await tx
          .update(matchPlayers)
          .set(stats)
          .where(and(eq(matchPlayers.matchId, id), eq(matchPlayers.userId, userId)));
      }
      return true;
    });
  }

  async abort(id: string, reason: string, now: Date): Promise<boolean> {
    const rows = await this.database.db
      .update(matches)
      .set({ status: 'aborted', endedAt: now, endReason: reason })
      .where(and(eq(matches.id, id), inArray(matches.status, [...ACTIVE])))
      .returning({ id: matches.id });
    return rows.length > 0;
  }

  findAssignedBefore(createdBefore: Date): Promise<Match[]> {
    return this.database.db
      .select()
      .from(matches)
      .where(and(eq(matches.status, 'assigned'), lt(matches.createdAt, createdBefore)));
  }

  findRunningWithHeartbeatBefore(heartbeatBefore: Date): Promise<Match[]> {
    return this.database.db
      .select()
      .from(matches)
      .where(and(eq(matches.status, 'running'), lt(matches.lastHeartbeatAt, heartbeatBefore)));
  }

  async abortAllActive(reason: string, now: Date): Promise<number> {
    const rows = await this.database.db
      .update(matches)
      .set({ status: 'aborted', endedAt: now, endReason: reason })
      .where(inArray(matches.status, [...ACTIVE]))
      .returning({ id: matches.id });
    return rows.length;
  }

  async historyOf(userId: string, limit: number): Promise<HistoryEntry[]> {
    const mine = alias(matchPlayers, 'mine');
    const theirs = alias(matchPlayers, 'theirs');
    const opponentUser = alias(users, 'opponent_user');
    const rows = await this.database.db
      .select({
        matchId: matches.id,
        status: matches.status,
        createdAt: matches.createdAt,
        endedAt: matches.endedAt,
        endReason: matches.endReason,
        durationS: matches.durationS,
        winnerUserId: matches.winnerUserId,
        mine: {
          heroId: mine.heroId,
          kills: mine.kills,
          deaths: mine.deaths,
          finalLevel: mine.finalLevel,
          bossKill: mine.bossKill,
          setActive: mine.setActive,
        },
        // O id do oponente nem sai do banco: só o que a tela mostra.
        theirs: {
          heroId: theirs.heroId,
          nickname: opponentUser.nickname,
          kills: theirs.kills,
          finalLevel: theirs.finalLevel,
        },
        hasOpponent: isNotNull(theirs.matchId),
      })
      .from(mine)
      .innerJoin(matches, eq(matches.id, mine.matchId))
      .leftJoin(theirs, and(eq(theirs.matchId, mine.matchId), ne(theirs.userId, mine.userId)))
      .leftJoin(opponentUser, eq(opponentUser.id, theirs.userId))
      .where(and(eq(mine.userId, userId), inArray(matches.status, [...TERMINAL])))
      .orderBy(desc(sql`coalesce(${matches.endedAt}, ${matches.createdAt})`), desc(matches.id))
      .limit(limit);
    return rows.map((row) => ({
      matchId: row.matchId,
      status: row.status as HistoryEntry['status'],
      playedAt: row.endedAt ?? row.createdAt,
      endReason: row.endReason,
      durationS: row.durationS,
      winnerUserId: row.winnerUserId,
      me: row.mine,
      // O join com `users` torna cada coluna do oponente anulável; `hasOpponent` garante a linha.
      opponent: row.hasOpponent
        ? {
            heroId: row.theirs.heroId,
            nickname: row.theirs.nickname,
            kills: row.theirs.kills ?? 0,
            finalLevel: row.theirs.finalLevel ?? 0,
          }
        : null,
    }));
  }

  async recordOf(userId: string): Promise<WinLossRecord> {
    const [row] = await this.database.db
      .select({
        wins: sql<number>`count(*) filter (where ${matches.winnerUserId} = ${userId})::int`,
        losses: sql<number>`count(*) filter (where ${matches.winnerUserId} is not null and ${matches.winnerUserId} <> ${userId})::int`,
      })
      .from(matchPlayers)
      .innerJoin(matches, eq(matches.id, matchPlayers.matchId))
      .where(and(eq(matchPlayers.userId, userId), eq(matches.status, 'finished')));
    return { wins: row?.wins ?? 0, losses: row?.losses ?? 0 };
  }
}
