import { JwtService } from '@nestjs/jwt';
import { FakeClock, FakeContainerRuntime, InMemoryMatchesRepository } from '../../test/support/fakes';
import type { AppConfig } from '../config';
import { MatchTokenService } from './match-token.service';
import { OrchestratorService } from './orchestrator.service';

const PLAYERS = ['u1', 'u2'];

const config = {
  JWT_SECRET: 'segredo-de-teste-com-32-caracteres!!',
  MATCH_TOKEN_TTL_S: 120,
  POOL_SIZE: 2,
  POOL_MAX: 3,
  GAME_PORT_MIN: 7000,
  GAME_PORT_MAX: 7020,
  GAMESERVER_PUBLIC_HOST: 'jogo.exemplo.com',
} as AppConfig;

describe('OrchestratorService', () => {
  let runtime: FakeContainerRuntime;
  let matches: InMemoryMatchesRepository;
  let tokens: MatchTokenService;
  let orchestrator: OrchestratorService;

  function build(overrides: Partial<AppConfig> = {}): OrchestratorService {
    const cfg = { ...config, ...overrides };
    const jwt = new JwtService({ secret: cfg.JWT_SECRET });
    tokens = new MatchTokenService(jwt, cfg);
    return new OrchestratorService(runtime, matches, tokens, new FakeClock(), cfg);
  }

  beforeEach(() => {
    runtime = new FakeContainerRuntime();
    matches = new InMemoryMatchesRepository();
    orchestrator = build();
  });

  describe('warm', () => {
    it('limpa containers antigos, aborta partidas órfãs e sobe POOL_SIZE nas primeiras portas', async () => {
      await matches.createAssigned({
        id: 'antiga',
        playerIds: PLAYERS,
        serverHost: 'x',
        serverPort: 7000,
        tokenHash: 'h',
        seed: 1,
        now: new Date(),
      });

      await orchestrator.warm();

      expect(runtime.removeAllCalls).toBe(1);
      expect(runtime.started).toEqual([7000, 7001]);
      expect(matches.rows.get('antiga')).toMatchObject({ status: 'aborted', endReason: 'backend_restart' });
    });

    it('aborta as partidas órfãs mesmo se limpar os containers falhar', async () => {
      await matches.createAssigned({
        id: 'antiga',
        playerIds: PLAYERS,
        serverHost: 'x',
        serverPort: 7000,
        tokenHash: 'h',
        seed: 1,
        now: new Date(),
      });
      jest.spyOn(runtime, 'removeAllManaged').mockRejectedValueOnce(new Error('docker fora'));

      await orchestrator.warm();

      expect(matches.rows.get('antiga')?.status).toBe('aborted');
    });

    it('Docker fora do ar no boot não derruba o backend (pool vazio, assign devolve null)', async () => {
      runtime.failStart = true;

      await expect(orchestrator.warm()).resolves.toBeUndefined();
      await expect(orchestrator.assign(PLAYERS)).resolves.toBeNull();
    });
  });

  describe('assign', () => {
    it('usa um container ocioso: grava matches(assigned) e devolve host, porta e token válido', async () => {
      await orchestrator.warm();

      const assigned = await orchestrator.assign(PLAYERS);

      expect(assigned).not.toBeNull();
      const { matchId, assignment } = assigned!;
      expect(assignment).toMatchObject({ host: 'jogo.exemplo.com', port: 7000 });
      expect(runtime.started).toEqual([7000, 7001]); // nenhum container novo antes de repor
      const row = matches.rows.get(matchId)!;
      expect(row).toMatchObject({ status: 'assigned', serverHost: 'jogo.exemplo.com', serverPort: 7000 });
      expect(row.tokenHash).toBe(MatchTokenService.hash(assignment.token));
      await expect(tokens.verify(assignment.token)).resolves.toMatchObject({
        match_id: matchId,
        player_ids: PLAYERS,
      });
      expect(await matches.playerIds(matchId)).toEqual(PLAYERS);
    });

    it('repõe o pool em segundo plano depois de alocar', async () => {
      await orchestrator.warm();

      await orchestrator.assign(PLAYERS);
      await orchestrator.settle();

      expect(runtime.started).toEqual([7000, 7001, 7002]);
    });

    it('pool vazio sobe container sob demanda; passou de POOL_MAX devolve null', async () => {
      orchestrator = build({ POOL_SIZE: 0, POOL_MAX: 2 });

      const first = await orchestrator.assign(['a', 'b']);
      const second = await orchestrator.assign(['c', 'd']);
      const third = await orchestrator.assign(['e', 'f']);

      expect(first?.assignment.port).toBe(7000);
      expect(second?.assignment.port).toBe(7001);
      expect(third).toBeNull();
    });

    it('porta que falha ao subir não trava o pool: usa a próxima livre', async () => {
      orchestrator = build({ POOL_SIZE: 0 });
      runtime.failPorts.add(7000);

      const assigned = await orchestrator.assign(PLAYERS);

      expect(assigned?.assignment.port).toBe(7001);
    });

    it('respeita a faixa de portas mesmo com POOL_MAX maior que ela', async () => {
      orchestrator = build({ POOL_SIZE: 0, POOL_MAX: 99, GAME_PORT_MIN: 7000, GAME_PORT_MAX: 7001 });

      await orchestrator.assign(['a', 'b']);
      await orchestrator.assign(['c', 'd']);

      await expect(orchestrator.assign(['e', 'f'])).resolves.toBeNull();
      expect(runtime.started).toEqual([7000, 7001]);
    });

    it('falha ao gravar a partida devolve o container e propaga o erro', async () => {
      await orchestrator.warm();
      jest.spyOn(matches, 'createAssigned').mockRejectedValueOnce(new Error('banco caiu'));

      await expect(orchestrator.assign(PLAYERS)).rejects.toThrow('banco caiu');
      await orchestrator.settle();

      // o container usado foi removido e recriado; nada fica preso como ocupado
      expect(runtime.removed).toEqual(['container-1']);
      await expect(orchestrator.assign(PLAYERS)).resolves.not.toBeNull();
    });
  });

  describe('release', () => {
    it('recria o container: remove o usado, repõe o pool na porta liberada e esquece o assignment', async () => {
      await orchestrator.warm(); // c1@7000, c2@7001
      const first = (await orchestrator.assign(['a', 'b']))!; // c1 ocupado, repõe c3@7002
      await orchestrator.settle();
      await orchestrator.assign(['c', 'd']); // c2 ocupado; POOL_MAX=3 impede repor
      await orchestrator.settle();
      expect(orchestrator.assignmentFor(first.matchId)).toBeDefined();
      expect(runtime.started).toEqual([7000, 7001, 7002]);

      await orchestrator.release(first.matchId);
      await orchestrator.settle();

      expect(orchestrator.assignmentFor(first.matchId)).toBeUndefined();
      expect(runtime.removed).toEqual(['container-1']);
      expect(runtime.started).toEqual([7000, 7001, 7002, 7000]); // volta na porta mais baixa livre
    });

    it('com o pool já cheio, soltar não sobe container extra', async () => {
      await orchestrator.warm();
      const { matchId } = (await orchestrator.assign(PLAYERS))!;
      await orchestrator.settle(); // c1 ocupado, c2 e c3 ociosos

      await orchestrator.release(matchId);
      await orchestrator.settle();

      expect(runtime.removed).toEqual(['container-1']);
      expect(runtime.started).toEqual([7000, 7001, 7002]);
    });

    it('soltar partida desconhecida é inofensivo', async () => {
      await expect(orchestrator.release('nao-existe')).resolves.toBeUndefined();
      expect(runtime.removed).toEqual([]);
    });
  });
});
