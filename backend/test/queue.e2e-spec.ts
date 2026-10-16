import { INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import type { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { Clock } from '../src/common/clock';
import { AppConfig, loadConfig } from '../src/config';
import { Database } from '../src/db/database';
import { ContainerRuntime } from '../src/orchestrator/container-runtime';
import { OrchestratorService } from '../src/orchestrator/orchestrator.service';
import { SweeperService } from '../src/sweeper.service';
import { FakeClock, FakeContainerRuntime } from './support/fakes';

const INTERNAL_SECRET = 'interno-e2e-com-pelo-menos-32-caracteres';
const SECRET_HEADER = 'x-internal-secret';
const SLOT_PORT_HEADER = 'x-slot-port';
const FIRST_SLOT_PORT = 7000;

const baseConfig: AppConfig = loadConfig({
  DATABASE_URL: process.env.TEST_DATABASE_URL ?? 'postgres://rrb:rrb@localhost:5432/rrb_test',
  JWT_SECRET: 'segredo-e2e-com-pelo-menos-32-caracteres',
  INTERNAL_SECRET,
  AUTH_RATE_LIMIT: '1000',
  QUEUE_RATE_LIMIT: '1000',
  SWEEP_INTERVAL_MS: '0',
  POOL_SIZE: '2',
  POOL_MAX: '3',
  GAMESERVER_PUBLIC_HOST: 'jogo.exemplo.com',
  LOG_LEVEL: 'silent',
});

interface User {
  id: string;
  auth: string;
}

interface Paired {
  matchId: string;
  /** Token do primeiro jogador; `tokenB` é o do segundo (um por jogador, §4.2). */
  token: string;
  tokenB: string;
  ticketA: string;
  ticketB: string;
}

describe('fila 1x1 e orquestrador (e2e, Docker mock)', () => {
  let app: INestApplication<App>;
  let runtime: FakeContainerRuntime;
  let clock: FakeClock;
  let users: User[];
  const jwt = new JwtService({ secret: baseConfig.JWT_SECRET });

  async function createApp(overrides: Partial<AppConfig> = {}): Promise<void> {
    runtime = new FakeContainerRuntime();
    clock = new FakeClock();
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule.forRoot({ ...baseConfig, ...overrides })],
    })
      .overrideProvider(ContainerRuntime)
      .useValue(runtime)
      .overrideProvider(Clock)
      .useValue(clock)
      .compile();
    app = moduleRef.createNestApplication<INestApplication<App>>({ logger: false });
    // Escuta uma vez (porta efêmera): com o servidor parado, requisições paralelas do supertest fazem
    // listen/close concorrentes no mesmo http.Server e, no Windows, derrubam o processo do node.
    await app.listen(0);
    const database = app.get(Database);
    await database.migrate();
    await database.pool.query('TRUNCATE queue_tickets, match_players, matches, users CASCADE');
    await app.get(OrchestratorService).warm();
  }

  const rows = async <T>(sql: string, params: unknown[] = []): Promise<T[]> =>
    (await app.get(Database).pool.query(sql, params)).rows as T[];

  /**
   * Conta direto no banco + access token assinado aqui: o cadastro/login real é do auth.e2e-spec, e
   * hashear senha com argon2 (64 MiB) a cada teste só deixaria este arquivo lento.
   */
  async function register(n: number): Promise<User> {
    const [row] = await rows<{ id: string }>(
      'INSERT INTO users (email, password_hash) VALUES ($1, $2) RETURNING id',
      [`jogador${n}@rrb.dev`, 'hash-nao-usado'],
    );
    const id = row!.id;
    const accessToken = await jwt.signAsync({ sub: id, typ: 'access' }, { expiresIn: '15m' });
    return { id, auth: `Bearer ${accessToken}` };
  }

  const server = (): App => app.getHttpServer();
  const join = (user: User) => request(server()).post('/queue').set('Authorization', user.auth);
  const poll = (user: User, ticket: string) =>
    request(server()).get(`/queue/${ticket}`).set('Authorization', user.auth);
  // `slotPort`: o SLOT_PORT do container que chama; o primeiro slot do pool é o 7000.
  const internal = (path: string, slotPort = FIRST_SLOT_PORT) =>
    request(server())
      .post(`/internal/matches/${path}`)
      .set(SECRET_HEADER, INTERNAL_SECRET)
      .set(SLOT_PORT_HEADER, String(slotPort));
  /** O slot que o orquestrador deu à partida (as seguintes ao primeiro pareamento usam outras portas). */
  const slotOf = async (matchId: string): Promise<number> =>
    (await rows<{ server_port: number }>('SELECT server_port FROM matches WHERE id = $1', [matchId]))[0]!.server_port;

  /** Dois jogadores entram na fila, são pareados e cada um lê o seu assignment. */
  async function pairUp(a: User, b: User): Promise<Paired> {
    const ticketA = ((await join(a)).body as { id: string }).id;
    const ticketB = ((await join(b)).body as { id: string }).id;
    const forA = (await poll(a, ticketA)).body as { assignment: { token: string } };
    const forB = (await poll(b, ticketB)).body as { assignment: { token: string } };
    const { match_id: matchId } = jwt.decode<{ match_id: string }>(forA.assignment.token);
    return { matchId, token: forA.assignment.token, tokenB: forB.assignment.token, ticketA, ticketB };
  }

  beforeEach(async () => {
    await createApp();
    users = await Promise.all([1, 2, 3, 4].map(register));
  });

  afterEach(async () => {
    await app.close();
  });

  describe('fila', () => {
    it('POST /queue → ticket searching; GET → searching enquanto não há par', async () => {
      const [a] = users as [User];

      const created = await join(a);
      const polled = await poll(a, (created.body as { id: string }).id);

      expect(created.status).toBe(201);
      expect(created.body).toEqual({ id: expect.any(String), status: 'searching', createdAt: expect.any(String) });
      expect(polled.status).toBe(200);
      expect(polled.body).toEqual({ status: 'searching', elapsedS: 0 });
    });

    it('dois tickets formam par: mesmo servidor, um token por jogador (sub = a conta)', async () => {
      const [a, b] = users as [User, User];
      const { ticketA, ticketB } = await pairUp(a, b);

      const forA = await poll(a, ticketA);
      const forB = await poll(b, ticketB);

      expect(forA.body).toMatchObject({
        status: 'matched',
        assignment: { host: 'jogo.exemplo.com', port: 7000, token: expect.any(String) },
      });
      expect(forB.body).toMatchObject({
        status: 'matched',
        assignment: { host: 'jogo.exemplo.com', port: 7000, token: expect.any(String) },
      });
      const tokenA = (forA.body as { assignment: { token: string } }).assignment.token;
      const tokenB = (forB.body as { assignment: { token: string } }).assignment.token;
      expect(tokenB).not.toBe(tokenA);
      expect(jwt.decode<{ sub: string }>(tokenA).sub).toBe(a.id);
      expect(jwt.decode<{ sub: string }>(tokenB).sub).toBe(b.id);
    });

    it('banco: matches(assigned) e match_players dos dois com o hash do token de cada um (nunca o token)', async () => {
      const [a, b] = users as [User, User];
      const { matchId, token, tokenB } = await pairUp(a, b);

      const [match] = await rows<{ status: string; server_port: number }>(
        'SELECT status, server_port FROM matches WHERE id = $1',
        [matchId],
      );
      const players = await rows<{ user_id: string; token_hash: string }>(
        'SELECT user_id, token_hash FROM match_players WHERE match_id = $1',
        [matchId],
      );

      expect(match).toMatchObject({ status: 'assigned', server_port: 7000 });
      expect(players.map((p) => p.user_id).sort()).toEqual([a.id, b.id].sort());
      for (const player of players) {
        expect(player.token_hash).toMatch(/^[0-9a-f]{64}$/);
        expect([token, tokenB].some((t) => player.token_hash.includes(t))).toBe(false);
      }
      expect(new Set(players.map((p) => p.token_hash)).size).toBe(2);
    });

    it('I8: segundo ticket da mesma conta → 409 ALREADY_QUEUED', async () => {
      const [a] = users as [User];
      await join(a);

      const again = await join(a);

      expect(again.status).toBe(409);
      expect(again.body).toMatchObject({ statusCode: 409, code: 'ALREADY_QUEUED' });
      expect(await rows('SELECT 1 FROM queue_tickets WHERE user_id = $1', [a.id])).toHaveLength(1);
    });

    it('I8: dois POST simultâneos da mesma conta criam um ticket só', async () => {
      const [a] = users as [User];

      const results = await Promise.all([join(a), join(a), join(a)]);

      expect(results.map((r) => r.status).sort()).toEqual([201, 409, 409]);
      expect(await rows('SELECT 1 FROM queue_tickets WHERE user_id = $1', [a.id])).toHaveLength(1);
    });

    it('conta em partida em andamento não entra na fila (ALREADY_QUEUED)', async () => {
      const [a, b] = users as [User, User];
      await pairUp(a, b);

      expect((await join(a)).status).toBe(409);
    });

    it('FIFO: A,B pareiam primeiro; C espera e pareia com D', async () => {
      const [a, b, c, d] = users as [User, User, User, User];
      const first = await pairUp(a, b);
      const ticketC = ((await join(c)).body as { id: string }).id;
      expect((await poll(c, ticketC)).body).toMatchObject({ status: 'searching' });

      const ticketD = ((await join(d)).body as { id: string }).id;

      const forC = (await poll(c, ticketC)).body as { status: string; assignment: { token: string } };
      const forD = (await poll(d, ticketD)).body as { assignment: { token: string } };
      const second = jwt.decode<{ match_id: string; player_ids: string[] }>(forC.assignment.token);
      expect(forC.status).toBe('matched');
      expect(second.player_ids).toEqual([c.id, d.id]);
      expect(second.match_id).not.toBe(first.matchId);
      expect(jwt.decode<{ match_id: string }>(forD.assignment.token).match_id).toBe(second.match_id);
    });

    it('DELETE /queue/:ticket cancela; depois dele o GET diz cancelled e o ticket não pareia', async () => {
      const [a, b] = users as [User, User];
      const ticketA = ((await join(a)).body as { id: string }).id;

      const del = await request(server()).delete(`/queue/${ticketA}`).set('Authorization', a.auth);
      await join(b);

      expect(del.status).toBe(204);
      expect((await poll(a, ticketA)).body).toMatchObject({ status: 'cancelled' });
      expect(runtime.started).toEqual([7000, 7001]); // nenhuma partida alocada
    });

    it('DELETE de ticket já pareado → 409 ALREADY_MATCHED; de outra conta ou lixo → 404', async () => {
      const [a, b, c] = users as [User, User, User];
      const { ticketA } = await pairUp(a, b);

      const matched = await request(server()).delete(`/queue/${ticketA}`).set('Authorization', a.auth);
      const foreign = await request(server()).delete(`/queue/${ticketA}`).set('Authorization', c.auth);
      const garbage = await request(server()).get('/queue/nao-e-uuid').set('Authorization', a.auth);

      expect(matched.status).toBe(409);
      expect(matched.body).toMatchObject({ code: 'ALREADY_MATCHED' });
      expect(foreign.status).toBe(404);
      expect(foreign.body).toMatchObject({ code: 'TICKET_NOT_FOUND' });
      expect(garbage.status).toBe(404);
    });

    it('sem token de usuário → 401', async () => {
      expect((await request(server()).post('/queue')).status).toBe(401);
      expect((await request(server()).get('/queue/x')).status).toBe(401);
    });

    it('ticket sem polling por mais de 10 s expira e não pareia com o próximo', async () => {
      const [a, b] = users as [User, User];
      const ticketA = ((await join(a)).body as { id: string }).id;
      clock.advance(10_001);

      const ticketB = ((await join(b)).body as { id: string }).id;

      expect((await poll(a, ticketA)).body).toMatchObject({ status: 'cancelled' });
      expect((await poll(b, ticketB)).body).toMatchObject({ status: 'searching' });
    });
  });

  describe('pool de containers', () => {
    it('sobe o pool no boot e repõe depois de alocar', async () => {
      expect(runtime.started).toEqual([7000, 7001]);
      const [a, b] = users as [User, User];

      await pairUp(a, b);
      await app.get(OrchestratorService).settle();

      expect(runtime.started).toEqual([7000, 7001, 7002]);
    });

    it('pool vazio sobe container sob demanda; no limite o par espera até abrir vaga', async () => {
      await app.close();
      await createApp({ POOL_SIZE: 0, POOL_MAX: 1 });
      users = await Promise.all([1, 2, 3, 4].map(register));
      const [a, b, c, d] = users as [User, User, User, User];
      expect(runtime.started).toEqual([]);

      const first = await pairUp(a, b);
      expect(runtime.started).toEqual([7000]); // criado sob demanda

      const ticketC = ((await join(c)).body as { id: string }).id;
      const ticketD = ((await join(d)).body as { id: string }).id;
      expect((await poll(c, ticketC)).body).toMatchObject({ status: 'searching' }); // POOL_MAX=1

      await request(server()).post(`/matches/${first.matchId}/abandon`).set('Authorization', a.auth).expect(204);
      await app.get(SweeperService).tick();

      expect((await poll(c, ticketC)).body).toMatchObject({ status: 'matched' });
      expect((await poll(d, ticketD)).body).toMatchObject({ status: 'matched' });
    });
  });

  describe('endpoints internos', () => {
    it('sem o segredo compartilhado → 401 INTERNAL_UNAUTHORIZED (e com segredo errado)', async () => {
      const id = '99999999-9999-4999-8999-999999999999';

      const none = await request(server()).post(`/internal/matches/${id}/heartbeat`);
      const wrong = await request(server()).post(`/internal/matches/${id}/heartbeat`).set(SECRET_HEADER, 'errado');

      expect(none.status).toBe(401);
      expect(none.body).toMatchObject({ code: 'INTERNAL_UNAUTHORIZED' });
      expect(wrong.status).toBe(401);
    });

    it('token de usuário não abre rota interna', async () => {
      const [a] = users as [User];

      const res = await request(server())
        .post('/internal/matches/99999999-9999-4999-8999-999999999999/heartbeat')
        .set('Authorization', a.auth);

      expect(res.status).toBe(401);
    });

    it('#181: token da partida M2 apresentado pelo container de M1 → 401 TOKEN_INVALID e M2 continua assigned', async () => {
      const [a, b, c, d] = users as [User, User, User, User];
      const m1 = await pairUp(a, b);
      const m2 = await pairUp(c, d);
      const [slot1, slot2] = await Promise.all([slotOf(m1.matchId), slotOf(m2.matchId)]);
      expect(slot1).not.toBe(slot2);

      const hijack = await internal(`${m2.matchId}/validate`, slot1).send({ token: m2.token });
      const own = await internal(`${m2.matchId}/validate`, slot2).send({ token: m2.token });

      expect(hijack.status).toBe(401);
      expect(hijack.body).toMatchObject({ code: 'TOKEN_INVALID' });
      expect(own.status).toBe(200);
    });

    it('#181: heartbeat e result de container que não é o da partida → 401 SLOT_MISMATCH; sem o cabeçalho também', async () => {
      const [a, b] = users as [User, User];
      const { matchId, token } = await pairUp(a, b);
      await internal(`${matchId}/validate`).send({ token });
      const result = { winnerUserId: null, endReason: 'abandoned', durationS: 1, players: [] };

      const beat = await internal(`${matchId}/heartbeat`, 7001);
      const report = await internal(`${matchId}/result`, 7001).send(result);
      const bare = await request(server()).post(`/internal/matches/${matchId}/heartbeat`).set(SECRET_HEADER, INTERNAL_SECRET);
      const junk = await internal(`${matchId}/heartbeat`, FIRST_SLOT_PORT).set(SLOT_PORT_HEADER, '7000abc');

      for (const res of [beat, report, bare, junk]) {
        expect(res.status).toBe(401);
        expect(res.body).toMatchObject({ code: 'SLOT_MISMATCH' });
      }
      const [match] = await rows<{ status: string }>('SELECT status FROM matches WHERE id = $1', [matchId]);
      expect(match?.status).toBe('running');
    });

    it('validate com o token de cada jogador: assigned → running, devolve a conta, seed e jogadores', async () => {
      const [a, b] = users as [User, User];
      const { matchId, token, tokenB } = await pairUp(a, b);

      const res = await internal(`${matchId}/validate`).send({ token });
      const again = await internal(`${matchId}/validate`).send({ token: tokenB }); // o segundo peer

      expect(res.status).toBe(200);
      expect(res.body).toEqual({ matchId, userId: a.id, playerIds: [a.id, b.id], seed: expect.any(Number) });
      expect(again.body).toEqual({ ...(res.body as object), userId: b.id });
      const [match] = await rows<{ status: string; started_at: Date }>(
        'SELECT status, started_at FROM matches WHERE id = $1',
        [matchId],
      );
      expect(match?.status).toBe('running');
      expect(match?.started_at).toEqual(clock.now());
    });

    it('validate com token expirado → 401 TOKEN_EXPIRED e a partida continua assigned', async () => {
      await app.close();
      await createApp({ MATCH_TOKEN_TTL_S: 1 });
      users = await Promise.all([1, 2, 3, 4].map(register));
      const [a, b] = users as [User, User];
      const { matchId, token } = await pairUp(a, b);

      await new Promise((resolve) => setTimeout(resolve, 1200));
      const res = await internal(`${matchId}/validate`).send({ token });

      expect(res.status).toBe(401);
      expect(res.body).toMatchObject({ statusCode: 401, code: 'TOKEN_EXPIRED' });
      const [match] = await rows<{ status: string }>('SELECT status FROM matches WHERE id = $1', [matchId]);
      expect(match?.status).toBe('assigned');
    });

    it('validate com token de outra partida / lixo → 401 TOKEN_INVALID', async () => {
      const [a, b, c, d] = users as [User, User, User, User];
      const first = await pairUp(a, b);
      const second = await pairUp(c, d);

      const swapped = await internal(`${first.matchId}/validate`).send({ token: second.token });
      const garbage = await internal(`${first.matchId}/validate`).send({ token: 'lixo' });
      const missing = await internal(`${first.matchId}/validate`).send({});

      expect(swapped.body).toMatchObject({ code: 'TOKEN_INVALID' });
      expect(garbage.body).toMatchObject({ code: 'TOKEN_INVALID' });
      expect(missing.status).toBe(400);
    });

    it('result grava finished, vencedor e match_players; devolve o container ao pool', async () => {
      const [a, b] = users as [User, User];
      const { matchId, token } = await pairUp(a, b);
      await internal(`${matchId}/validate`).send({ token });
      const stats = (userId: string, kills: number) => ({
        userId,
        heroId: 'arqueiro',
        kills,
        deaths: 1,
        finalLevel: 8,
        damageDealt: 1500.5,
        damageTaken: 900,
        monstersKilled: 14,
        chestsOpened: 2,
        bossKill: kills > 3,
        setActive: 'fogo',
        levelAtPhase1End: 5,
        avgPingMs: 48,
      });

      const res = await internal(`${matchId}/result`).send({
        winnerUserId: a.id,
        endReason: 'kill_goal',
        durationS: 512,
        players: [stats(a.id, 5), stats(b.id, 2)],
      });
      await app.get(OrchestratorService).settle();

      expect(res.status).toBe(204);
      const [match] = await rows<{ status: string; winner_user_id: string; end_reason: string; duration_s: number; ended_at: Date }>(
        'SELECT status, winner_user_id, end_reason, duration_s, ended_at FROM matches WHERE id = $1',
        [matchId],
      );
      expect(match).toMatchObject({ status: 'finished', winner_user_id: a.id, end_reason: 'kill_goal', duration_s: 512 });
      const players = await rows<Record<string, unknown>>(
        'SELECT * FROM match_players WHERE match_id = $1 AND user_id = $2',
        [matchId, a.id],
      );
      expect(players[0]).toMatchObject({
        hero_id: 'arqueiro',
        kills: 5,
        deaths: 1,
        final_level: 8,
        damage_dealt: 1500.5,
        monsters_killed: 14,
        chests_opened: 2,
        boss_kill: true,
        set_active: 'fogo',
        level_at_phase1_end: 5,
        avg_ping_ms: 48,
      });
      expect(runtime.removed).toEqual(['container-1']);
      expect((await join(a)).status).toBe(201); // conta livre de novo
    });

    it('result inválido: jogador de fora → 400 INVALID_RESULT; repetido → 409 MATCH_NOT_RUNNING', async () => {
      const [a, b, c] = users as [User, User, User];
      const { matchId, token } = await pairUp(a, b);
      await internal(`${matchId}/validate`).send({ token });
      const valid = { winnerUserId: null, endReason: 'abandoned', durationS: 60, players: [] };

      const outsider = await internal(`${matchId}/result`).send({ ...valid, winnerUserId: c.id });
      const bad = await internal(`${matchId}/result`).send({ ...valid, endReason: 'Com Espaço' });
      const ok = await internal(`${matchId}/result`).send(valid);
      const repeated = await internal(`${matchId}/result`).send(valid);

      expect(outsider.body).toMatchObject({ code: 'INVALID_RESULT' });
      expect(bad.status).toBe(400);
      expect(ok.status).toBe(204);
      expect(repeated.status).toBe(409);
      expect(repeated.body).toMatchObject({ code: 'MATCH_NOT_RUNNING' });
    });

    it('heartbeat mantém a partida viva; 3 perdidos (30 s) → aborted e container reciclado', async () => {
      const [a, b] = users as [User, User];
      const { matchId, token } = await pairUp(a, b);
      await internal(`${matchId}/validate`).send({ token });

      clock.advance(20_000);
      expect((await internal(`${matchId}/heartbeat`)).status).toBe(204);
      clock.advance(30_000);
      await app.get(SweeperService).tick();
      const alive = await rows<{ status: string }>('SELECT status FROM matches WHERE id = $1', [matchId]);
      expect(alive[0]?.status).toBe('running'); // 30 s desde o último heartbeat: ainda não

      clock.advance(1_000);
      await app.get(SweeperService).tick();
      await app.get(OrchestratorService).settle();

      const [match] = await rows<{ status: string; end_reason: string }>(
        'SELECT status, end_reason FROM matches WHERE id = $1',
        [matchId],
      );
      expect(match).toEqual({ status: 'aborted', end_reason: 'heartbeat_lost' });
      expect(runtime.removed).toEqual(['container-1']);
      expect((await internal(`${matchId}/heartbeat`)).status).toBe(409);
      expect((await poll(a, (await rows<{ id: string }>('SELECT id FROM queue_tickets WHERE user_id = $1', [a.id]))[0]!.id)).body).toMatchObject({
        status: 'cancelled',
      });
    });

    it('token não validado dentro de 2 min → aborted "token_expired" na varredura', async () => {
      const [a, b] = users as [User, User];
      const { matchId } = await pairUp(a, b);

      clock.advance(121_000);
      await app.get(SweeperService).tick();

      const [match] = await rows<{ status: string; end_reason: string }>(
        'SELECT status, end_reason FROM matches WHERE id = $1',
        [matchId],
      );
      expect(match).toEqual({ status: 'aborted', end_reason: 'token_expired' });
      await app.get(OrchestratorService).settle();
      expect(runtime.removed).toEqual(['container-1']); // container liberado também neste caminho
      expect((await poll(a, (await rows<{ id: string }>('SELECT id FROM queue_tickets WHERE user_id = $1', [a.id]))[0]!.id)).body).toMatchObject({
        status: 'cancelled',
      });
    });
  });

  describe('POST /matches/:id/abandon (Launcher)', () => {
    it('participante aborta partida ainda não iniciada e libera o container', async () => {
      const [a, b] = users as [User, User];
      const { matchId } = await pairUp(a, b);

      const res = await request(server()).post(`/matches/${matchId}/abandon`).set('Authorization', b.auth);
      await app.get(OrchestratorService).settle();

      expect(res.status).toBe(204);
      const [match] = await rows<{ status: string; end_reason: string }>(
        'SELECT status, end_reason FROM matches WHERE id = $1',
        [matchId],
      );
      expect(match).toEqual({ status: 'aborted', end_reason: 'abandoned' });
      expect(runtime.removed).toEqual(['container-1']);
    });

    it('outra conta → 404; partida já rodando → 409 MATCH_NOT_ASSIGNED; sem login → 401', async () => {
      const [a, b, c] = users as [User, User, User];
      const { matchId, token } = await pairUp(a, b);

      const outsider = await request(server()).post(`/matches/${matchId}/abandon`).set('Authorization', c.auth);
      const anonymous = await request(server()).post(`/matches/${matchId}/abandon`);
      await internal(`${matchId}/validate`).send({ token });
      const running = await request(server()).post(`/matches/${matchId}/abandon`).set('Authorization', a.auth);

      expect(outsider.status).toBe(404);
      expect(anonymous.status).toBe(401);
      expect(running.status).toBe(409);
      expect(running.body).toMatchObject({ code: 'MATCH_NOT_ASSIGNED' });
    });
  });

  describe('GET /matches?mine=1 (histórico)', () => {
    const stats = (userId: string, heroId: string, kills: number, level: number) => ({
      userId,
      heroId,
      kills,
      deaths: 1,
      finalLevel: level,
      damageDealt: 100,
      damageTaken: 90,
      monstersKilled: 3,
      chestsOpened: 1,
      bossKill: false,
    });
    const history = (user: User, query = '?mine=1') =>
      request(server()).get(`/matches${query}`).set('Authorization', user.auth);

    /** Pareia, valida e fecha a partida: `winner` ganha por 5 × 2. */
    async function play(a: User, b: User, winner: User): Promise<string> {
      const { matchId, token } = await pairUp(a, b);
      const slot = await slotOf(matchId);
      await internal(`${matchId}/validate`, slot).send({ token });
      await internal(`${matchId}/result`, slot).send({
        winnerUserId: winner.id,
        endReason: 'kill_goal',
        durationS: 512,
        players: [
          stats(a.id, 'arqueiro', winner === a ? 5 : 2, 9),
          stats(b.id, 'cavaleiro', winner === b ? 5 : 2, 8),
        ],
      });
      await app.get(OrchestratorService).settle();
      clock.advance(1000);
      return matchId;
    }

    it('lista só as partidas da conta autenticada, com o herói do oponente e os totais V–D', async () => {
      const [a, b, c, d] = users as [User, User, User, User];
      await rows('UPDATE users SET nickname = $1 WHERE id = $2', ['RodReis', b.id]);
      const first = await play(a, b, a);
      const second = await play(a, b, b);
      await play(c, d, c); // partida de outras contas

      const res = await history(a);

      expect(res.status).toBe(200);
      const body = res.body as { totals: unknown; matches: { matchId: string; result: string }[] };
      expect(body.totals).toEqual({ wins: 1, losses: 1 });
      expect(body.matches.map((m) => [m.matchId, m.result])).toEqual([
        [second, 'loss'],
        [first, 'win'],
      ]);
      expect(body.matches[1]).toMatchObject({
        endReason: 'kill_goal',
        durationS: 512,
        me: { heroId: 'arqueiro', kills: 5, finalLevel: 9 },
        opponent: { heroId: 'cavaleiro', nickname: 'RodReis', kills: 2, finalLevel: 8 },
      });
    });

    it('oponente sem nickname (conta anterior ao F35) vem com nickname nulo', async () => {
      const [a, b] = users as [User, User];
      await play(a, b, a);

      const body = (await history(a)).body as { matches: { opponent: { nickname: unknown } }[] };

      expect(body.matches[0]?.opponent.nickname).toBeNull();
    });

    it('sem vazamento: nada de id, e-mail ou token de outra conta na resposta', async () => {
      const [a, b, c] = users as [User, User, User];
      await play(a, b, a);

      const raw = (await history(a)).text;
      const outsider = await history(c);

      expect(raw).not.toContain(b.id);
      expect(raw).not.toContain('jogador2@rrb.dev');
      expect(raw).not.toMatch(/userId|user_id|email|token/i);
      expect(outsider.body).toEqual({ totals: { wins: 0, losses: 0 }, matches: [] });
    });

    it('partida abortada aparece como interrupted; a em andamento não aparece', async () => {
      const [a, b, c, d] = users as [User, User, User, User];
      const { matchId } = await pairUp(a, b);
      await request(server()).post(`/matches/${matchId}/abandon`).set('Authorization', a.auth);
      await app.get(OrchestratorService).settle();
      await pairUp(c, d); // assigned: ainda não terminou

      const aborted = (await history(a)).body as { matches: { result: string; me: { heroId: unknown } }[] };
      const open = (await history(c)).body as { matches: unknown[] };

      expect(aborted.matches).toMatchObject([{ result: 'interrupted', endReason: 'abandoned', me: { heroId: null } }]);
      expect(open.matches).toEqual([]);
    });

    it('sem login → 401; sem mine=1 → 400', async () => {
      const [a] = users as [User];

      const anonymous = await request(server()).get('/matches?mine=1');
      const missing = await history(a, '');

      expect(anonymous.status).toBe(401);
      expect(missing.status).toBe(400);
    });

    it('mine repetido, em lista ou com userId extra: só vale mine=1 e o dono é o do JWT', async () => {
      const [a, b] = users as [User, User];
      await play(a, b, a);

      const twice = await history(a, '?mine=1&mine=1');
      const list = await history(a, '?mine[]=1');
      const spoofed = await history(b, `?mine=1&userId=${a.id}`);

      expect([twice.status, list.status]).toEqual([400, 400]);
      expect(spoofed.status).toBe(200);
      expect((spoofed.body as { matches: { me: { heroId: string } }[] }).matches[0]?.me.heroId).toBe('cavaleiro');
    });

    it('o polling do histórico não gasta o limite de entrar na fila', async () => {
      await app.close();
      await createApp({ QUEUE_RATE_LIMIT: 2 });
      users = await Promise.all([1, 2, 3, 4].map(register));
      const [a] = users as [User];

      const reads = await Promise.all(Array.from({ length: 6 }, () => history(a)));

      expect(reads.every((res) => res.status === 200)).toBe(true);
      expect((await join(a)).status).toBe(201);
    });
  });

  describe('rate limit', () => {
    it('POST /queue estoura o limite → 429; o polling do GET não é limitado', async () => {
      await app.close();
      await createApp({ QUEUE_RATE_LIMIT: 2 });
      users = await Promise.all([1, 2, 3, 4].map(register));
      const [a, b, c] = users as [User, User, User];

      const first = await join(a);
      await join(b); // pareia a e b
      const third = await join(c);
      const fourth = await join(c);
      const ticketA = (first.body as { id: string }).id;
      const polls = await Promise.all(Array.from({ length: 15 }, () => poll(a, ticketA)));

      expect([first.status, third.status, fourth.status]).toEqual([201, 429, 429]);
      expect(fourth.body).toMatchObject({ statusCode: 429, code: 'RATE_LIMITED' });
      expect(polls.every((res) => res.status === 200)).toBe(true);
    });
  });
});
