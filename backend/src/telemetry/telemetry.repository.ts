import { Injectable } from '@nestjs/common';
import { and, count, desc, eq, inArray, SQL, sql } from 'drizzle-orm';
import { matches, MatchStatus, matchPlayers, users } from '../../drizzle/schema';
import { Database } from '../db/database';
import type { KpiMatch } from './kpis';

export interface MatchFilter {
  endReason?: string;
  /** Partidas em que algum dos dois jogou com esse herói. */
  heroId?: string;
}

/** Jogador como o painel vê: sem id de conta, e-mail nem hash de token. */
export interface AdminPlayerRow {
  nickname: string | null;
  isWinner: boolean;
  heroId: string | null;
  kills: number;
  deaths: number;
  finalLevel: number;
  damageDealt: number;
  damageTaken: number;
  monstersKilled: number;
  chestsOpened: number;
  bossKill: boolean;
  setActive: string | null;
  levelAtPhase1End: number | null;
  avgPingMs: number | null;
  teleportCount: number | null;
}

export interface AdminMatchRow {
  matchId: string;
  status: MatchStatus;
  seed: number;
  serverHost: string;
  serverPort: number;
  createdAt: Date;
  startedAt: Date | null;
  lastHeartbeatAt: Date | null;
  endedAt: Date | null;
  endReason: string | null;
  durationS: number | null;
  players: AdminPlayerRow[];
}

export abstract class TelemetryRepository {
  /** Base dos KPIs: só partidas `finished` com pelo menos uma linha de jogador. */
  abstract kpiMatches(): Promise<KpiMatch[]>;
  /** Mais recente primeiro (`createdAt`, depois `id`), todos os status. */
  abstract listMatches(filter: MatchFilter, limit: number, offset: number): Promise<AdminMatchRow[]>;
  abstract countMatches(filter: MatchFilter): Promise<number>;
  abstract allMatches(filter: MatchFilter): Promise<AdminMatchRow[]>;
}

function whereOf(filter: MatchFilter): SQL | undefined {
  const parts: SQL[] = [];
  if (filter.endReason !== undefined) parts.push(eq(matches.endReason, filter.endReason));
  if (filter.heroId !== undefined) {
    parts.push(
      sql`exists (select 1 from ${matchPlayers} where ${matchPlayers.matchId} = ${matches.id} and ${matchPlayers.heroId} = ${filter.heroId})`,
    );
  }
  return parts.length ? and(...parts) : undefined;
}

// ponytail: KPIs e CSV leem todas as partidas em memória (playtest: centenas); agregar em SQL se passar de milhares.
@Injectable()
export class DrizzleTelemetryRepository extends TelemetryRepository {
  constructor(private readonly database: Database) {
    super();
  }

  async kpiMatches(): Promise<KpiMatch[]> {
    const rows = await this.database.db
      .select({
        matchId: matches.id,
        durationS: matches.durationS,
        avgPingMs: matchPlayers.avgPingMs,
        levelAtPhase1End: matchPlayers.levelAtPhase1End,
        teleportCount: matchPlayers.teleportCount,
        isWinner: sql<boolean>`coalesce(${matches.winnerUserId} = ${matchPlayers.userId}, false)`,
      })
      .from(matchPlayers)
      .innerJoin(matches, eq(matches.id, matchPlayers.matchId))
      .where(eq(matches.status, 'finished'));
    const byMatch = new Map<string, KpiMatch>();
    for (const { matchId, durationS, ...player } of rows) {
      const entry = byMatch.get(matchId) ?? { durationS, players: [] };
      entry.players.push(player);
      byMatch.set(matchId, entry);
    }
    return [...byMatch.values()];
  }

  async countMatches(filter: MatchFilter): Promise<number> {
    const [row] = await this.database.db.select({ total: count() }).from(matches).where(whereOf(filter));
    return row?.total ?? 0;
  }

  listMatches(filter: MatchFilter, limit: number, offset: number): Promise<AdminMatchRow[]> {
    return this.fetchMatches(filter, { limit, offset });
  }

  allMatches(filter: MatchFilter): Promise<AdminMatchRow[]> {
    return this.fetchMatches(filter);
  }

  private async fetchMatches(filter: MatchFilter, page?: { limit: number; offset: number }): Promise<AdminMatchRow[]> {
    const { db } = this.database;
    const base = db
      .select({
        matchId: matches.id,
        status: matches.status,
        seed: matches.seed,
        serverHost: matches.serverHost,
        serverPort: matches.serverPort,
        createdAt: matches.createdAt,
        startedAt: matches.startedAt,
        lastHeartbeatAt: matches.lastHeartbeatAt,
        endedAt: matches.endedAt,
        endReason: matches.endReason,
        durationS: matches.durationS,
      })
      .from(matches)
      .where(whereOf(filter))
      .orderBy(desc(matches.createdAt), desc(matches.id));
    const rows = page ? await base.limit(page.limit).offset(page.offset) : await base;
    const playersByMatch = await this.playersOf(rows.map((row) => row.matchId));
    return rows.map((row) => ({ ...row, players: playersByMatch.get(row.matchId) ?? [] }));
  }

  private async playersOf(matchIds: string[]): Promise<Map<string, AdminPlayerRow[]>> {
    const grouped = new Map<string, AdminPlayerRow[]>();
    if (matchIds.length === 0) return grouped;
    const rows = await this.database.db
      .select({
        matchId: matchPlayers.matchId,
        nickname: users.nickname,
        isWinner: sql<boolean>`coalesce(${matches.winnerUserId} = ${matchPlayers.userId}, false)`,
        heroId: matchPlayers.heroId,
        kills: matchPlayers.kills,
        deaths: matchPlayers.deaths,
        finalLevel: matchPlayers.finalLevel,
        damageDealt: matchPlayers.damageDealt,
        damageTaken: matchPlayers.damageTaken,
        monstersKilled: matchPlayers.monstersKilled,
        chestsOpened: matchPlayers.chestsOpened,
        bossKill: matchPlayers.bossKill,
        setActive: matchPlayers.setActive,
        levelAtPhase1End: matchPlayers.levelAtPhase1End,
        avgPingMs: matchPlayers.avgPingMs,
        teleportCount: matchPlayers.teleportCount,
      })
      .from(matchPlayers)
      .innerJoin(matches, eq(matches.id, matchPlayers.matchId))
      .innerJoin(users, eq(users.id, matchPlayers.userId))
      // Ordem estável entre as duas linhas sem expor a chave: a ordenação usa a conta, a saída não.
      .where(inArray(matchPlayers.matchId, matchIds))
      .orderBy(matchPlayers.matchId, matchPlayers.userId);
    for (const { matchId, ...player } of rows) {
      grouped.set(matchId, [...(grouped.get(matchId) ?? []), player]);
    }
    return grouped;
  }
}
