import { randomInt, randomUUID } from 'node:crypto';
import { Inject, Injectable, Logger } from '@nestjs/common';
import { APP_CONFIG } from '../common/app-config';
import { errorMessage } from '../common/error-message';
import { Clock } from '../common/clock';
import { Mutex } from '../common/mutex';
import type { AppConfig } from '../config';
import { MatchesRepository } from '../matches/matches.repository';
import { ContainerRuntime } from './container-runtime';
import { MatchTokenService } from './match-token.service';

/** O que o Launcher recebe para abrir o jogo (§4.2 passos 4–5). */
export interface MatchAssignment {
  host: string;
  port: number;
  token: string;
}

/** Um token por jogador (§4.2): `assignments` é indexado pelo id da conta. */
export interface AssignedMatch {
  matchId: string;
  assignments: Record<string, MatchAssignment>;
}

interface Slot {
  port: number;
  containerId: string;
  /** `undefined` = ocioso, pré-aquecido. */
  matchId?: string;
}

const SEED_BOUND = 2 ** 31;
/** Quantas portas livres tentar por pedido antes de desistir (Docker fora do ar falha em todas). */
const MAX_PORT_ATTEMPTS = 3;

/**
 * Pool de game servers (§4.2). Estado do pool fica em memória (instância única): no boot os
 * containers antigos são removidos e as partidas ativas abortadas, então não há o que reconciliar.
 *
 * Reciclar vs. recriar (§4.2 passo 7): recria. Medido com a imagem do game server: recriar
 * (rm + create + start) ≈ 2,0 s; `restart` ≈ 2,4–2,9 s; `start` de container parado ≈ 1,2 s. A diferença
 * é invisível porque o pool repõe em segundo plano, e recriar entrega fs limpo e a imagem atual.
 */
@Injectable()
export class OrchestratorService {
  private readonly logger = new Logger(OrchestratorService.name);
  private readonly slots = new Map<number, Slot>();
  private readonly assignments = new Map<string, Map<string, MatchAssignment>>();
  private readonly mutex = new Mutex();
  private background: Promise<void> = Promise.resolve();

  constructor(
    private readonly runtime: ContainerRuntime,
    private readonly matches: MatchesRepository,
    private readonly tokens: MatchTokenService,
    private readonly clock: Clock,
    @Inject(APP_CONFIG) private readonly config: AppConfig,
  ) {}

  /** Boot: limpa o que sobrou de execuções anteriores e pré-aquece o pool. Nunca derruba o backend. */
  async warm(): Promise<void> {
    // As partidas ativas do banco são abortadas mesmo se o Docker não responder: sem isso as contas
    // ficariam presas em ALREADY_QUEUED até o sweeper vencer o token.
    try {
      const aborted = await this.matches.abortAllActive('backend_restart', this.clock.now());
      if (aborted > 0) this.logger.warn(`${aborted} partida(s) ativa(s) abortada(s) no boot`);
    } catch (error) {
      this.logger.error(`Partidas antigas não abortadas: ${errorMessage(error)}`);
    }
    try {
      await this.runtime.removeAllManaged();
      await this.mutex.run(() => this.replenish());
    } catch (error) {
      this.logger.error(`Pool não aquecido (Docker disponível?): ${errorMessage(error)}`);
    }
  }

  /** Aguarda a reposição do pool em segundo plano (testes e shutdown). */
  settle(): Promise<void> {
    return this.background;
  }

