import { JwtService } from '@nestjs/jwt';
import { FakeClock, InMemoryMatchesRepository } from '../../test/support/fakes';
import type { AppConfig } from '../config';
import { MatchTokenService } from '../orchestrator/match-token.service';
import type { OrchestratorService } from '../orchestrator/orchestrator.service';
import { MatchesService } from './matches.service';
import type { MatchResult } from './matches.repository';

const SECRET = 'segredo-de-teste-com-32-caracteres!!';
const A = '11111111-1111-4111-8111-111111111111';
const B = '22222222-2222-4222-8222-222222222222';
const OUTSIDER = '33333333-3333-4333-8333-333333333333';

const config = {
  MATCH_TOKEN_TTL_S: 120,
  HEARTBEAT_INTERVAL_MS: 10_000,
  HEARTBEAT_MISS_LIMIT: 3,
} as AppConfig;

function statsFor(userId: string): MatchResult['players'][number] {
  return {
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
  };
}

const RESULT: MatchResult = {
  winnerUserId: A,
  endReason: 'kill_goal',
  durationS: 540,
  players: [statsFor(A), statsFor(B)],
};

async function code(promise: Promise<unknown>): Promise<unknown> {
  return promise.then(
    () => undefined,
    (error: { getResponse(): { code: string } }) => error.getResponse().code,
  );
}

