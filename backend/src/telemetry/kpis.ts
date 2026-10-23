/**
 * KPIs de playtest (SPEC-029 §4, PRD §9.2). Função pura: o repositório entrega só as partidas
 * `finished` com jogadores; nenhum id de conta passa por aqui (`isWinner` já vem resolvido).
 */
export interface KpiPlayer {
  avgPingMs: number | null;
  levelAtPhase1End: number | null;
  teleportCount: number | null;
  isWinner: boolean;
}

export interface KpiMatch {
  durationS: number | null;
  players: KpiPlayer[];
}

export type KpiUnit = 'ms' | 'percent' | 's' | 'count';

export interface Kpi {
  key: string;
  label: string;
  /** `null` = sem dados (N = 0). */
  value: number | null;
  unit: KpiUnit;
  /** Quantas partidas ou jogador-partida entraram no cálculo. */
  n: number;
  /** `server`: medido pelo servidor autoritativo; `client`: relatado pelo cliente (não confiável). */
  source: 'server' | 'client';
  /** Limite do PRD §9.2 (mesma unidade do valor); `null` = o PRD não fixa limite. */
  limit: number | null;
  limitLabel: string | null;
  /** `null` = sem limite ou sem dados. */
  withinLimit: boolean | null;
}

export interface KpiReport {
  /** Partidas `finished` com pelo menos uma linha de jogador. */
  matches: number;
  kpis: Kpi[];
}

export const PING_LIMIT_MS = 80;
export const DURATION_LIMIT_S = 600;
export const LEADER_WINS_LIMIT_PERCENT = 75;
const DECIMALS = 100;
const PERCENT = 100;

const round = (value: number): number => Math.round(value * DECIMALS) / DECIMALS;
const sum = (values: number[]): number => values.reduce((total, value) => total + value, 0);
const percent = (part: number, whole: number): number => (part / whole) * PERCENT;
const present = (values: (number | null)[]): number[] => values.filter((v): v is number => v !== null);
const average = (values: number[]): number | null => (values.length ? sum(values) / values.length : null);
const share = (values: number[], test: (v: number) => boolean): number | null =>
  values.length ? percent(values.filter(test).length, values.length) : null;

type Spec = Omit<Kpi, 'value' | 'n' | 'withinLimit'>;
const NO_LIMIT = { limit: null, limitLabel: null } as const;

function build(spec: Spec, n: number, raw: number | null, within?: (value: number) => boolean): Kpi {
  const value = raw === null || n === 0 ? null : round(raw);
  const withinLimit = value === null || !within ? null : within(value);
  return { ...spec, value, n, withinLimit };
}

interface F1Pair {
  tie: boolean;
  /** Nulo = vencedor indefinido (ninguém ou os dois marcados). */
  leaderWon: boolean | null;
}

/** Só partidas com os dois níveis da fase 1. */
function f1Pairs(matches: KpiMatch[]): F1Pair[] {
  const pairs: F1Pair[] = [];
  for (const { players } of matches) {
    const [a, b] = players;
    const la = a?.levelAtPhase1End;
    const lb = b?.levelAtPhase1End;
    if (!a || !b || players.length !== 2 || la == null || lb == null) continue;
    if (la === lb) {
      pairs.push({ tie: true, leaderWon: null });
      continue;
    }
    const winners = players.filter((player) => player.isWinner);
    pairs.push({ tie: false, leaderWon: winners.length === 1 ? winners[0] === (la > lb ? a : b) : null });
  }
  return pairs;
}

export function computeKpis(allMatches: KpiMatch[]): KpiReport {
  const matches = allMatches.filter((match) => match.players.length > 0);
  const pings = present(matches.flatMap((m) => m.players.map((pl) => pl.avgPingMs)));
  const durations = present(matches.map((m) => m.durationS));
  const teleports = present(matches.flatMap((m) => m.players.map((pl) => pl.teleportCount)));
  const pairs = f1Pairs(matches);
  const decided = pairs.filter((pair) => pair.leaderWon !== null);
  const server = { source: 'server' } as const;

  const kpis: Kpi[] = [
    build(
      { key: 'ping_avg', label: 'Ping médio', unit: 'ms', ...server, limit: PING_LIMIT_MS, limitLabel: '≤ 80 ms' },
      pings.length,
      average(pings),
      (v) => v <= PING_LIMIT_MS,
    ),
    build(
      { key: 'ping_over_limit', label: 'Ping acima de 80 ms', unit: 'percent', ...server, ...NO_LIMIT },
      pings.length,
      share(pings, (v) => v > PING_LIMIT_MS),
    ),
    build(
      { key: 'duration_avg', label: 'Duração média', unit: 's', ...server, ...NO_LIMIT },
      durations.length,
      average(durations),
    ),
    build(
      {
        key: 'duration_over_limit',
        label: 'Partidas acima de 10 min',
        unit: 'percent',
        ...server,
        limit: 0,
        limitLabel: '0 % (todas ≤ 10 min)',
      },
      durations.length,
      share(durations, (v) => v > DURATION_LIMIT_S),
      (v) => v === 0,
    ),
    build(
      {
        key: 'f1_leader_wins',
        label: 'Líder de nível F1 vence',
        unit: 'percent',
        ...server,
        limit: LEADER_WINS_LIMIT_PERCENT,
        limitLabel: '< 75 %',
      },
      decided.length,
      decided.length ? percent(decided.filter((pair) => pair.leaderWon).length, decided.length) : null,
      (v) => v < LEADER_WINS_LIMIT_PERCENT,
    ),
    // N = partidas com os dois níveis; o valor é a quantidade de empates, fora do % acima.
    build(
      { key: 'f1_ties', label: 'Empates de nível no F1', unit: 'count', ...server, ...NO_LIMIT },
      pairs.length,
      pairs.length ? pairs.filter((pair) => pair.tie).length : null,
    ),
    build(
      { key: 'teleports_total', label: 'Teleportes (total)', unit: 'count', source: 'client', ...NO_LIMIT },
      teleports.length,
      teleports.length ? sum(teleports) : null,
    ),
    build(
      { key: 'teleports_avg', label: 'Teleportes por jogador-partida', unit: 'count', source: 'client', ...NO_LIMIT },
      teleports.length,
      average(teleports),
    ),
  ];
  return { matches: matches.length, kpis };
}
