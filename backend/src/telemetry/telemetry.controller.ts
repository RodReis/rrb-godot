import { Controller, Get, Header, Query, UseGuards } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiForbiddenResponse,
  ApiOkResponse,
  ApiProduces,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { AdminGuard } from './admin.guard';
import { KpiReport } from './kpis';
import { AdminMatchesCsvQueryDto, AdminMatchesQueryDto, AdminMatchList, AdminMatchListDto, KpiReportDto } from './telemetry.dto';
import { TelemetryService } from './telemetry.service';

/**
 * Painel de playtest (SPEC-029, ADR-0033): só `role = admin`. Sem throttler próprio: o brute force
 * de senha é do `/auth/login`, que já tem limite. Nenhuma resposta traz e-mail, hash, token ou id de conta.
 */
@ApiTags('admin')
@ApiBearerAuth()
@ApiUnauthorizedResponse({ description: 'UNAUTHORIZED' })
@ApiForbiddenResponse({ description: 'ADMIN_REQUIRED' })
@UseGuards(AdminGuard)
@Controller('admin')
export class TelemetryController {
  constructor(private readonly telemetry: TelemetryService) {}

  @Get('kpis')
  @ApiOkResponse({ type: KpiReportDto })
  kpis(): Promise<KpiReport> {
    return this.telemetry.kpis();
  }

  @Get('matches')
  @ApiOkResponse({ type: AdminMatchListDto })
  @ApiBadRequestResponse({ description: 'VALIDATION_FAILED' })
  matches(@Query() { page, ...filter }: AdminMatchesQueryDto): Promise<AdminMatchList> {
    return this.telemetry.matches(filter, page);
  }

  @Get('matches.csv')
  @Header('Content-Type', 'text/csv; charset=utf-8')
  @Header('Content-Disposition', 'attachment; filename="partidas.csv"')
  @ApiProduces('text/csv')
  @ApiOkResponse({ description: 'Mesmo conteúdo de /admin/matches, todas as páginas, uma linha por jogador', type: String })
  @ApiBadRequestResponse({ description: 'VALIDATION_FAILED' })
  matchesCsv(@Query() filter: AdminMatchesCsvQueryDto): Promise<string> {
    return this.telemetry.matchesCsv(filter);
  }
}