  /**
   * Reserva um game server e grava `matches(assigned)`. `null` = sem capacidade agora (pool no
   * limite ou Docker indisponível): quem chamou deixa os tickets na fila e tenta de novo.
   */
  assign(playerIds: string[]): Promise<AssignedMatch | null> {
    return this.mutex.run(async () => {
      const slot = this.takeIdle() ?? (await this.startSlot());
      if (!slot) return null;

      const matchId = randomUUID();
      const host = this.config.GAMESERVER_PUBLIC_HOST;
      try {
        const issued = await Promise.all(
          playerIds.map(async (userId) => ({ userId, token: await this.tokens.sign(matchId, playerIds, userId) })),
        );
        await this.matches.createAssigned({
          id: matchId,
          players: issued.map(({ userId, token }) => ({ userId, tokenHash: MatchTokenService.hash(token) })),
          serverHost: host,
          serverPort: slot.port,
          seed: randomInt(SEED_BOUND),
          now: this.clock.now(),
        });
        slot.matchId = matchId;
        const assignments = new Map(
          issued.map(({ userId, token }) => [userId, { host, port: slot.port, token }] as const),
        );
        this.assignments.set(matchId, assignments);
        this.replenishInBackground();
        return { matchId, assignments: Object.fromEntries(assignments) };
      } catch (error) {
        await this.discard(slot);
        this.replenishInBackground();
        throw error;
      }
    });
  }

  /**
   * Os tokens só existem em memória (o banco guarda o hash) e ficam até a partida terminar: o segundo
   * jogador pode consultar o ticket depois que o primeiro já conectou. O JWT expira por conta própria.
   */
  assignmentFor(matchId: string, userId: string): MatchAssignment | undefined {
    return this.assignments.get(matchId)?.get(userId);
  }

  /** Fim da partida (`finished` ou `aborted`): descarta o container e repõe o pool se faltar. */
  async release(matchId: string): Promise<void> {
    await this.mutex.run(async () => {
      this.assignments.delete(matchId);
      const slot = [...this.slots.values()].find((s) => s.matchId === matchId);
      if (slot) await this.discard(slot);
    });
    this.replenishInBackground();
  }

  private takeIdle(): Slot | undefined {
    return [...this.slots.values()]
      .filter((slot) => slot.matchId === undefined)
      .sort((a, b) => a.port - b.port)[0];
  }

  private idleCount(): number {
    return [...this.slots.values()].filter((slot) => slot.matchId === undefined).length;
  }

  private capacity(): number {
    const portCount = this.config.GAME_PORT_MAX - this.config.GAME_PORT_MIN + 1;
    return Math.min(this.config.POOL_MAX, portCount);
  }

  /** Portas livres em ordem; uma porta que falha (ocupada por container que não saiu) não trava as outras. */
  private freePorts(): number[] {
    const ports: number[] = [];
    for (let port = this.config.GAME_PORT_MIN; port <= this.config.GAME_PORT_MAX; port++) {
      if (!this.slots.has(port)) ports.push(port);
    }
    return ports;
  }

  private async startSlot(): Promise<Slot | undefined> {
    if (this.slots.size >= this.capacity()) return undefined;
    for (const port of this.freePorts().slice(0, MAX_PORT_ATTEMPTS)) {
      try {
        const slot: Slot = { port, containerId: await this.runtime.start(port) };
        this.slots.set(port, slot);
        return slot;
      } catch (error) {
        this.logger.error(`Falha ao subir game server na porta ${port}: ${errorMessage(error)}`);
      }
    }
    return undefined;
  }

  private async discard(slot: Slot): Promise<void> {
    this.slots.delete(slot.port);
    try {
      await this.runtime.remove(slot.containerId);
    } catch (error) {
      this.logger.error(`Falha ao remover o container ${slot.containerId}: ${errorMessage(error)}`);
    }
  }

  /** Chamar com o mutex tomado. */
  private async replenish(): Promise<void> {
    while (this.idleCount() < this.config.POOL_SIZE && this.slots.size < this.capacity()) {
      if (!(await this.startSlot())) return;
    }
  }

  private replenishInBackground(): void {
    this.background = this.background
      .then(() => this.mutex.run(() => this.replenish()))
      .catch((error: unknown) => this.logger.error(`Reposição do pool falhou: ${errorMessage(error)}`));
  }
}
