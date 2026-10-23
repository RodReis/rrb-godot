import { ExecutionContext } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InMemoryUsersRepository } from '../../test/support/fakes';
import { JwtGuard } from '../common/jwt.guard';
import { AdminGuard } from './admin.guard';

const SECRET = 'segredo-de-teste-com-32-caracteres!!';

function context(authorization?: string): ExecutionContext {
  const req = { headers: authorization ? { authorization } : {} };
  return { switchToHttp: () => ({ getRequest: () => req }) } as unknown as ExecutionContext;
}

async function status(promise: Promise<unknown>): Promise<unknown> {
  return promise.then(
    () => 200,
    (error: { getStatus(): number; getResponse(): { code: string } }) => [error.getStatus(), error.getResponse().code],
  );
}

describe('AdminGuard (SPEC-029)', () => {
  const jwt = new JwtService({ secret: SECRET });
  let users: InMemoryUsersRepository;
  let guard: AdminGuard;
  let adminId: string;
  let playerId: string;

  const bearer = async (sub: string, typ = 'access'): Promise<string> => `Bearer ${await jwt.signAsync({ sub, typ })}`;

  beforeEach(async () => {
    users = new InMemoryUsersRepository();
    adminId = (await users.create('admin@rrb.dev', 'h'))?.id ?? '';
    playerId = (await users.create('jogador@rrb.dev', 'h'))?.id ?? '';
    await users.promoteToAdmin(['admin@rrb.dev']);
    guard = new AdminGuard(new JwtGuard(jwt), users);
  });

  it('sem JWT → 401', async () => {
    expect(await status(guard.canActivate(context()))).toEqual([401, 'UNAUTHORIZED']);
  });

  it('JWT inválido ou refresh token → 401', async () => {
    expect(await status(guard.canActivate(context('Bearer lixo')))).toEqual([401, 'UNAUTHORIZED']);
    expect(await status(guard.canActivate(context(await bearer(adminId, 'refresh'))))).toEqual([401, 'UNAUTHORIZED']);
  });

  it('conta player → 403 ADMIN_REQUIRED', async () => {
    expect(await status(guard.canActivate(context(await bearer(playerId))))).toEqual([403, 'ADMIN_REQUIRED']);
  });

  it('conta que não existe mais → 403 (o JWT sozinho não basta)', async () => {
    expect(await status(guard.canActivate(context(await bearer('fantasma'))))).toEqual([403, 'ADMIN_REQUIRED']);
  });

  it('admin → passa', async () => {
    expect(await guard.canActivate(context(await bearer(adminId)))).toBe(true);
  });

  it('o papel vem do banco a cada chamada: rebaixar vale com o mesmo token', async () => {
    const token = await bearer(adminId);
    expect(await guard.canActivate(context(token))).toBe(true);

    const row = users.rows.find((u) => u.id === adminId);
    if (row) row.role = 'player';

    expect(await status(guard.canActivate(context(token)))).toEqual([403, 'ADMIN_REQUIRED']);
  });
});
