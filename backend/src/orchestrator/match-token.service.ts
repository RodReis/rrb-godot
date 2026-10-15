import { createHash } from 'node:crypto';
import { Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { APP_CONFIG } from '../common/app-config';
import type { AppConfig } from '../config';

/** Token de partida (§4.2 passo 3). `typ: 'match'` o separa dos tokens de usuário (`JwtGuard` exige `access`). */
export interface MatchTokenPayload {
  typ: 'match';
  match_id: string;
  player_ids: string[];
}

@Injectable()
export class MatchTokenService {
  constructor(
    private readonly jwt: JwtService,
    @Inject(APP_CONFIG) private readonly config: AppConfig,
  ) {}

  sign(matchId: string, playerIds: string[]): Promise<string> {
    const payload: MatchTokenPayload = { typ: 'match', match_id: matchId, player_ids: playerIds };
    return this.jwt.signAsync(payload, { expiresIn: this.config.MATCH_TOKEN_TTL_S });
  }

  /** Assinatura + validade + tipo. Lança 401 `TOKEN_EXPIRED` ou `TOKEN_INVALID`. */
  async verify(token: string): Promise<MatchTokenPayload> {
    try {
      const payload = await this.jwt.verifyAsync<MatchTokenPayload>(token);
      if (payload.typ === 'match') return payload;
    } catch (error) {
      if ((error as { name?: string }).name === 'TokenExpiredError') {
        throw new UnauthorizedException({ code: 'TOKEN_EXPIRED', message: 'Token de partida expirado' });
      }
    }
    throw new UnauthorizedException({ code: 'TOKEN_INVALID', message: 'Token de partida inválido' });
  }

  /** O banco guarda só o hash (§4.3): vazar `matches` não vaza token utilizável. */
  static hash(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }
}
