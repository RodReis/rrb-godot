import { ConflictException, Inject, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { QueueTicket } from '../../drizzle/schema';
import { APP_CONFIG } from '../common/app-config';
import { errorMessage } from '../common/error-message';
import { Clock } from '../common/clock';
import { Mutex } from '../common/mutex';
import type { AppConfig } from '../config';
import { MatchesRepository } from '../matches/matches.repository';
import { MatchesService } from '../matches/matches.service';
import { MatchAssignment, OrchestratorService } from '../orchestrator/orchestrator.service';
import { QueueRepository } from './queue.repository';

/** Vocabulário do Launcher (`QueueService.searching | matched | cancelled`, ARCHITECTURE-LAUNCHER §3.3). */
export type TicketState = 'searching' | 'matched' | 'cancelled';

export interface TicketView {
  status: TicketState;
  elapsedS: number;
  /** Em `matched`: o Launcher manda `POST /matches/:id/abandon` se o Game não abrir. */
  matchId?: string;
  /** Presente enquanto a partida existe e o token ainda está em memória. */
  assignment?: MatchAssignment;
}

const PAIR_SIZE = 2;
const MS_PER_SECOND = 1000;

const notFound = (): NotFoundException =>
  new NotFoundException({ code: 'TICKET_NOT_FOUND', message: 'Ticket não encontrado' });

/**
 * Fila 1x1 FIFO sem rating (PRD §8.4). Postgres é a fonte de verdade; toda mutação passa pelo
 * mutex, então o pareamento não corre contra `cancel` nem contra a varredura.
 */
@Injectable()
export class QueueService {
  private readonly logger = new Logger(QueueService.name);
  private readonly lock = new Mutex();

  constructor(
    private readonly tickets: QueueRepository,
    private readonly matches: MatchesRepository,
    private readonly matchesService: MatchesService,
    private readonly orchestrator: OrchestratorService,
    private readonly clock: Clock,
    @Inject(APP_CONFIG) private readonly config: AppConfig,
  ) {}

  join(userId: string): Promise<QueueTicket> {
    return this.lock.run(async () => {
      const alreadyQueued = (): ConflictException =>
        new ConflictException({ code: 'ALREADY_QUEUED', message: 'Esta conta já está na fila ou em partida' });
      if (await this.matches.userHasActiveMatch(userId)) throw alreadyQueued();
      const ticket = await this.tickets.create(userId, this.clock.now());
      if (!ticket) throw alreadyQueued();
      await this.pairPending();
      return ticket;
    });
  }

  /** Cada consulta renova o ticket: o polling do Launcher (2 s) é o sinal de vida da conta. */
  async status(userId: string, ticketId: string): Promise<TicketView> {
    const ticket = await this.owned(userId, ticketId);
    const elapsedS = Math.floor((this.clock.now().getTime() - ticket.createdAt.getTime()) / MS_PER_SECOND);
    if (ticket.status === 'waiting') {
      await this.tickets.touch(ticket.id, this.clock.now());
      return { status: 'searching', elapsedS };
    }
    if (ticket.status !== 'matched' || !ticket.matchId) return { status: 'cancelled', elapsedS };
    const match = await this.matches.findById(ticket.matchId);
    if (!match || match.status === 'aborted') return { status: 'cancelled', elapsedS };
    const assignment = this.orchestrator.assignmentFor(match.id, userId);
    const matched = { status: 'matched' as const, elapsedS, matchId: match.id };
    return assignment ? { ...matched, assignment } : matched;
  }

  /** Idempotente para ticket já cancelado/expirado; pareado só sai por `abandon` da partida. */
  cancel(userId: string, ticketId: string): Promise<void> {
    return this.lock.run(async () => {
      const ticket = await this.owned(userId, ticketId);
      if (ticket.status === 'matched') {
        throw new ConflictException({ code: 'ALREADY_MATCHED', message: 'O ticket já foi pareado' });
      }
      await this.tickets.cancel(ticket.id);
    });
  }

  /** Varredura periódica: expira tickets sem polling e pareia o que sobrou (ex.: pool voltou a ter vaga). */
  sweep(): Promise<void> {
    return this.lock.run(() => this.pairPending());
  }

  private async owned(userId: string, ticketId: string): Promise<QueueTicket> {
    const ticket = await this.tickets.findById(ticketId);
    if (!ticket || ticket.userId !== userId) throw notFound();
    return ticket;
  }

  /** Chamar com o lock tomado. Falha de infraestrutura deixa os tickets na fila para a próxima varredura. */
  private async pairPending(): Promise<void> {
    try {
      const staleBefore = new Date(this.clock.now().getTime() - this.config.TICKET_STALE_MS);
      await this.tickets.expireStale(staleBefore);
      for (;;) {
        const waiting = await this.tickets.listWaiting(PAIR_SIZE);
        if (waiting.length < PAIR_SIZE) return;
        const assigned = await this.orchestrator.assign(waiting.map((ticket) => ticket.userId));
        if (!assigned) return;
        if (!(await this.tickets.markMatched(waiting.map((ticket) => ticket.id), assigned.matchId))) {
          await this.matchesService.abort(assigned.matchId, 'pairing_failed');
          return;
        }
      }
    } catch (error) {
      this.logger.error(`Pareamento falhou: ${errorMessage(error)}`);
    }
  }
}
