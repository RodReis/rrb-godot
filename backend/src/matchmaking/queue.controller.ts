import { Controller, Delete, Get, HttpCode, HttpStatus, Param, Post, Req, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiConflictResponse,
  ApiCreatedResponse,
  ApiNoContentResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiResponse,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { SkipThrottle, ThrottlerGuard } from '@nestjs/throttler';
import { ParseUuidPipe } from '../common/parse-uuid.pipe';
import type { AuthenticatedRequest } from '../common/jwt.guard';
import { JwtGuard } from '../common/jwt.guard';
import { ClientVersionGuard } from '../common/client-version.guard';
import { QueueTicketBody, QueueTicketDto, TicketStatusDto } from './queue.dto';
import { QueueService, TicketView } from './queue.service';

const TICKET_NOT_FOUND = 'TICKET_NOT_FOUND';

/**
 * Rate limit só em `POST`/`DELETE`: o `GET` é o polling de 2 s do Launcher e não pode ser barrado.
 * O limiter `auth` é de `/auth/*`.
 */
@ApiTags('queue')
@ApiBearerAuth()
@ApiUnauthorizedResponse({ description: 'UNAUTHORIZED' })
@ApiTooManyRequestsResponse({ description: 'RATE_LIMITED' })
@SkipThrottle({ auth: true })
@UseGuards(ThrottlerGuard, JwtGuard)
@Controller('queue')
export class QueueController {
  constructor(private readonly queue: QueueService) {}

  @Post()
  @UseGuards(ClientVersionGuard)
  @ApiCreatedResponse({ type: QueueTicketDto })
  @ApiResponse({ status: 426, description: 'CLIENT_OUTDATED (X-Client-Version < MIN_CLIENT_VERSION)' })
  @ApiConflictResponse({ description: 'ALREADY_QUEUED (ticket ativo ou partida em andamento)' })
  async join(@Req() req: AuthenticatedRequest): Promise<QueueTicketBody> {
    const ticket = await this.queue.join(req.userId);
    return { id: ticket.id, status: 'searching', createdAt: ticket.createdAt.toISOString() };
  }

  @Get(':ticket')
  @SkipThrottle({ queue: true })
  @ApiOkResponse({ type: TicketStatusDto })
  @ApiNotFoundResponse({ description: TICKET_NOT_FOUND })
  status(
    @Req() req: AuthenticatedRequest,
    @Param('ticket', new ParseUuidPipe(TICKET_NOT_FOUND)) ticket: string,
  ): Promise<TicketView> {
    return this.queue.status(req.userId, ticket);
  }

  @Delete(':ticket')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiNoContentResponse()
  @ApiNotFoundResponse({ description: TICKET_NOT_FOUND })
  @ApiConflictResponse({ description: 'ALREADY_MATCHED' })
  cancel(
    @Req() req: AuthenticatedRequest,
    @Param('ticket', new ParseUuidPipe(TICKET_NOT_FOUND)) ticket: string,
  ): Promise<void> {
    return this.queue.cancel(req.userId, ticket);
  }
}