describe('MatchesService', () => {
  let repo: InMemoryMatchesRepository;
  let clock: FakeClock;
  let tokens: MatchTokenService;
  let orchestrator: { release: jest.Mock };
  let service: MatchesService;

  /** Cria uma partida `assigned` como o orquestrador faria. */
  async function assigned(matchId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'): Promise<{ id: string; token: string }> {
    const token = await tokens.sign(matchId, [A, B]);
    await repo.createAssigned({
      id: matchId,
      playerIds: [A, B],
      serverHost: '127.0.0.1',
      serverPort: 7000,
      tokenHash: MatchTokenService.hash(token),
      seed: 42,
      now: clock.now(),
    });
    return { id: matchId, token };
  }

  beforeEach(() => {
    repo = new InMemoryMatchesRepository();
    clock = new FakeClock();
    tokens = new MatchTokenService(new JwtService({ secret: SECRET }), config);
    orchestrator = { release: jest.fn().mockResolvedValue(undefined) };
    service = new MatchesService(repo, tokens, orchestrator as unknown as OrchestratorService, clock, config);
  });

  describe('validate', () => {
    it('token válido: assigned → running, devolve seed e jogadores; chamar de novo é idempotente', async () => {
      const { id, token } = await assigned();

      const first = await service.validate(id, token);
      const second = await service.validate(id, token);

      expect(first).toEqual({ matchId: id, playerIds: [A, B], seed: 42 });
      expect(second).toEqual(first);
      expect(repo.rows.get(id)).toMatchObject({ status: 'running', startedAt: clock.now() });
    });

    it('os dois peers chegando juntos: ambos recebem 200 (o que perdeu a corrida do markRunning também vale)', async () => {
      const { id, token } = await assigned();

      const results = await Promise.all([service.validate(id, token), service.validate(id, token)]);

      expect(results[1]).toEqual(results[0]);
      expect(repo.rows.get(id)?.status).toBe('running');
    });

    it('token de outra partida (assinatura válida) → TOKEN_INVALID', async () => {
      const mine = await assigned();
      const other = await assigned('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');

      expect(await code(service.validate(mine.id, other.token))).toBe('TOKEN_INVALID');
      expect(repo.rows.get(mine.id)?.status).toBe('assigned');
    });

    it('token válido mas diferente do emitido (hash não bate) → TOKEN_INVALID', async () => {
      const { id, token } = await assigned();
      const forged = await new JwtService({ secret: SECRET }).signAsync(
        { typ: 'match', match_id: id, player_ids: [A, B], iat: Math.floor(Date.now() / 1000) - 30 },
        { expiresIn: 120 },
      ); // mesma partida, assinatura válida, mas não é o token que o orquestrador emitiu

      expect(forged).not.toBe(token);
      expect(await code(service.validate(id, forged))).toBe('TOKEN_INVALID');
    });

    it('token expirado → TOKEN_EXPIRED e a partida continua assigned', async () => {
      const { id } = await assigned();
      const expired = await new JwtService({ secret: SECRET }).signAsync(
        { typ: 'match', match_id: id, player_ids: [A, B] },
        { expiresIn: -5 },
      );

      expect(await code(service.validate(id, expired))).toBe('TOKEN_EXPIRED');
      expect(repo.rows.get(id)?.status).toBe('assigned');
    });

    it('partida inexistente → 404 MATCH_NOT_FOUND', async () => {
      const ghost = '99999999-9999-4999-8999-999999999999';
      const token = await tokens.sign(ghost, [A, B]);

      expect(await code(service.validate(ghost, token))).toBe('MATCH_NOT_FOUND');
    });

    it.each(['finished', 'aborted'] as const)('partida %s → 409 MATCH_NOT_ACTIVE', async (status) => {
      const { id, token } = await assigned();
      repo.rows.set(id, { ...repo.rows.get(id)!, status });

      expect(await code(service.validate(id, token))).toBe('MATCH_NOT_ACTIVE');
    });
  });

  describe('heartbeat', () => {
    it('partida running: atualiza last_heartbeat_at', async () => {
      const { id, token } = await assigned();
      await service.validate(id, token);
      clock.advance(10_000);

      await service.heartbeat(id);

      expect(repo.rows.get(id)?.lastHeartbeatAt).toEqual(clock.now());
    });

    it('assigned ou terminada → 409 MATCH_NOT_RUNNING; inexistente → 404', async () => {
      const { id } = await assigned();

      expect(await code(service.heartbeat(id))).toBe('MATCH_NOT_RUNNING');
      expect(await code(service.heartbeat('99999999-9999-4999-8999-999999999999'))).toBe('MATCH_NOT_FOUND');
    });
  });

  describe('result', () => {
    async function running(): Promise<string> {
      const { id, token } = await assigned();
      await service.validate(id, token);
      return id;
    }

    it('running → finished com vencedor, motivo, duração e estatísticas; libera o container', async () => {
      const id = await running();
      clock.advance(540_000);

      await service.result(id, RESULT);

      expect(repo.rows.get(id)).toMatchObject({
        status: 'finished',
        winnerUserId: A,
        endReason: 'kill_goal',
        durationS: 540,
        endedAt: clock.now(),
      });
      expect(repo.players.get(id)?.get(A)).toMatchObject({ heroId: 'arqueiro', kills: 3, finalLevel: 7 });
      expect(repo.players.get(id)?.get(B)).toMatchObject({ heroId: 'arqueiro', deaths: 1 });
      expect(orchestrator.release).toHaveBeenCalledWith(id);
    });

    it('resultado repetido → 409 MATCH_NOT_RUNNING (não regrava)', async () => {
      const id = await running();
      await service.result(id, RESULT);

      expect(await code(service.result(id, { ...RESULT, winnerUserId: B }))).toBe('MATCH_NOT_RUNNING');
      expect(repo.rows.get(id)?.winnerUserId).toBe(A);
    });

    it('antes do validate (assigned) → 409 MATCH_NOT_RUNNING', async () => {
      const { id } = await assigned();

      expect(await code(service.result(id, RESULT))).toBe('MATCH_NOT_RUNNING');
    });

    it.each([
      ['jogador de fora', { ...RESULT, players: [statsFor(A), statsFor(OUTSIDER)] }],
      ['jogador repetido', { ...RESULT, players: [statsFor(A), statsFor(A)] }],
      ['vencedor de fora', { ...RESULT, winnerUserId: OUTSIDER }],
    ])('%s → 400 INVALID_RESULT e a partida segue running', async (_caso, body) => {
      const id = await running();

      expect(await code(service.result(id, body))).toBe('INVALID_RESULT');
      expect(repo.rows.get(id)?.status).toBe('running');
      expect(orchestrator.release).not.toHaveBeenCalled();
    });

    it('partida sem vencedor e sem jogadores (abandoned) é aceita', async () => {
      const id = await running();

      await service.result(id, { winnerUserId: null, endReason: 'abandoned', durationS: 90, players: [] });

      expect(repo.rows.get(id)).toMatchObject({ status: 'finished', winnerUserId: null, endReason: 'abandoned' });
    });

    it('partida inexistente → 404', async () => {
      expect(await code(service.result('99999999-9999-4999-8999-999999999999', RESULT))).toBe('MATCH_NOT_FOUND');
    });
  });

  describe('abandon', () => {
    it('participante em assigned: aborta com "abandoned" e libera o container', async () => {
      const { id } = await assigned();

      await service.abandon(id, B);

      expect(repo.rows.get(id)).toMatchObject({ status: 'aborted', endReason: 'abandoned' });
      expect(orchestrator.release).toHaveBeenCalledWith(id);
    });

    it('chamar de novo é idempotente (sem segundo release)', async () => {
      const { id } = await assigned();
      await service.abandon(id, A);

      await expect(service.abandon(id, A)).resolves.toBeUndefined();
      expect(orchestrator.release).toHaveBeenCalledTimes(1);
    });

    it('quem não está na partida e partida inexistente → 404 (não vaza que a partida existe)', async () => {
      const { id } = await assigned();

      expect(await code(service.abandon(id, OUTSIDER))).toBe('MATCH_NOT_FOUND');
      expect(await code(service.abandon('99999999-9999-4999-8999-999999999999', A))).toBe('MATCH_NOT_FOUND');
      expect(repo.rows.get(id)?.status).toBe('assigned');
    });

    it('partida já running ou finished → 409 MATCH_NOT_ASSIGNED', async () => {
      const { id, token } = await assigned();
      await service.validate(id, token);

      expect(await code(service.abandon(id, A))).toBe('MATCH_NOT_ASSIGNED');
      expect(repo.rows.get(id)?.status).toBe('running');
    });
  });

  describe('sweep', () => {
    it('assigned com token vencido sem validate → aborted "token_expired" e container liberado', async () => {
      const { id } = await assigned();

      clock.advance(120_000);
      await service.sweep();
      expect(repo.rows.get(id)?.status).toBe('assigned'); // ainda no limite

      clock.advance(1);
      await service.sweep();
      expect(repo.rows.get(id)).toMatchObject({ status: 'aborted', endReason: 'token_expired' });
      expect(orchestrator.release).toHaveBeenCalledWith(id);
    });

    it('3 heartbeats perdidos (30 s) → aborted "heartbeat_lost"; heartbeat em dia mantém', async () => {
      const { id, token } = await assigned();
      await service.validate(id, token);

      clock.advance(30_000);
      await service.sweep();
      expect(repo.rows.get(id)?.status).toBe('running'); // exatamente 3 intervalos: ainda não

      await service.heartbeat(id);
      clock.advance(30_001);
      await service.sweep();
      expect(repo.rows.get(id)).toMatchObject({ status: 'aborted', endReason: 'heartbeat_lost' });
      expect(orchestrator.release).toHaveBeenCalledWith(id);
    });

    it('um erro ao liberar uma partida não impede as outras', async () => {
      const first = await assigned();
      const second = await assigned('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');
      orchestrator.release.mockRejectedValueOnce(new Error('docker caiu'));

      clock.advance(121_000);
      await expect(service.sweep()).resolves.toBeUndefined();

      expect(repo.rows.get(first.id)?.status).toBe('aborted');
      expect(repo.rows.get(second.id)?.status).toBe('aborted');
    });
  });
});
