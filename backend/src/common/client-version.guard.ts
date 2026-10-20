import { CanActivate, ExecutionContext, HttpException, Inject, Injectable } from '@nestjs/common';
import type { Request } from 'express';
import { APP_CONFIG } from './app-config';
import type { AppConfig } from '../config';
import { isClientVersionAtLeast } from './client-version';

export const CLIENT_VERSION_HEADER = 'x-client-version';
/** 426 Upgrade Required (o enum HttpStatus do Nest não tem). */
export const UPGRADE_REQUIRED = 426;

/**
 * Entrar na fila exige o Launcher em `MIN_CLIENT_VERSION` ou mais novo (F83, ADR-0023): cliente velho
 * contra servidor novo dessincroniza a partida. Vazio = aceita todos. Sem cabeçalho (ZIP v0.1.0) = recusa.
 */
@Injectable()
export class ClientVersionGuard implements CanActivate {
  constructor(@Inject(APP_CONFIG) private readonly config: AppConfig) {}

  canActivate(context: ExecutionContext): boolean {
    const minimum = this.config.MIN_CLIENT_VERSION;
    if (!minimum) return true;
    const header = context.switchToHttp().getRequest<Request>().headers[CLIENT_VERSION_HEADER];
    if (isClientVersionAtLeast(typeof header === 'string' ? header : undefined, minimum)) return true;
    throw new HttpException(
      { code: 'CLIENT_OUTDATED', message: `Atualize o jogo para ${minimum} ou mais novo` },
      UPGRADE_REQUIRED,
    );
  }
}
