import { Body, Controller, Get, HttpCode, HttpStatus, Param, Post, Query, Req, UseGuards } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiConflictResponse,
  ApiNoContentResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiSecurity,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { SkipThrottle, ThrottlerGuard } from '@nestjs/throttler';
import type { AuthenticatedRequest } from '../common/jwt.guard';
import { JwtGuard } from '../common/jwt.guard';
import { InternalGuard } from '../common/internal.guard';
import { ParseUuidPipe } from '../common/parse-uuid.pipe';
import { MatchHistoryDto, MatchResultDto, MineQueryDto, ValidatedMatchDto, ValidateDto } from './matches.dto';
import { MatchesService, MatchHistory, ValidatedMatch } from './matches.service';

const MATCH_NOT_FOUND = 'MATCH_NOT_FOUND';
const matchId = (): ParseUuidPipe => new ParseUuidPipe(MATCH_NOT_FOUND);

/** Só o game server (segredo compartilhado, §4.4). Nunca chamados pelo Launcher. */
@ApiTags('internal')
@ApiSecurity('internal-secret')
@ApiUnauthorizedResponse({ description: 'INTERNAL_UNAUTHORIZED' })
@ApiNotFoundResponse({ description: MATCH_NOT_FOUND })
@UseGuards(InternalGuard)
@Controller('internal/matches')
export class InternalMatchesController {
  constructor(private readonly matches: MatchesService) {}

  @Post(':id/validate')
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ type: ValidatedMatchDto })
  @ApiUnauthorizedResponse({ description: 'INTERNAL_UNAUTHORIZED | TOKEN_INVALID | TOKEN_EXPIRED' })
  @ApiConflictResponse({ description: 'MATCH_NOT_ACTIVE' })
  validate(@Param('id', matchId()) id: string, @Body() body: ValidateDto): Promise<ValidatedMatch> {
    return this.matches.validate(id, body.token);
  }

  @Post(':id/heartbeat')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiNoContentResponse()
  @ApiConflictResponse({ description: 'MATCH_NOT_RUNNING' })
  heartbeat(@Param('id', matchId()) id: string): Promise<void> {
    return this.matches.heartbeat(id);
  }

  @Post(':id/result')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiNoContentResponse()
  @ApiBadRequestResponse({ description: 'INVALID_RESULT | VALIDATION_FAILED' })
  @ApiConflictResponse({ description: 'MATCH_NOT_RUNNING' })
  result(@Param('id', matchId()) id: string, @Body() body: MatchResultDto): Promise<void> {
    return this.matches.result(id, body);
  }
}

@ApiTags('matches')
@ApiBearerAuth()
@ApiUnauthorizedResponse({ description: 'UNAUTHORIZED' })
@SkipThrottle({ auth: true })
@UseGuards(ThrottlerGuard, JwtGuard)
@Controller('matches')
export class MatchesController {
  constructor(private readonly matches: MatchesService) {}

  /** Histórico da própria conta (§4.2 passo 8): as últimas partidas terminadas e os totais V–D. */
  // Leitura: não divide o balde `queue` (10/min) com entrar na fila e abandonar.
  @Get()
  @SkipThrottle({ queue: true })
  @ApiOkResponse({ type: MatchHistoryDto })
  @ApiBadRequestResponse({ description: 'VALIDATION_FAILED (falta mine=1)' })
  // `query` só existe para o pipe do zod exigir `mine=1`.
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  history(@Req() req: AuthenticatedRequest, @Query() query: MineQueryDto): Promise<MatchHistory> {
    return this.matches.history(req.userId);
  }

  /** Launcher: "instalação incompleta" (§6) — libera o container sem esperar o token vencer. */
  @Post(':id/abandon')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiNoContentResponse()
  @ApiNotFoundResponse({ description: MATCH_NOT_FOUND })
  @ApiConflictResponse({ description: 'MATCH_NOT_ASSIGNED' })
  abandon(@Req() req: AuthenticatedRequest, @Param('id', matchId()) id: string): Promise<void> {
    return this.matches.abandon(id, req.userId);
  }
}
