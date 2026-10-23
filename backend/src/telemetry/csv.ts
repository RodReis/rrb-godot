import type { AdminMatch, AdminPlayer } from './telemetry.dto';

type Cell = string | number | boolean | null;

const MATCH_COLUMNS: [string, (m: AdminMatch) => Cell][] = [
  ['matchId', (m) => m.matchId],
  ['status', (m) => m.status],
  ['createdAt', (m) => m.createdAt],
  ['startedAt', (m) => m.startedAt],
  ['lastHeartbeatAt', (m) => m.lastHeartbeatAt],
  ['endedAt', (m) => m.endedAt],
  ['endReason', (m) => m.endReason],
  ['durationS', (m) => m.durationS],
  ['seed', (m) => m.seed],
  ['serverHost', (m) => m.serverHost],
  ['serverPort', (m) => m.serverPort],
];

const PLAYER_COLUMNS: [string, (p: AdminPlayer) => Cell][] = [
  ['nickname', (p) => p.nickname],
  ['isWinner', (p) => p.isWinner],
  ['heroId', (p) => p.heroId],
  ['kills', (p) => p.kills],
  ['deaths', (p) => p.deaths],
  ['finalLevel', (p) => p.finalLevel],
  ['damageDealt', (p) => p.damageDealt],
  ['damageTaken', (p) => p.damageTaken],
  ['monstersKilled', (p) => p.monstersKilled],
  ['chestsOpened', (p) => p.chestsOpened],
  ['bossKill', (p) => p.bossKill],
  ['setActive', (p) => p.setActive],
  ['levelAtPhase1End', (p) => p.levelAtPhase1End],
  ['avgPingMs', (p) => p.avgPingMs],
  ['teleportCount', (p) => p.teleportCount],
];

/** Texto que a planilha trataria como fórmula ganha um apóstrofo na frente (CSV injection). */
const FORMULA_START = /^[=+\-@\t\r]/;

export function csvCell(cell: Cell): string {
  if (cell === null) return '';
  const text = typeof cell === 'string' && FORMULA_START.test(cell) ? `'${cell}` : String(cell);
  return /[",\r\n]/.test(text) ? `"${text.replaceAll('"', '""')}"` : text;
}

/** Uma linha por jogador por partida (partida sem jogador sai com as colunas do jogador vazias). */
export function matchesToCsv(matches: AdminMatch[]): string {
  const header = [...MATCH_COLUMNS, ...PLAYER_COLUMNS].map(([name]) => name);
  const lines = [header.join(',')];
  for (const match of matches) {
    const matchCells = MATCH_COLUMNS.map(([, read]) => read(match));
    const players: (AdminPlayer | null)[] = match.players.length ? match.players : [null];
    for (const player of players) {
      const playerCells = PLAYER_COLUMNS.map(([, read]) => (player ? read(player) : null));
      lines.push([...matchCells, ...playerCells].map(csvCell).join(','));
    }
  }
  return `${lines.join('\r\n')}\r\n`;
}
