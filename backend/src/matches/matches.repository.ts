import { Injectable } from '@nestjs/common';
import { and, eq, inArray, lt } from 'drizzle-orm';
import { Match, matches, matchPlayers } from '../../drizzle/schema';
import { Database } from '../db/database';

export interface NewMatch {
  id: string;
  playerIds: string[];
  serverHost: string;
  serverPort: number;
  tokenHash: string;
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
}

/** `MatchResult` do game server (ARCHITECTURE-LAUNCHER §4.2 passo 7). */
export interface MatchResult {
  winnerUserId: string | null;
  endReason: string;
  durationS: number;
  players: PlayerResult[];
}

const ACTIVE = ['assigned', 'running'] as const;

/** Todas as transições são condicionais ao estado de origem: `false` = a partida já estava em outro estado. */
export abstract class MatchesRepository {
  abstract createAssigned(match: NewMatch): Promise<void>;
  abstract findById(id: string): Promise<Match | null>;
  abstract playerIds(matchId: string): Promise<string[]>;
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
        tokenHash: match.tokenHash,
        seed: match.seed,
        createdAt: match.now,
      });
      await tx
        .insert(matchPlayers)
        .values(match.playerIds.map((userId) => ({ matchId: match.id, userId })));
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
}
