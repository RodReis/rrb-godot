import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import type { Request } from 'express';
import type { TokenPayload } from '../auth/auth.service';

export interface AuthenticatedRequest extends Request {
  userId: string;
}

/** Exige `Authorization: Bearer <access token>`; refresh token não abre rota. */
@Injectable()
export class JwtGuard implements CanActivate {
  constructor(private readonly jwt: JwtService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const [scheme, token] = req.headers.authorization?.split(' ') ?? [];
    const payload =
      scheme === 'Bearer' && token
        ? await this.jwt.verifyAsync<TokenPayload>(token).catch(() => null)
        : null;
    if (payload?.typ !== 'access') {
      throw new UnauthorizedException({ code: 'UNAUTHORIZED', message: 'Login necessário' });
    }
    req.userId = payload.sub;
    return true;
  }
}
