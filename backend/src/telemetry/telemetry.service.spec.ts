import { InMemoryTelemetryRepository } from '../../test/support/fakes';
import { ADMIN_PAGE_SIZE } from './telemetry.dto';
import { AdminMatchRow, AdminPlayerRow } from './telemetry.repository';
import { TelemetryService } from './telemetry.service';

const player = (partial: Partial<AdminPlayerRow> = {}): AdminPlayerRow => ({
  nickname: 'Rod',
  isWinner: false,
  heroId: 'arqueiro',
  kills: 0,
  deaths: 0,
  finalLevel: 1,
  damageDealt: 0,
  damageTaken: 0,
  monstersKilled: 0,
  chestsOpened: 0,
  bossKill: false,
  setActive: null,
  levelAtPhase1End: null,
  avgPingMs: null,
  teleportCount: null,
  ...partial,
});

let serial = 0;
function row(partial: Partial<AdminMatchRow> = {}): AdminMatchRow {
  serial++;
  return {
    matchId: `00000000-0000-4000-8000-${String(serial).padStart(12, '0')}`,
    status: 'finished',
    seed: serial,
    serverHost: '10.0.0.1',
    serverPort: 7000,
    createdAt: new Date(Date.UTC(2026, 9, 1, 0, serial)),
    startedAt: null,
    lastHeartbeatAt: null,
    endedAt: new Date(Date.UTC(2026, 9, 1, 1, serial)),
    endReason: 'kill_goal',
    durationS: 300,
    players: [player({ nickname: 'A', isWinner: true }), player({ nickname: 'B', heroId: 'bruxo' })],
    ...partial,
  };
}

describe('TelemetryService (SPEC-029)', () => {
  let repo: InMemoryTelemetryRepository;
  let service: TelemetryService;

  beforeEach(() => {
    serial = 0;
    repo = new InMemoryTelemetryRepository();
    service = new TelemetryService(repo);
  });

  describe('kpis', () => {
    it('abandonada e abortada ficam fora de todos os KPIs; só finished entra', async () => {
      repo.rows.push(
        row({ durationS: 300, players: [player({ avgPingMs: 40 }), player({ avgPingMs: 60 })] }),
        row({ status: 'aborted', endReason: 'abandoned', durationS: 9000, players: [player({ avgPingMs: 999 })] }),
        row({ status: 'running', durationS: null, players: [player({ avgPingMs: 888 })] }),
      );

      const report = await service.kpis();

      expect(report.matches).toBe(1);
      expect(report.kpis.find((k) => k.key === 'ping_avg')).toMatchObject({ value: 50, n: 2 });
      expect(report.kpis.find((k) => k.key === 'duration_avg')).toMatchObject({ value: 300, n: 1 });
    });
  });

  describe('matches', () => {
    it('pagina de 50 em 50, da mais recente para a mais antiga, e informa o total', async () => {
      for (let i = 0; i < 120; i++) repo.rows.push(row());

      const first = await service.matches({}, 1);
      const third = await service.matches({}, 3);

      expect(first).toMatchObject({ page: 1, pageSize: ADMIN_PAGE_SIZE, total: 120 });
      expect(first.matches).toHaveLength(50);
      expect(first.matches[0]?.seed).toBe(120);
      expect(third.matches).toHaveLength(20);
      expect(third.matches.at(-1)?.seed).toBe(1);
    });

    it('filtra por endReason e por herói (qualquer dos dois jogadores)', async () => {
      repo.rows.push(
        row({ endReason: 'kill_goal' }),
        row({ endReason: 'abandoned', players: [player({ heroId: 'ladina' })] }),
        row({ endReason: 'kill_goal', players: [player({ heroId: 'ladina' }), player({ heroId: 'bruxo' })] }),
      );

      expect((await service.matches({ endReason: 'abandoned' }, 1)).total).toBe(1);
      expect((await service.matches({ heroId: 'ladina' }, 1)).total).toBe(2);
      expect((await service.matches({ heroId: 'ladina', endReason: 'kill_goal' }, 1)).total).toBe(1);
      expect((await service.matches({ heroId: 'ninguem' }, 1)).matches).toEqual([]);
    });

    it('lista também partida abandonada/abortada, com os dois jogadores e todos os campos', async () => {
      repo.rows.push(row({ status: 'aborted', endReason: 'abandoned', startedAt: new Date('2026-10-01T00:00:00Z') }));

      const [match] = (await service.matches({}, 1)).matches;

      expect(match).toMatchObject({ status: 'aborted', endReason: 'abandoned', startedAt: '2026-10-01T00:00:00.000Z' });
      expect(match?.players).toHaveLength(2);
      expect(Object.keys(match?.players[0] ?? {}).sort()).toEqual(
        [
          'avgPingMs', 'bossKill', 'chestsOpened', 'damageDealt', 'damageTaken', 'deaths', 'finalLevel', 'heroId',
          'isWinner', 'kills', 'levelAtPhase1End', 'monstersKilled', 'nickname', 'setActive', 'teleportCount',
        ].sort(),
      );
    });

    it('a resposta nunca traz e-mail, hash, token nem id de conta, mesmo se a linha vier suja', async () => {
      const dirty = row();
      Object.assign(dirty, { email: 'x@y.z', tokenHash: 'h' });
      Object.assign(dirty.players[0] as object, { userId: 'u1', email: 'a@b.c', passwordHash: 'p', tokenHash: 't' });
      repo.rows.push(dirty);

      const json = JSON.stringify(await service.matches({}, 1));

      expect(json).not.toMatch(/email|passwordHash|tokenHash|userId|winnerUserId|u1|@/);
    });
  });

  describe('matchesCsv', () => {
    it('traz todas as páginas (uma linha por jogador) e respeita o filtro', async () => {
      for (let i = 0; i < 60; i++) repo.rows.push(row());
      repo.rows.push(row({ endReason: 'abandoned' }));

      const all = (await service.matchesCsv({})).trimEnd().split('\r\n');
      const some = (await service.matchesCsv({ endReason: 'abandoned' })).trimEnd().split('\r\n');

      expect(all).toHaveLength(1 + 61 * 2);
      expect(some).toHaveLength(1 + 2);
    });
  });
});
