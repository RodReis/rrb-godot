import { timingSafeEqual } from 'node:crypto';
import { CanActivate, ExecutionContext, Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import type { Request } from 'express';
import { APP_CONFIG } from './app-config';
import type { AppConfig } from '../config';

export const INTERNAL_SECRET_HEADER = 'x-internal-secret';

/** `/internal/*`: só o game server, que recebe o segredo por variável de ambiente (§4.4). */
@Injectable()
export class InternalGuard implements CanActivate {
  private readonly secret: Buffer;

  constructor(@Inject(APP_CONFIG) config: AppConfig) {
    this.secret = Buffer.from(config.INTERNAL_SECRET);
  }

  canActivate(context: ExecutionContext): boolean {
    const header = context.switchToHttp().getRequest<Request>().headers[INTERNAL_SECRET_HEADER];
    const given = Buffer.from(typeof header === 'string' ? header : '');
    // timingSafeEqual exige o mesmo tamanho; o tamanho do segredo não é segredo.
    if (given.length !== this.secret.length || !timingSafeEqual(given, this.secret)) {
      throw new UnauthorizedException({
        code: 'INTERNAL_UNAUTHORIZED',
        message: 'Segredo interno inválido',
      });
    }
    return true;
  }
}
