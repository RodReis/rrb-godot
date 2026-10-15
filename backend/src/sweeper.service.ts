import { Inject, Injectable, Logger, OnApplicationBootstrap, OnApplicationShutdown } from '@nestjs/common';
import { APP_CONFIG } from './common/app-config';
import { errorMessage } from './common/error-message';
import type { AppConfig } from './config';
import { MatchesService } from './matches/matches.service';
import { QueueService } from './matchmaking/queue.service';

/**
 * Relógio do backend: aborta partida com token vencido ou sem heartbeat e pareia a fila.
 * `SWEEP_INTERVAL_MS=0` desliga o timer (os testes chamam `tick()`).
 */
@Injectable()
export class SweeperService implements OnApplicationBootstrap, OnApplicationShutdown {
  private readonly logger = new Logger(SweeperService.name);
  private timer?: NodeJS.Timeout;
  private running = false;

  constructor(
    private readonly matches: MatchesService,
    private readonly queue: QueueService,
    @Inject(APP_CONFIG) private readonly config: AppConfig,
  ) {}

  onApplicationBootstrap(): void {
    if (this.config.SWEEP_INTERVAL_MS > 0) {
      this.timer = setInterval(() => void this.tick(), this.config.SWEEP_INTERVAL_MS);
    }
  }

  onApplicationShutdown(): void {
    clearInterval(this.timer);
  }

  /** Sem reentrada (daemon lento não empilha ticks) e uma varredura falhar não impede a outra. */
  async tick(): Promise<void> {
    if (this.running) return;
    this.running = true;
    try {
      for (const sweep of [() => this.matches.sweep(), () => this.queue.sweep()]) {
        try {
          await sweep();
        } catch (error) {
          this.logger.error(`Varredura falhou: ${errorMessage(error)}`);
        }
      }
    } finally {
      this.running = false;
    }
  }
}
