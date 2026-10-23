// GERADO por scripts/gen-api.mjs a partir de backend/openapi.json. Não edite à mão.

export type AuthTokens = {
  accessToken: string;
  refreshToken: string;
};

export type KpiReport = {
  matches: number;
  kpis: Array<{
    key: string;
    label: string;
    value: number | null;
    unit: "ms" | "percent" | "s" | "count";
    n: number;
    source: "server" | "client";
    limit: number | null;
    limitLabel: string | null;
    withinLimit: boolean | null;
  }>;
};

export type AdminMatchList = {
  page: number;
  pageSize: number;
  total: number;
  matches: Array<{
    matchId: string;
    status: "assigned" | "running" | "finished" | "aborted";
    seed: number;
    serverHost: string;
    serverPort: number;
    createdAt: string;
    startedAt: string | null;
    lastHeartbeatAt: string | null;
    endedAt: string | null;
    endReason: string | null;
    durationS: number | null;
    players: Array<{
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
    }>;
  }>;
};
