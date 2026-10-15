import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { Match } from '../../drizzle/schema';
import { APP_CONFIG } from '../common/app-config';
import { errorMessage } from '../common/error-message';
import { Clock } from '../common/clock';
import type { AppConfig } from '../config';
import { MatchTokenService } from '../orchestrator/match-token.service';
import { OrchestratorService } from '../orchestrator/orchestrator.service';
import { HistoryEntry, MatchesRepository, MatchResult } from './matches.repository';

export interface ValidatedMatch {
  matchId: string;
  userId: string;
  playerIds: string[];
  seed: number;
}

/** Quantas partidas o histórico devolve (as mais recentes); os totais V–D contam todas. */
export const HISTORY_LIMIT = 50;

export type HistoryResult = 'win' | 'loss' | 'interrupted';

/** Uma partida do histórico da própria conta (`GET /matches?mine=1`). */
export interface HistoryMatch {
  matchId: string;
  result: HistoryResult;
  playedAt: string;
  endReason: string | null;
  durationS: number | null;
  me: HistoryEntry['me'];
  opponent: { heroId: string | null; kills: number; finalLevel: number };
}

export interface MatchHistory {
  totals: { wins: number; losses: number };
  matches: HistoryMatch[];
}

/** Abortada ou sem vencedor (`abandoned`: ninguém conectado) = "partida interrompida". */
function resultFor(entry: HistoryEntry, userId: string): HistoryResult {
  if (entry.status !== 'finished' || entry.winnerUserId === null) return 'interrupted';
  return entry.winnerUserId === userId ? 'win' : 'loss';
}

const notFound = (): NotFoundException =>
  new NotFoundException({ code: 'MATCH_NOT_FOUND', message: 'Partida não encontrada' });

/** Ciclo da partida (§4.2 passos 6–7): validate → heartbeat → result, mais abandono e varredura. */
@Injectable()
export class MatchesService {
  private readonly logger = new Logger(MatchesService.name);

  constructor(
    private readonly repo: MatchesRepository,
    private readonly tokens: MatchTokenService,
    private readonly orchestrator: OrchestratorService,
    private readonly clock: Clock,
    @Inject(APP_CONFIG) private readonly config: AppConfig,
  ) {}

  /** Game server confere o token de um peer; cada jogador tem o seu e `userId` diz de quem é. */
  async validate(matchId: string, token: string): Promise<ValidatedMatch> {
    const payload = await this.tokens.verify(token);
    const match = await this.repo.findById(matchId);
    if (!match) throw notFound();
    const issuedHash = await this.repo.playerTokenHash(matchId, payload.sub);
    if (payload.match_id !== matchId || MatchTokenService.hash(token) !== issuedHash) {
      throw new UnauthorizedException({ code: 'TOKEN_INVALID', message: 'Token de partida inválido' });
    }
    // O segundo peer pode chegar junto com o primeiro: se `markRunning` perdeu a corrida, a partida
    // já está `running` e o validate dele também vale. Só terminada/abortada é recusada.
    if (match.status === 'assigned') await this.repo.markRunning(matchId, this.clock.now());
    const current = match.status === 'assigned' ? await this.repo.findById(matchId) : match;
    if (current?.status !== 'running') throw this.notActive();
    return { matchId, userId: payload.sub, playerIds: payload.player_ids, seed: match.seed };
  }

  async heartbeat(matchId: string): Promise<void> {
    if (await this.repo.touchHeartbeat(matchId, this.clock.now())) return;
    throw (await this.repo.findById(matchId)) ? this.notRunning() : notFound();
  }

  async result(matchId: string, result: MatchResult): Promise<void> {
    const match = await this.repo.findById(matchId);
    if (!match) throw notFound();
    await this.assertResultMatchesPlayers(matchId, result);
    if (!(await this.repo.finish(matchId, result, this.clock.now()))) throw this.notRunning();
    await this.orchestrator.release(matchId);
  }

  /** Launcher: histórico da própria conta, com o herói do oponente (§4.2 passo 8, CONVENTION §4.8). */
  async history(userId: string): Promise<MatchHistory> {
    const [entries, totals] = await Promise.all([
      this.repo.historyOf(userId, HISTORY_LIMIT),
      this.repo.recordOf(userId),
    ]);
    return {
      totals,
      matches: entries.map((entry) => ({
        matchId: entry.matchId,
        result: resultFor(entry, userId),
        playedAt: entry.playedAt.toISOString(),
        endReason: entry.endReason,
        durationS: entry.durationS,
        me: entry.me,
        opponent: entry.opponent ?? { heroId: null, kills: 0, finalLevel: 0 },
      })),
    };
  }

  /** Launcher: executável do Game ausente (§6). Só vale antes de a partida começar. */
  async abandon(matchId: string, userId: string): Promise<void> {
    const match = await this.repo.findById(matchId);
    const players = match ? await this.repo.playerIds(matchId) : [];
    if (!match || !players.includes(userId)) throw notFound();
    if (match.status === 'aborted') return;
    if (match.status !== 'assigned' || !(await this.abort(matchId, 'abandoned'))) {
      throw new ConflictException({
        code: 'MATCH_NOT_ASSIGNED',
        message: 'A partida já começou ou terminou',
      });
    }
  }

  /** Aborta e libera o container. `false` = a partida já não estava ativa. */
  async abort(matchId: string, reason: string): Promise<boolean> {
    if (!(await this.repo.abort(matchId, reason, this.clock.now()))) return false;
    await this.orchestrator.release(matchId);
    return true;
  }

  /** Token vencido sem ninguém conectar e game server que parou de dar sinal de vida. */
  async sweep(): Promise<void> {
    const now = this.clock.now().getTime();
    const tokenCutoff = new Date(now - this.config.MATCH_TOKEN_TTL_S * 1000);
    const heartbeatCutoff = new Date(now - this.config.HEARTBEAT_MISS_LIMIT * this.config.HEARTBEAT_INTERVAL_MS);
    await this.abortAll(await this.repo.findAssignedBefore(tokenCutoff), 'token_expired');
    await this.abortAll(await this.repo.findRunningWithHeartbeatBefore(heartbeatCutoff), 'heartbeat_lost');
  }

  private async abortAll(stale: Match[], reason: string): Promise<void> {
    for (const match of stale) {
      try {
        if (await this.abort(match.id, reason)) this.logger.warn(`Partida ${match.id} abortada: ${reason}`);
      } catch (error) {
        this.logger.error(`Falha ao abortar ${match.id}: ${errorMessage(error)}`);
      }
    }
  }

  private async assertResultMatchesPlayers(matchId: string, result: MatchResult): Promise<void> {
    const players = new Set(await this.repo.playerIds(matchId));
    const reported = result.players.map((player) => player.userId);
    const valid =
      new Set(reported).size === reported.length &&
      reported.every((id) => players.has(id)) &&
      (result.winnerUserId === null || players.has(result.winnerUserId));
    if (!valid) {
      throw new BadRequestException({
        code: 'INVALID_RESULT',
        message: 'Resultado cita jogador que não está na partida',
      });
    }
  }

  private notActive(): ConflictException {
    return new ConflictException({ code: 'MATCH_NOT_ACTIVE', message: 'A partida já terminou' });
  }

  private notRunning(): ConflictException {
    return new ConflictException({ code: 'MATCH_NOT_RUNNING', message: 'A partida não está em andamento' });
  }
}
