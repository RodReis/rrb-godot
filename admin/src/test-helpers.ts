import { vi } from 'vitest';
import { AdminMatch, AdminMatchList, AdminPlayer, Api, Kpi, KpiReport } from './api/client';

export function kpi(partial: Partial<Kpi> = {}): Kpi {
  return {
    key: 'ping_avg',
    label: 'Ping médio',
    value: 66.36,
    unit: 'ms',
    n: 11,
    source: 'server',
    limit: 80,
    limitLabel: '≤ 80 ms',
    withinLimit: true,
    ...partial,
  };
}

export function report(kpis: Kpi[], matches = 6): KpiReport {
  return { matches, kpis };
}

export function player(partial: Partial<AdminPlayer> = {}): AdminPlayer {
  return {
    nickname: 'Jogador',
    isWinner: false,
    heroId: 'knight',
    kills: 3,
    deaths: 1,
    finalLevel: 7,
    damageDealt: 1234.5,
    damageTaken: 800,
    monstersKilled: 12,
    chestsOpened: 2,
    bossKill: false,
    setActive: null,
    levelAtPhase1End: 5,
    avgPingMs: 50,
    teleportCount: 2,
    ...partial,
  };
}

export function match(partial: Partial<AdminMatch> = {}): AdminMatch {
  return {
    matchId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1',
    status: 'finished',
    seed: 99,
    serverHost: '203.0.113.9',
    serverPort: 7001,
    createdAt: '2026-10-23T12:00:00.000Z',
    startedAt: '2026-10-23T12:00:05.000Z',
    lastHeartbeatAt: null,
    endedAt: '2026-10-23T12:09:00.000Z',
    endReason: 'kill_goal',
    durationS: 540,
    players: [player({ nickname: 'Alfa', isWinner: true }), player({ nickname: 'Beta', heroId: 'rogue', teleportCount: null })],
    ...partial,
  };
}

export function matchList(matches: AdminMatch[], extra: Partial<AdminMatchList> = {}): AdminMatchList {
  return { page: 1, pageSize: 50, total: matches.length, matches, ...extra };
}

/** Api em memória: cada método é um `vi.fn()` que o teste pode sobrescrever. */
export function fakeApi(overrides: Partial<Api> = {}): { [K in keyof Api]: ReturnType<typeof vi.fn> } & Api {
  return {
    login: vi.fn().mockResolvedValue({ accessToken: 'jwt-de-teste', refreshToken: 'r' }),
    kpis: vi.fn().mockResolvedValue(report([kpi()])),
    matches: vi.fn().mockResolvedValue(matchList([match()])),
    matchesCsv: vi.fn().mockResolvedValue(new Blob(['a,b'])),
    ...overrides,
  } as { [K in keyof Api]: ReturnType<typeof vi.fn> } & Api;
}
