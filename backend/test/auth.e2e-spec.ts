import { INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import type { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { AppConfig, loadConfig } from '../src/config';
import { Database } from '../src/db/database';

// Postgres em container: `docker compose -f infra/docker-compose.yml --profile backend up -d postgres`
// (local) ou `services:` do job test-backend (CI).
const config: AppConfig = loadConfig({
  DATABASE_URL: process.env.TEST_DATABASE_URL ?? 'postgres://rrb:rrb@localhost:5432/rrb_test',
  JWT_SECRET: 'segredo-e2e-com-pelo-menos-32-caracteres',
  INTERNAL_SECRET: 'interno-e2e-com-pelo-menos-32-caracteres',
  AUTH_RATE_LIMIT: '1000',
  LOG_LEVEL: 'silent',
});

async function createApp(overrides: Partial<AppConfig> = {}): Promise<INestApplication<App>> {
  const moduleRef = await Test.createTestingModule({
    imports: [AppModule.forRoot({ ...config, ...overrides })],
  }).compile();
  const app = moduleRef.createNestApplication<INestApplication<App>>({ logger: false });
  await app.init();
  return app;
}

describe('auth e users (e2e)', () => {
  let app: INestApplication<App>;
  const credentials = { email: 'jogador@rrb.dev', password: 'senha1234' };

  beforeAll(async () => {
    app = await createApp();
    const database = app.get(Database);
    await database.migrate();
    await database.pool.query('TRUNCATE users CASCADE');
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /health sem token → 200 { status: ok } (status e ping do rodapé do Launcher)', async () => {
    const res = await request(app.getHttpServer()).get('/health');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: 'ok' });
  });

  it('POST /auth/register cria conta e devolve tokens (201)', async () => {
    const res = await request(app.getHttpServer()).post('/auth/register').send(credentials);
    expect(res.status).toBe(201);
    expect(res.body).toEqual({ accessToken: expect.any(String), refreshToken: expect.any(String) });
  });

  it('e-mail duplicado (mesmo com maiúsculas) → 409 EMAIL_TAKEN', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth/register')
      .send({ ...credentials, email: ' JOGADOR@rrb.dev' });
    expect(res.status).toBe(409);
    expect(res.body).toMatchObject({ statusCode: 409, code: 'EMAIL_TAKEN' });
  });

  it.each([
    ['curta', 'abc123'],
    ['sem número', 'somenteletras'],
    ['sem letra', '123456789'],
  ])('senha %s → 400 WEAK_PASSWORD', async (_caso, password) => {
    const res = await request(app.getHttpServer())
      .post('/auth/register')
      .send({ email: 'outro@rrb.dev', password });
    expect(res.status).toBe(400);
    expect(res.body).toMatchObject({ statusCode: 400, code: 'WEAK_PASSWORD' });
  });

  it('e-mail inválido → 400 INVALID_EMAIL; corpo sem campo → 400 VALIDATION_FAILED', async () => {
    const server = app.getHttpServer();
    const invalid = await request(server)
      .post('/auth/register')
      .send({ email: 'x', password: 'senha1234' });
    expect(invalid.body).toMatchObject({ statusCode: 400, code: 'INVALID_EMAIL' });
    const missing = await request(server).post('/auth/register').send({ email: 'a@b.com' });
    expect(missing.body).toMatchObject({ statusCode: 400, code: 'VALIDATION_FAILED' });
  });

  it('POST /auth/login ok → 200 com tokens; senha errada → 401 INVALID_CREDENTIALS', async () => {
    const server = app.getHttpServer();
    const ok = await request(server).post('/auth/login').send(credentials);
    expect(ok.status).toBe(200);
    expect(ok.body.accessToken).toEqual(expect.any(String));

    const wrong = await request(server)
      .post('/auth/login')
      .send({ ...credentials, password: 'errada123' });
    expect(wrong.status).toBe(401);
    expect(wrong.body).toMatchObject({ statusCode: 401, code: 'INVALID_CREDENTIALS' });

    const unknown = await request(server)
      .post('/auth/login')
      .send({ email: 'ninguem@rrb.dev', password: 'senha1234' });
    expect(unknown.status).toBe(401);
    expect(unknown.body).toMatchObject({ statusCode: 401, code: 'INVALID_CREDENTIALS' });
  });

  it('corpo acima de 100 KB → 413 PAYLOAD_TOO_LARGE (não 500)', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'a@b.com', password: 'x'.repeat(200_000) });
    expect(res.status).toBe(413);
    expect(res.body).toMatchObject({ statusCode: 413, code: 'PAYLOAD_TOO_LARGE' });
  });

  it('POST /auth/refresh troca refresh por novo par; access no lugar → 401', async () => {
    const server = app.getHttpServer();
    const login = await request(server).post('/auth/login').send(credentials);

    const renewed = await request(server)
      .post('/auth/refresh')
      .send({ refreshToken: login.body.refreshToken });
    expect(renewed.status).toBe(200);
    expect(renewed.body.accessToken).toEqual(expect.any(String));

    const misuse = await request(server)
      .post('/auth/refresh')
      .send({ refreshToken: login.body.accessToken });
    expect(misuse.status).toBe(401);
    expect(misuse.body).toMatchObject({ code: 'INVALID_REFRESH_TOKEN' });
  });

  it('GET /users/me sem token → 401; com refresh → 401; com access → 200 sem hash', async () => {
    const server = app.getHttpServer();
    const anon = await request(server).get('/users/me');
    expect(anon.status).toBe(401);
    expect(anon.body).toMatchObject({ statusCode: 401, code: 'UNAUTHORIZED' });

    const login = await request(server).post('/auth/login').send(credentials);
    const withRefresh = await request(server)
      .get('/users/me')
      .set('Authorization', `Bearer ${login.body.refreshToken}`);
    expect(withRefresh.status).toBe(401);

    const forged = new JwtService({ secret: 'outro-segredo-com-pelo-menos-32-caracteres' });
    const foreign = await forged.signAsync({ sub: 'x', typ: 'access' });
    const withForeign = await request(server)
      .get('/users/me')
      .set('Authorization', `Bearer ${foreign}`);
    expect(withForeign.status).toBe(401);

    const me = await request(server)
      .get('/users/me')
      .set('Authorization', `Bearer ${login.body.accessToken}`);
    expect(me.status).toBe(200);
    expect(me.body).toEqual({
      id: expect.any(String),
      email: credentials.email,
      nickname: null,
      queueUnlockReason: null,
      createdAt: expect.any(String),
    });
  });

  describe('nickname (F35)', () => {
    const server = (): App => app.getHttpServer();
    const login = async (account: { email: string; password: string }): Promise<string> =>
      `Bearer ${((await request(server()).post('/auth/login').send(account)).body as { accessToken: string }).accessToken}`;
    const setNickname = (auth: string, nickname: unknown) =>
      request(server()).put('/users/me/nickname').set('Authorization', auth).send({ nickname });
    const me = async (auth: string) =>
      (await request(server()).get('/users/me').set('Authorization', auth)).body as { nickname: string | null };

    const second = { email: 'segundo@rrb.dev', password: 'senha1234' };
    const third = { email: 'terceiro@rrb.dev', password: 'senha1234' };
    let auth1: string;
    let auth2: string;
    let auth3: string;

    beforeAll(async () => {
      await request(server()).post('/auth/register').send(second);
      await request(server()).post('/auth/register').send(third);
      [auth1, auth2, auth3] = await Promise.all([login(credentials), login(second), login(third)]);
    });

    it('sem token → 401', async () => {
      const res = await request(server()).put('/users/me/nickname').send({ nickname: 'RodReis' });
      expect(res.status).toBe(401);
    });

    it.each([
      ['curto', 'ab'],
      ['longo', 'a'.repeat(17)],
      ['com espaço', 'rod reis'],
      ['com #', '#RodReis'],
      ['acentuado', 'ródrigo'],
    ])('nickname %s → 400 INVALID_NICKNAME e a conta segue sem nickname', async (_caso, nickname) => {
      const res = await setNickname(auth1, nickname);
      expect(res.status).toBe(400);
      expect(res.body).toMatchObject({ statusCode: 400, code: 'INVALID_NICKNAME' });
      expect((await me(auth1)).nickname).toBeNull();
    });

    it('corpo sem o campo → 400 VALIDATION_FAILED', async () => {
      const res = await request(server()).put('/users/me/nickname').set('Authorization', auth1).send({});
      expect(res.status).toBe(400);
      expect(res.body).toMatchObject({ code: 'VALIDATION_FAILED' });
    });

    it('define o nickname (200) e /users/me passa a devolvê-lo na grafia escolhida', async () => {
      const res = await setNickname(auth1, 'RodReis');
      expect(res.status).toBe(200);
      expect(res.body).toMatchObject({ email: credentials.email, nickname: 'RodReis' });
      expect((await me(auth1)).nickname).toBe('RodReis');
    });

    it.each(['RodReis', 'rodreis', 'RODREIS'])('outra conta com %s → 409 NICKNAME_TAKEN (sem diferenciar maiúsculas)', async (nickname) => {
      const res = await setNickname(auth2, nickname);
      expect(res.status).toBe(409);
      expect(res.body).toMatchObject({ statusCode: 409, code: 'NICKNAME_TAKEN' });
      expect((await me(auth2)).nickname).toBeNull();
    });

    it('quem já definiu não troca → 409 NICKNAME_ALREADY_SET', async () => {
      const res = await setNickname(auth1, 'Outro_Nome');
      expect(res.status).toBe(409);
      expect(res.body).toMatchObject({ code: 'NICKNAME_ALREADY_SET' });
      expect((await me(auth1)).nickname).toBe('RodReis');
    });

    it('corrida: duas contas pedem o mesmo nickname ao mesmo tempo → uma 200 e uma 409 (o índice único arbitra)', async () => {
      const [x, y] = await Promise.all([setNickname(auth2, 'Disputado'), setNickname(auth3, 'DISPUTADO')]);
      expect([x.status, y.status].sort()).toEqual([200, 409]);
      const loser = x.status === 409 ? x : y;
      expect(loser.body).toMatchObject({ code: 'NICKNAME_TAKEN' });
    });
  });

  describe('liberação da fila (SPEC-085)', () => {
    const server = (): App => app.getHttpServer();
    const unlock = (auth: string, reason: unknown) =>
      request(server()).post('/users/me/queue-unlock').set('Authorization', auth).send({ reason });
    const profile = async (auth: string) =>
      (await request(server()).get('/users/me').set('Authorization', auth)).body as {
        queueUnlockReason: string | null;
      };
    const accounts = ['lib1', 'lib2', 'lib3'].map((name) => ({ email: `${name}@rrb.dev`, password: 'senha1234' }));
    let auths: string[];

    beforeAll(async () => {
      auths = [];
      for (const account of accounts) {
        await request(server()).post('/auth/register').send(account);
        const login = await request(server()).post('/auth/login').send(account);
        auths.push(`Bearer ${(login.body as { accessToken: string }).accessToken}`);
      }
    });

    it('sem token → 401', async () => {
      const res = await request(server()).post('/users/me/queue-unlock').send({ reason: 'tutorial' });
      expect(res.status).toBe(401);
    });

    it.each([
      ['tutorial', 0],
      ['bot_win', 1],
    ] as const)('registra %s (200) e o perfil expõe o motivo', async (reason, i) => {
      expect((await profile(auths[i]!)).queueUnlockReason).toBeNull();

      const res = await unlock(auths[i]!, reason);

      expect(res.status).toBe(200);
      expect(res.body).toMatchObject({ queueUnlockReason: reason });
      expect((await profile(auths[i]!)).queueUnlockReason).toBe(reason);
    });

    it('idempotente: segunda chamada com outro motivo → 200 e mantém o original', async () => {
      const res = await unlock(auths[0]!, 'bot_win');
      expect(res.status).toBe(200);
      expect(res.body).toMatchObject({ queueUnlockReason: 'tutorial' });
    });

    it.each([['history'], ['outro'], [42], [null], [undefined]])(
      'reason %p → 400 VALIDATION_FAILED e a conta segue bloqueada',
      async (reason) => {
        const res = await unlock(auths[2]!, reason);
        expect(res.status).toBe(400);
        expect(res.body).toMatchObject({ code: 'VALIDATION_FAILED' });
        expect((await profile(auths[2]!)).queueUnlockReason).toBeNull();
      },
    );
  });
});

describe('rate limit em /auth/* (e2e)', () => {
  it('estoura o limite → 429 RATE_LIMITED', async () => {
    const app = await createApp({ AUTH_RATE_LIMIT: 2 });
    const server = app.getHttpServer();
    const body = { email: 'ninguem@rrb.dev', password: 'qualquer1' };
    const statuses: number[] = [];
    for (let i = 0; i < 3; i++) {
      statuses.push((await request(server).post('/auth/login').send(body)).status);
    }
    const last = await request(server).post('/auth/login').send(body);
    await app.close();

    expect(statuses).toEqual([401, 401, 429]);
    expect(last.body).toMatchObject({ statusCode: 429, code: 'RATE_LIMITED' });
  });
});
