import { csvCell, matchesToCsv } from './csv';
import type { AdminMatch, AdminPlayer } from './telemetry.dto';

const player = (partial: Partial<AdminPlayer>): AdminPlayer => ({
  nickname: 'Rod',
  isWinner: false,
  heroId: 'arqueiro',
  kills: 1,
  deaths: 2,
  finalLevel: 3,
  damageDealt: 10.5,
  damageTaken: 4,
  monstersKilled: 5,
  chestsOpened: 6,
  bossKill: false,
  setActive: null,
  levelAtPhase1End: null,
  avgPingMs: 42,
  teleportCount: 0,
  ...partial,
});

const match = (players: AdminPlayer[]): AdminMatch => ({
  matchId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  status: 'finished',
  seed: 7,
  serverHost: '10.0.0.1',
  serverPort: 7000,
  createdAt: '2026-10-23T10:00:00.000Z',
  startedAt: '2026-10-23T10:00:05.000Z',
  lastHeartbeatAt: null,
  endedAt: '2026-10-23T10:09:00.000Z',
  endReason: 'kill_goal',
  durationS: 540,
  players,
});

describe('csvCell', () => {
  it.each([
    [null, ''],
    [12, '12'],
    [false, 'false'],
    ['simples', 'simples'],
    ['com,vírgula', '"com,vírgula"'],
    ['com "aspas"', '"com ""aspas"""'],
    ['duas\nlinhas', '"duas\nlinhas"'],
  ])('%j vira %j', (cell, expected) => {
    expect(csvCell(cell)).toBe(expected);
  });

  it.each(['=1+1', '+1', '-1', '@SUM(A1)'])('neutraliza fórmula de planilha em %s', (text) => {
    expect(csvCell(text)).toBe(`'${text}`);
  });

  it('número negativo não é tratado como fórmula', () => {
    expect(csvCell(-1)).toBe('-1');
  });
});

describe('matchesToCsv', () => {
  it('uma linha por jogador por partida, com o cabeçalho e CRLF', () => {
    const csv = matchesToCsv([match([player({ nickname: 'A', isWinner: true }), player({ nickname: 'B' })])]);
    const lines = csv.trimEnd().split('\r\n');

    expect(lines).toHaveLength(3);
    expect(lines[0]).toContain('matchId,status');
    expect(lines[0]).toContain('levelAtPhase1End,avgPingMs,teleportCount');
    expect(lines[1]).toContain(',A,true,arqueiro,1,2,3,10.5,');
    expect(lines[2]).toContain(',B,false,');
    expect(csv.endsWith('\r\n')).toBe(true);
  });

  it('partida sem jogador ainda aparece, com as colunas do jogador vazias', () => {
    const lines = matchesToCsv([match([])]).trimEnd().split('\r\n');

    expect(lines).toHaveLength(2);
    expect(lines[1]).toMatch(/,7000,{15}$/);
  });

  it('sem partidas: só o cabeçalho', () => {
    expect(matchesToCsv([]).trimEnd().split('\r\n')).toHaveLength(1);
  });
});
