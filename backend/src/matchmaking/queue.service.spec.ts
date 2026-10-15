import { FakeClock, InMemoryMatchesRepository, InMemoryQueueRepository } from '../../test/support/fakes';
import type { AppConfig } from '../config';
import type { MatchesService } from '../matches/matches.service';
import type { AssignedMatch, MatchAssignment, OrchestratorService } from '../orchestrator/orchestrator.service';
import { QueueService } from './queue.service';

const config = { TICKET_STALE_MS: 10_000 } as AppConfig;
const A = 'user-a';
const B = 'user-b';
const C = 'user-c';
const D = 'user-d';

/** Orquestrador de mentira: grava a partida como o real e deixa o teste cortar a capacidade. */
class FakeOrchestrator {
  hasCapacity = true;
  readonly assigned: string[][] = [];
  private readonly assignments = new Map<string, MatchAssignment>();

  constructor(
    private readonly matches: InMemoryMatchesRepository,
    private readonly clock: FakeClock,
  ) {}

  async assign(playerIds: string[]): Promise<AssignedMatch | null> {
    if (!this.hasCapacity) return null;
    const matchId = `match-${this.assigned.length + 1}`;
    this.assigned.push(playerIds);
    await this.matches.createAssigned({
      id: matchId,
      playerIds,
      serverHost: 'h',
      serverPort: 7000,
      tokenHash: 'x',
      seed: 1,
      now: this.clock.now(),
    });
    const assignment = { host: 'h', port: 7000 + this.assigned.length, token: `token-${matchId}` };
    this.assignments.set(matchId, assignment);
    return { matchId, assignment };
  }

  assignmentFor(matchId: string): MatchAssignment | undefined {
    return this.assignments.get(matchId);
  }

  drop(matchId: string): void {
    this.assignments.delete(matchId);
  }
}

async function code(promise: Promise<unknown>): Promise<unknown> {
  return promise.then(
    () => undefined,
    (error: { getResponse(): { code: string } }) => error.getResponse().code,
  );
}

