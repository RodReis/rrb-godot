import { computeKpis, Kpi, KpiMatch, KpiPlayer, KpiReport } from './kpis';

function p(partial: Partial<KpiPlayer>): KpiPlayer {
  return { avgPingMs: null, levelAtPhase1End: null, teleportCount: null, isWinner: false, ...partial };
}

/**
 * Massa feita à mão (cada número do teste sai desta tabela):
 *  M1 300 s  A ping 50  nv5 vence tele 2 | B ping 100 nv3 tele 1       -> líder (A) venceu
 *  M2 700 s  A ping 90  nv4              | B ping nulo nv6 vence tele 0  -> líder (B) venceu
 *  M3 600 s  A ping 80  nv5 vence        | B ping 80  nv5 tele nulo     -> empate no F1
 *  M4 nulo   A ping 10  nv nulo          | B ping 30  nv2 vence         -> sem os dois níveis
 *  M5 400 s  A ping 70  nv7              | B ping 60  nv3 vence tele 4  -> líder (A) perdeu
 *  M6 500 s  A ping 120 nv4              | B ping 40  nv2 (sem vencedor) -> níveis ok, vencedor indefinido
 */
const MATCHES: KpiMatch[] = [
  {
    durationS: 300,
    players: [
      p({ avgPingMs: 50, levelAtPhase1End: 5, isWinner: true, teleportCount: 2 }),
      p({ avgPingMs: 100, levelAtPhase1End: 3, teleportCount: 1 }),
    ],
  },
  {
    durationS: 700,
    players: [p({ avgPingMs: 90, levelAtPhase1End: 4 }), p({ levelAtPhase1End: 6, isWinner: true, teleportCount: 0 })],
  },
  {
    durationS: 600,
    players: [p({ avgPingMs: 80, levelAtPhase1End: 5, isWinner: true }), p({ avgPingMs: 80, levelAtPhase1End: 5 })],
  },
  {
    durationS: null,
    players: [p({ avgPingMs: 10 }), p({ avgPingMs: 30, levelAtPhase1End: 2, isWinner: true })],
  },
  {
    durationS: 400,
    players: [
      p({ avgPingMs: 70, levelAtPhase1End: 7 }),
      p({ avgPingMs: 60, levelAtPhase1End: 3, isWinner: true, teleportCount: 4 }),
    ],
  },
  {
    durationS: 500,
    players: [p({ avgPingMs: 120, levelAtPhase1End: 4 }), p({ avgPingMs: 40, levelAtPhase1End: 2 })],
  },
];

function kpi(report: KpiReport, key: string): Kpi {
  const found = report.kpis.find((k) => k.key === key);
  if (!found) throw new Error(`KPI ${key} ausente`);
  return found;
}

describe('computeKpis (SPEC-029 §4)', () => {
  const report = computeKpis(MATCHES);

  it('conta as partidas da base', () => {
    expect(report.matches).toBe(6);
  });

  it('ping médio: média dos jogador-partida não nulos (11 de 12), limite ≤ 80 ms', () => {
    expect(kpi(report, 'ping_avg')).toMatchObject({
      value: 66.36,
      n: 11,
      unit: 'ms',
      limit: 80,
      withinLimit: true,
      source: 'server',
    });
  });

  it('ping acima do limite: % com ping > 80 (o 80 exato não conta), sem limite no PRD', () => {
    expect(kpi(report, 'ping_over_limit')).toMatchObject({
      value: 27.27,
      n: 11,
      unit: 'percent',
      limit: null,
      withinLimit: null,
    });
  });

  it('duração média ignora duração nula (5 de 6 partidas)', () => {
    expect(kpi(report, 'duration_avg')).toMatchObject({ value: 500, n: 5, unit: 's', limit: null, withinLimit: null });
  });

  it('duração acima de 600 s: % de partidas; o limite é 0 % e 700 s o viola', () => {
    expect(kpi(report, 'duration_over_limit')).toMatchObject({ value: 20, n: 5, limit: 0, withinLimit: false });
  });

  it('líder F1 vence: só níveis diferentes e vencedor definido (M1, M2, M5): 2 de 3', () => {
    expect(kpi(report, 'f1_leader_wins')).toMatchObject({
      value: 66.67,
      n: 3,
      unit: 'percent',
      limit: 75,
      withinLimit: true,
    });
  });

  it('empates no F1: conta à parte (M3) e fora do percentual', () => {
    expect(kpi(report, 'f1_ties')).toMatchObject({ value: 1, n: 5, unit: 'count', limit: null, withinLimit: null });
  });

  it('teleportes: total e média só sobre contagem não nula (4 jogador-partida), rotulados como dado do cliente', () => {
    expect(kpi(report, 'teleports_total')).toMatchObject({
      value: 7,
      n: 4,
      source: 'client',
      limit: null,
      withinLimit: null,
    });
    expect(kpi(report, 'teleports_avg')).toMatchObject({ value: 1.75, n: 4, source: 'client' });
  });

  it('fora do limite: ping médio > 80 e líder vencendo 100 %', () => {
    const bad = computeKpis([
      {
        durationS: 100,
        players: [p({ avgPingMs: 150, levelAtPhase1End: 5, isWinner: true }), p({ avgPingMs: 90, levelAtPhase1End: 3 })],
      },
      {
        durationS: 100,
        players: [p({ avgPingMs: 81, levelAtPhase1End: 2 }), p({ avgPingMs: 99, levelAtPhase1End: 4, isWinner: true })],
      },
    ]);

    expect(kpi(bad, 'ping_avg')).toMatchObject({ value: 105, withinLimit: false });
    expect(kpi(bad, 'f1_leader_wins')).toMatchObject({ value: 100, n: 2, withinLimit: false });
    expect(kpi(bad, 'duration_over_limit')).toMatchObject({ value: 0, withinLimit: true });
  });

  it('exatamente 75 % de líder vencendo está fora (o limite é < 75 %)', () => {
    const lead = (won: boolean): KpiMatch => ({
      durationS: 1,
      players: [p({ levelAtPhase1End: 5, isWinner: won }), p({ levelAtPhase1End: 3, isWinner: !won })],
    });
    const edge = computeKpis([lead(true), lead(true), lead(true), lead(false)]);

    expect(kpi(edge, 'f1_leader_wins')).toMatchObject({ value: 75, n: 4, withinLimit: false });
  });

  it('sem dados: valores nulos, N zero e nenhum limite avaliado', () => {
    const empty = computeKpis([]);

    expect(empty.matches).toBe(0);
    for (const k of empty.kpis) expect(k).toMatchObject({ value: null, n: 0, withinLimit: null });
    expect(empty.kpis.map((k) => k.key)).toEqual(report.kpis.map((k) => k.key));
  });

  it('partida sem nenhuma linha de jogador fica fora da base', () => {
    const only = computeKpis([{ durationS: 900, players: [] }, MATCHES[0] as KpiMatch]);

    expect(only.matches).toBe(1);
    expect(kpi(only, 'duration_avg')).toMatchObject({ value: 300, n: 1 });
  });
});
