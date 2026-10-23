import { Injectable } from '@nestjs/common';
import { matchesToCsv } from './csv';
import { computeKpis, KpiReport } from './kpis';
import { ADMIN_PAGE_SIZE, AdminMatch, AdminMatchList } from './telemetry.dto';
import { AdminMatchRow, MatchFilter, TelemetryRepository } from './telemetry.repository';

const iso = (date: Date | null): string | null => (date ? date.toISOString() : null);

/** Whitelist explícita: o que não está aqui não sai na resposta. */
function toAdminMatch(row: AdminMatchRow): AdminMatch {
  return {
    matchId: row.matchId,
    status: row.status,
    seed: row.seed,
    serverHost: row.serverHost,
    serverPort: row.serverPort,
    createdAt: row.createdAt.toISOString(),
    startedAt: iso(row.startedAt),
    lastHeartbeatAt: iso(row.lastHeartbeatAt),
    endedAt: iso(row.endedAt),
    endReason: row.endReason,
    durationS: row.durationS,
    players: row.players.map((player) => ({
      nickname: player.nickname,
      isWinner: player.isWinner,
      heroId: player.heroId,
      kills: player.kills,
      deaths: player.deaths,
      finalLevel: player.finalLevel,
      damageDealt: player.damageDealt,
      damageTaken: player.damageTaken,
      monstersKilled: player.monstersKilled,
      chestsOpened: player.chestsOpened,
      bossKill: player.bossKill,
      setActive: player.setActive,
      levelAtPhase1End: player.levelAtPhase1End,
      avgPingMs: player.avgPingMs,
      teleportCount: player.teleportCount,
    })),
  };
}

@Injectable()
export class TelemetryService {
  constructor(private readonly repo: TelemetryRepository) {}

  async kpis(): Promise<KpiReport> {
    return computeKpis(await this.repo.kpiMatches());
  }

  async matches(filter: MatchFilter, page: number): Promise<AdminMatchList> {
    const [total, rows] = await Promise.all([
      this.repo.countMatches(filter),
      this.repo.listMatches(filter, ADMIN_PAGE_SIZE, (page - 1) * ADMIN_PAGE_SIZE),
    ]);
    return { page, pageSize: ADMIN_PAGE_SIZE, total, matches: rows.map(toAdminMatch) };
  }

  /** O mesmo conteúdo da lista, de todas as páginas. */
  async matchesCsv(filter: MatchFilter): Promise<string> {
    return matchesToCsv((await this.repo.allMatches(filter)).map(toAdminMatch));
  }
}
