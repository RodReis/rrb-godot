import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import type { User } from '../../drizzle/schema';
import { UsersRepository } from '../users/users.repository';
import { AuthService } from './auth.service';

class FakeUsersRepository extends UsersRepository {
  readonly rows: User[] = [];

  async create(email: string, passwordHash: string): Promise<User | null> {
    if (this.rows.some((u) => u.email === email)) return null;
    const user: User = { id: `u${this.rows.length + 1}`, email, passwordHash, createdAt: new Date() };
    this.rows.push(user);
    return user;
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.rows.find((u) => u.email === email) ?? null;
  }

  async findById(id: string): Promise<User | null> {
    return this.rows.find((u) => u.id === id) ?? null;
  }
}

const SECRET = 'segredo-de-teste-com-32-caracteres!!';

function errorCode(error: unknown): unknown {
  return (error as { getResponse(): { code: string } }).getResponse().code;
}

describe('AuthService', () => {
  let users: FakeUsersRepository;
  let jwt: JwtService;
  let service: AuthService;

  beforeEach(() => {
    users = new FakeUsersRepository();
    jwt = new JwtService({ secret: SECRET });
    service = new AuthService(users, jwt);
  });

  it('register guarda hash argon2id (nunca a senha) e devolve tokens', async () => {
    const tokens = await service.register('a@b.com', 'abcdefg1');

    expect(users.rows[0]?.passwordHash).toMatch(/^\$argon2id\$/);
    expect(users.rows[0]?.passwordHash).not.toContain('abcdefg1');
    const access = await jwt.verifyAsync<{ sub: string; typ: string }>(tokens.accessToken);
    expect(access).toMatchObject({ sub: 'u1', typ: 'access' });
    const refresh = await jwt.verifyAsync<{ sub: string; typ: string }>(tokens.refreshToken);
    expect(refresh).toMatchObject({ sub: 'u1', typ: 'refresh' });
  });

  it('access expira em 15 min e refresh em 7 d', async () => {
    const tokens = await service.register('a@b.com', 'abcdefg1');
    const access = jwt.decode<{ iat: number; exp: number }>(tokens.accessToken);
    const refresh = jwt.decode<{ iat: number; exp: number }>(tokens.refreshToken);
    expect(access.exp - access.iat).toBe(15 * 60);
    expect(refresh.exp - refresh.iat).toBe(7 * 24 * 60 * 60);
  });

  it('register com e-mail duplicado lança 409 EMAIL_TAKEN', async () => {
    await service.register('a@b.com', 'abcdefg1');
    const error = await service.register('a@b.com', 'outra123').catch((e: unknown) => e);
    expect(error).toBeInstanceOf(ConflictException);
    expect(errorCode(error)).toBe('EMAIL_TAKEN');
  });

  it('login com senha certa devolve tokens do usuário', async () => {
    await service.register('a@b.com', 'abcdefg1');
    const tokens = await service.login('a@b.com', 'abcdefg1');
    expect(jwt.decode<{ sub: string }>(tokens.accessToken).sub).toBe('u1');
  });

  it.each([
    ['senha errada', 'a@b.com', 'errada123'],
    ['e-mail desconhecido', 'x@y.com', 'abcdefg1'],
  ])('login com %s lança 401 INVALID_CREDENTIALS', async (_caso, email, password) => {
    await service.register('a@b.com', 'abcdefg1');
    const error = await service.login(email, password).catch((e: unknown) => e);
    expect(error).toBeInstanceOf(UnauthorizedException);
    expect(errorCode(error)).toBe('INVALID_CREDENTIALS');
  });

  it('refresh troca refresh token válido por novo par', async () => {
    const tokens = await service.register('a@b.com', 'abcdefg1');
    const renewed = await service.refresh(tokens.refreshToken);
    expect(jwt.decode<{ sub: string; typ: string }>(renewed.accessToken)).toMatchObject({
      sub: 'u1',
      typ: 'access',
    });
  });

  it('refresh rejeita access token, token inválido e usuário inexistente', async () => {
    const tokens = await service.register('a@b.com', 'abcdefg1');
    const orphan = await jwt.signAsync({ sub: 'sumiu', typ: 'refresh' });

    for (const token of [tokens.accessToken, 'lixo', orphan]) {
      const error = await service.refresh(token).catch((e: unknown) => e);
      expect(error).toBeInstanceOf(UnauthorizedException);
      expect(errorCode(error)).toBe('INVALID_REFRESH_TOKEN');
    }
  });
});