describe('QueueService', () => {
  let tickets: InMemoryQueueRepository;
  let matches: InMemoryMatchesRepository;
  let clock: FakeClock;
  let orchestrator: FakeOrchestrator;
  let matchesService: { abort: jest.Mock };
  let service: QueueService;

  beforeEach(() => {
    tickets = new InMemoryQueueRepository();
    matches = new InMemoryMatchesRepository();
    clock = new FakeClock();
    orchestrator = new FakeOrchestrator(matches, clock);
    matchesService = { abort: jest.fn().mockResolvedValue(true) };
    service = new QueueService(
      tickets,
      matches,
      matchesService as unknown as MatchesService,
      orchestrator as unknown as OrchestratorService,
      clock,
      config,
    );
  });

  describe('join', () => {
    it('cria ticket waiting e fica procurando enquanto não há par', async () => {
      const ticket = await service.join(A);

      expect(ticket).toMatchObject({ userId: A, status: 'waiting' });
      expect(orchestrator.assigned).toEqual([]);
    });

    it('I8: segundo ticket da mesma conta é recusado (ALREADY_QUEUED)', async () => {
      await service.join(A);

      expect(await code(service.join(A))).toBe('ALREADY_QUEUED');
      expect(tickets.rows).toHaveLength(1);
    });

    it('I8: conta com partida em andamento não entra na fila de novo', async () => {
      await service.join(A);
      await service.join(B); // pareia: A e B estão em match-1 (assigned)

      expect(await code(service.join(A))).toBe('ALREADY_QUEUED');
    });

    it('depois que a partida termina a conta pode entrar de novo', async () => {
      await service.join(A);
      await service.join(B);
      await matches.abort('match-1', 'qualquer', clock.now());

      await expect(service.join(A)).resolves.toMatchObject({ status: 'waiting' });
    });
  });

  describe('pareamento FIFO 1x1', () => {
    it('dois tickets formam par: os dois ficam matched na mesma partida', async () => {
      const a = await service.join(A);
      const b = await service.join(B);

      expect(orchestrator.assigned).toEqual([[A, B]]);
      expect(await tickets.findById(a.id)).toMatchObject({ status: 'matched', matchId: 'match-1' });
      expect(await tickets.findById(b.id)).toMatchObject({ status: 'matched', matchId: 'match-1' });
    });

    it('respeita a ordem de chegada: A,B pareiam; C espera; D pareia com C', async () => {
      await service.join(A);
      await service.join(B);
      const c = await service.join(C);
      expect(await tickets.findById(c.id)).toMatchObject({ status: 'waiting' });

      await service.join(D);

      expect(orchestrator.assigned).toEqual([
        [A, B],
        [C, D],
      ]);
    });

    it('ticket cancelado não entra em par', async () => {
      const a = await service.join(A);
      await service.cancel(A, a.id);

      const b = await service.join(B);

      expect(orchestrator.assigned).toEqual([]);
      expect(await tickets.findById(b.id)).toMatchObject({ status: 'waiting' });
    });

    it('sem capacidade no pool os tickets esperam e pareiam na varredura seguinte', async () => {
      orchestrator.hasCapacity = false;
      const a = await service.join(A);
      const b = await service.join(B);
      expect(await tickets.findById(a.id)).toMatchObject({ status: 'waiting' });

      orchestrator.hasCapacity = true;
      await service.sweep();

      expect(await tickets.findById(a.id)).toMatchObject({ status: 'matched' });
      expect(await tickets.findById(b.id)).toMatchObject({ status: 'matched' });
    });

    it('com 4 esperando e vaga aberta, pareia na ordem de chegada: (A,B) e depois (C,D)', async () => {
      orchestrator.hasCapacity = false;
      for (const user of [A, B, C, D]) await service.join(user);

      orchestrator.hasCapacity = true;
      await service.sweep();

      expect(orchestrator.assigned).toEqual([
        [A, B],
        [C, D],
      ]);
    });

    it('ticket sem polling há mais de TICKET_STALE_MS expira e não é pareado', async () => {
      const a = await service.join(A);
      clock.advance(10_001);

      const b = await service.join(B);

      expect(await tickets.findById(a.id)).toMatchObject({ status: 'expired' });
      expect(await tickets.findById(b.id)).toMatchObject({ status: 'waiting' });
      expect(orchestrator.assigned).toEqual([]);
    });

    it('polling mantém o ticket vivo', async () => {
      const a = await service.join(A);
      clock.advance(8_000);
      await service.status(A, a.id);
      clock.advance(8_000);

      await service.join(B);

      expect(orchestrator.assigned).toEqual([[A, B]]);
    });

    it('se o ticket mudou no meio do pareamento, a partida criada é abortada', async () => {
      await service.join(A);
      jest.spyOn(tickets, 'markMatched').mockResolvedValueOnce(false);

      await service.join(B);

      expect(matchesService.abort).toHaveBeenCalledWith('match-1', 'pairing_failed');
    });
  });

  describe('status', () => {
    it('waiting → searching com o tempo decorrido', async () => {
      const a = await service.join(A);
      clock.advance(5_400);

      expect(await service.status(A, a.id)).toEqual({ status: 'searching', elapsedS: 5 });
    });

    it('matched → os dois jogadores recebem o mesmo assignment', async () => {
      const a = await service.join(A);
      const b = await service.join(B);

      const forA = await service.status(A, a.id);
      const forB = await service.status(B, b.id);

      expect(forA).toMatchObject({
        status: 'matched',
        assignment: { host: 'h', port: 7001, token: 'token-match-1' },
      });
      expect(forB).toEqual(forA);
    });

    it('matched com a partida já em andamento e sem assignment em memória → matched sem assignment', async () => {
      const a = await service.join(A);
      await service.join(B);
      await matches.markRunning('match-1', clock.now());
      orchestrator.drop('match-1');

      expect(await service.status(A, a.id)).toEqual({ status: 'matched', elapsedS: 0 });
    });

    it('matched mas a partida foi abortada → cancelled', async () => {
      const a = await service.join(A);
      await service.join(B);
      await matches.abort('match-1', 'token_expired', clock.now());

      expect(await service.status(A, a.id)).toMatchObject({ status: 'cancelled' });
    });

    it('cancelado e expirado aparecem como cancelled', async () => {
      const a = await service.join(A);
      await service.cancel(A, a.id);
      expect(await service.status(A, a.id)).toMatchObject({ status: 'cancelled' });

      const b = await service.join(B);
      clock.advance(10_001);
      await service.sweep();
      expect(await service.status(B, b.id)).toMatchObject({ status: 'cancelled' });
    });

    it('ticket de outra conta ou inexistente → 404 TICKET_NOT_FOUND', async () => {
      const a = await service.join(A);

      expect(await code(service.status(B, a.id))).toBe('TICKET_NOT_FOUND');
      expect(await code(service.status(A, 'nao-existe'))).toBe('TICKET_NOT_FOUND');
    });
  });

  describe('cancel', () => {
    it('waiting → cancelled; repetir é idempotente', async () => {
      const a = await service.join(A);

      await service.cancel(A, a.id);
      await expect(service.cancel(A, a.id)).resolves.toBeUndefined();

      expect(await tickets.findById(a.id)).toMatchObject({ status: 'cancelled' });
    });

    it('já pareado → 409 ALREADY_MATCHED (quem desiste usa abandon)', async () => {
      const a = await service.join(A);
      await service.join(B);

      expect(await code(service.cancel(A, a.id))).toBe('ALREADY_MATCHED');
    });

    it('ticket de outra conta → 404', async () => {
      const a = await service.join(A);

      expect(await code(service.cancel(B, a.id))).toBe('TICKET_NOT_FOUND');
      expect(await tickets.findById(a.id)).toMatchObject({ status: 'waiting' });
    });
  });
});
