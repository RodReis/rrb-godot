import { INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import type { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { AppConfig, loadConfig } from '../src/config';
import { Database } from '../src/db/database';
import { MatchesRepository } from '../src/matches/matches.repository';
import { AdminSeedService } from '../src/telemetry/admin-seed.service';

const config: AppConfig = loadConfig({
  DATABASE_URL: process.env.TEST_DATABASE_URL ?? 'postgres://rrb:rrb@localhost:5432/rrb_test',
  JWT_SECRET: 'segredo-e2e-com-pelo-menos-32-caracteres',
  INTERNAL_SECRET: 'interno-e2e-com-pelo-menos-32-caracteres',
  ADMIN_EMAILS: ' Dono@Rrb.dev ',
  SWEEP_INTERVAL_MS: '0',
  POOL_SIZE: '0',
  LOG_LEVEL: 'silent',
});

const TOKEN_HASH_A = 'hash-secreto-do-token-A';
const TOKEN_HASH_B = 'hash-secreto-do-token-B';
const NOW = new Date('2026-10-23T12:00:00.000Z');

interface Account {
  id: string;
  email: string;
  auth: string;
}

describe('painel de playtest /admin (e2e, Postgres)', () => {
  let app: INestApplication<App>;
  let db: Database;
  const jwt = new JwtService({ secret: config.JWT_SECRET });
  let owner: Account;
  let player: Account;
  let rival: Account;
  const q = async <T>(sql: string, params: unknown[] = []): Promise<T[]> => (await db.pool.query(sql, params)).rows as T[];

  async function account(email: string, nickname: string): Promise<Account> {
    const [row] = await q<{ id: string }>(
      'INSERT INTO users (email, password_hash, nickname) VALUES ($1, $2, $3) RETURNING id',
      [email, 'argon2-hash-secreto', nickname],
    );
    const id = row?.id ?? '';
    return { id, email, auth: `Bearer ${await jwt.signAsync({ sub: id, typ: 'access' })}` };
  }

  /** Cria a partida como o orquestrador (`assigned`) e a leva a `running`; o resto é com o teste. */
  async function runningMatch(matchId: string, a: Account, b: Account, createdAt: Date): Promise<void> {
    const repo = app.get(MatchesRepository);
    await repo.createAssigned({
      id: matchId,
      players: [
        { userId: a.id, tokenHash: TOKEN_HASH_A },
        { userId: b.id, tokenHash: TOKEN_HASH_B },
      ],
      serverHost: '203.0.113.9',
      serverPort: 7001,
      seed: 99,
      now: createdAt,
    });
    await repo.markRunning(matchId, createdAt);
  }

  const M_FINISHED = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
  const M_TIE = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2';
  const M_ABORTED = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa3';

  const stats = (userId: string, extra: Record<string, unknown>) => ({
    userId,
    heroId: 'arqueiro',
    kills: 3,
    deaths: 1,
    finalLevel: 7,
    damageDealt: 1234.5,
    damageTaken: 800,
    monstersKilled: 12,
    chestsOpened: 2,
    bossKill: false,
    ...extra,
  });

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule.forRoot(config)] }).compile();
    app = moduleRef.createNestApplication<INestApplication<App>>({ logger: false });
    await app.listen(0);
    db = app.get(Database);
    await db.migrate();
    await q('TRUNCATE queue_tickets, match_players, matches, users CASCADE');
    owner = await account('dono@rrb.dev', 'Dono');
    player = await account('jogador@rrb.dev', 'Jogador');
    rival = await account('rival@rrb.dev', 'Rival');

    // F1 decide: nível 5 (Jogador, vence) × 3 (Rival); ping 50 e 100; teleportes 2 e nulo.
    await runningMatch(M_FINISHED, player, rival, new Date(NOW.getTime() - 3000));
    const repo = app.get(MatchesRepository);
    await repo.finish(
      M_FINISHED,
      {
        winnerUserId: player.id,
        endReason: 'kill_goal',
        durationS: 540,
        players: [
          stats(player.id, { levelAtPhase1End: 5, avgPingMs: 50, teleportCount: 2, setActive: 'cacador' }),
          stats(rival.id, { heroId: 'bruxo', levelAtPhase1End: 3, avgPingMs: 100 }),
        ],
      },
      NOW,
    );
    // Empate de nível, duração acima de 10 min, ping alto.
    await runningMatch(M_TIE, player, rival, new Date(NOW.getTime() - 2000));
    await repo.finish(
      M_TIE,
      {
        winnerUserId: rival.id,
        endReason: 'time_up',
        durationS: 700,
        players: [
          stats(player.id, { levelAtPhase1End: 4, avgPingMs: 120, teleportCount: 0 }),
          stats(rival.id, { heroId: 'bruxo', levelAtPhase1End: 4, avgPingMs: 90 }),
        ],
      },
      NOW,
    );
    // Abortada: aparece na lista, fica fora dos KPIs.
    await runningMatch(M_ABORTED, player, rival, new Date(NOW.getTime() - 1000));
    await repo.abort(M_ABORTED, 'abandoned', NOW);

    await app.get(AdminSeedService).seed();
  });

  afterAll(async () => {
    await app.close();
  });

  const get = (path: string, auth?: string) => {
    const req = request(app.getHttpServer()).get(path);
    return auth ? req.set('Authorization', auth) : req;
  };

  describe('migração 0005', () => {
    it('conta nova nasce player; teleport_count nasce nulo; role fora de player/admin é recusado', async () => {
      const [fresh] = await q<{ role: string }>('SELECT role FROM users WHERE email = $1', ['rival@rrb.dev']);
      const [mp] = await q<{ teleport_count: number | null }>(
        'SELECT teleport_count FROM match_players WHERE match_id = $1 AND user_id = $2',
        [M_ABORTED, rival.id],
      );

      expect(fresh?.role).toBe('player');
      expect(mp?.teleport_count).toBeNull();
      await expect(q("UPDATE users SET role = 'root' WHERE email = $1", ['rival@rrb.dev'])).rejects.toMatchObject({
        code: '23514',
      });
    });

    it('teleportCount enviado no resultado é persistido', async () => {
      const [mp] = await q<{ teleport_count: number | null }>(
        'SELECT teleport_count FROM match_players WHERE match_id = $1 AND user_id = $2',
        [M_FINISHED, player.id],
      );
      expect(mp?.teleport_count).toBe(2);
    });
  });

  describe('seed ADMIN_EMAILS', () => {
    it('promoveu só o e-mail listado (sem diferenciar caixa) e ninguém mais', async () => {
      const roles = await q<{ email: string; role: string }>('SELECT email, role FROM users ORDER BY email');
      expect(roles).toEqual([
        { email: 'dono@rrb.dev', role: 'admin' },
        { email: 'jogador@rrb.dev', role: 'player' },
        { email: 'rival@rrb.dev', role: 'player' },
      ]);
    });
  });

  describe('acesso', () => {
    it.each(['/admin/kpis', '/admin/matches', '/admin/matches.csv'])('%s sem JWT → 401', async (path) => {
      const res = await get(path);
      expect(res.status).toBe(401);
    });

    it.each(['/admin/kpis', '/admin/matches', '/admin/matches.csv'])('%s com conta player → 403', async (path) => {
      const res = await get(path, player.auth);
      expect(res.status).toBe(403);
      expect(res.body).toMatchObject({ statusCode: 403, code: 'ADMIN_REQUIRED' });
    });
  });

  describe('GET /admin/kpis', () => {
    it('calcula sobre as partidas finished (a abortada fica de fora)', async () => {
      const res = await get('/admin/kpis', owner.auth);
      expect(res.status).toBe(200);
      const byKey = Object.fromEntries((res.body.kpis as { key: string }[]).map((k) => [k.key, k]));

      expect(res.body.matches).toBe(2);
      expect(byKey.ping_avg).toMatchObject({ value: 90, n: 4, withinLimit: false });
      expect(byKey.ping_over_limit).toMatchObject({ value: 75, n: 4 });
      expect(byKey.duration_avg).toMatchObject({ value: 620, n: 2 });
      expect(byKey.duration_over_limit).toMatchObject({ value: 50, n: 2, withinLimit: false });
      expect(byKey.f1_leader_wins).toMatchObject({ value: 100, n: 1, withinLimit: false });
      expect(byKey.f1_ties).toMatchObject({ value: 1, n: 2 });
      expect(byKey.teleports_total).toMatchObject({ value: 2, n: 2, source: 'client' });
    });
  });

  describe('GET /admin/matches', () => {
    it('lista todas as partidas da mais recente para a mais antiga, com os dois jogadores', async () => {
      const res = await get('/admin/matches', owner.auth);
      expect(res.status).toBe(200);
      expect(res.body).toMatchObject({ page: 1, pageSize: 50, total: 3 });
      expect((res.body.matches as { matchId: string }[]).map((m) => m.matchId)).toEqual([M_ABORTED, M_TIE, M_FINISHED]);

      const finished = res.body.matches[2];
      expect(finished).toMatchObject({ status: 'finished', endReason: 'kill_goal', durationS: 540, seed: 99 });
      expect(finished.players).toHaveLength(2);
      const winner = finished.players.find((p: { isWinner: boolean }) => p.isWinner);
      expect(winner).toMatchObject({
        nickname: 'Jogador',
        heroId: 'arqueiro',
        kills: 3,
        damageDealt: 1234.5,
        setActive: 'cacador',
        levelAtPhase1End: 5,
        avgPingMs: 50,
        teleportCount: 2,
      });
    });

    it('filtra por endReason e por herói', async () => {
      const abandoned = await get('/admin/matches?endReason=abandoned', owner.auth);
      const bruxo = await get('/admin/matches?heroId=bruxo', owner.auth);
      const none = await get('/admin/matches?heroId=bruxo&endReason=abandoned', owner.auth);

      expect(abandoned.body.total).toBe(1);
      expect(bruxo.body.total).toBe(2);
      expect(none.body).toMatchObject({ total: 0, matches: [] });
    });

    it('página inválida → 400', async () => {
      const res = await get('/admin/matches?page=0', owner.auth);
      expect(res.status).toBe(400);
    });

    it('nenhuma resposta traz e-mail, hash, token nem id de conta', async () => {
      const bodies = [
        JSON.stringify((await get('/admin/matches', owner.auth)).body),
        JSON.stringify((await get('/admin/kpis', owner.auth)).body),
        (await get('/admin/matches.csv', owner.auth)).text,
      ];
      const secrets = [owner, player, rival].flatMap((a) => [a.id, a.email, a.auth.slice('Bearer '.length)]);
      secrets.push('argon2-hash-secreto', TOKEN_HASH_A, TOKEN_HASH_B);

      for (const body of bodies) {
        for (const secret of secrets) expect(body).not.toContain(secret);
        expect(body).not.toMatch(/@rrb\.dev|passwordHash|tokenHash|userId|winnerUserId/);
      }
    });
  });

  describe('GET /admin/matches.csv', () => {
    it('é text/csv, tem o mesmo conteúdo da lista (uma linha por jogador) e honra os filtros', async () => {
      const res = await get('/admin/matches.csv', owner.auth);
      const lines = res.text.trimEnd().split('\r\n');

      expect(res.status).toBe(200);
      expect(res.headers['content-type']).toContain('text/csv');
      expect(res.headers['content-disposition']).toContain('attachment');
      expect(lines).toHaveLength(1 + 3 * 2);
      expect(lines[0]).toContain('teleportCount');
      expect(res.text).toContain('Jogador');

      const filtered = await get('/admin/matches.csv?endReason=kill_goal', owner.auth);
      expect(filtered.text.trimEnd().split('\r\n')).toHaveLength(1 + 2);
    });
  });

  describe('o papel vem do banco a cada chamada', () => {
    it('rebaixar o admin tira o acesso com o mesmo token', async () => {
      await q("UPDATE users SET role = 'player' WHERE id = $1", [owner.id]);
      expect((await get('/admin/kpis', owner.auth)).status).toBe(403);
      await q("UPDATE users SET role = 'admin' WHERE id = $1", [owner.id]);
      expect((await get('/admin/kpis', owner.auth)).status).toBe(200);
    });
  });
});
