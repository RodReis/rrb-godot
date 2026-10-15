import { ConflictException, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService, JwtSignOptions } from '@nestjs/jwt';
import * as argon2 from 'argon2';
import { UsersRepository } from '../users/users.repository';
import type { AuthTokens } from './auth.dto';

export const ACCESS_TOKEN_TTL = '15m';
export const REFRESH_TOKEN_TTL = '7d';

export type TokenType = 'access' | 'refresh';
export interface TokenPayload {
  sub: string;
  typ: TokenType;
}

@Injectable()
export class AuthService {
  /** Hash descartável: login com e-mail desconhecido gasta o mesmo tempo que senha errada. */
  private dummyHash?: Promise<string>;

  constructor(
    private readonly users: UsersRepository,
    private readonly jwt: JwtService,
  ) {}

  async register(email: string, password: string): Promise<AuthTokens> {
    const passwordHash = await argon2.hash(password, { type: argon2.argon2id });
    const user = await this.users.create(email, passwordHash);
    if (!user) {
      throw new ConflictException({ code: 'EMAIL_TAKEN', message: 'E-mail já cadastrado' });
    }
    return this.issueTokens(user.id);
  }

  async login(email: string, password: string): Promise<AuthTokens> {
    const user = await this.users.findByEmail(email);
    this.dummyHash ??= argon2.hash('dummy-password-1', { type: argon2.argon2id });
    const valid = await argon2.verify(user?.passwordHash ?? (await this.dummyHash), password);
    if (!user || !valid) {
      throw new UnauthorizedException({
        code: 'INVALID_CREDENTIALS',
        message: 'E-mail ou senha inválidos',
      });
    }
    return this.issueTokens(user.id);
  }

  async refresh(refreshToken: string): Promise<AuthTokens> {
    const payload = await this.jwt.verifyAsync<TokenPayload>(refreshToken).catch(() => null);
    const user = payload?.typ === 'refresh' ? await this.users.findById(payload.sub) : null;
    if (!user) {
      throw new UnauthorizedException({
        code: 'INVALID_REFRESH_TOKEN',
        message: 'Sessão expirada',
      });
    }
    return this.issueTokens(user.id);
  }

  private async issueTokens(userId: string): Promise<AuthTokens> {
    const [accessToken, refreshToken] = await Promise.all([
      this.sign(userId, 'access', ACCESS_TOKEN_TTL),
      this.sign(userId, 'refresh', REFRESH_TOKEN_TTL),
    ]);
    return { accessToken, refreshToken };
  }

  private sign(sub: string, typ: TokenType, expiresIn: JwtSignOptions['expiresIn']): Promise<string> {
    const payload: TokenPayload = { sub, typ };
    return this.jwt.signAsync(payload, { expiresIn });
  }
}
