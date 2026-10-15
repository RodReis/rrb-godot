import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import type { AppConfig } from '../config';
import { INTERNAL_SECRET_HEADER, InternalGuard } from './internal.guard';

const SECRET = 'segredo-interno-com-pelo-menos-32-caracteres';

function contextWith(headers: Record<string, string>): ExecutionContext {
  return {
    switchToHttp: () => ({ getRequest: () => ({ headers }) }),
  } as unknown as ExecutionContext;
}

describe('InternalGuard', () => {
  const guard = new InternalGuard({ INTERNAL_SECRET: SECRET } as AppConfig);

  it('aceita o segredo compartilhado', () => {
    expect(guard.canActivate(contextWith({ [INTERNAL_SECRET_HEADER]: SECRET }))).toBe(true);
  });

  it.each([
    ['ausente', {}],
    ['errado', { [INTERNAL_SECRET_HEADER]: 'outro-segredo-com-pelo-menos-32-caracteres' }],
    ['de tamanho diferente', { [INTERNAL_SECRET_HEADER]: 'curto' }],
  ])('recusa segredo %s com 401 INTERNAL_UNAUTHORIZED', (_caso, headers) => {
    expect.assertions(2);
    try {
      guard.canActivate(contextWith(headers));
    } catch (error) {
      expect(error).toBeInstanceOf(UnauthorizedException);
      expect((error as UnauthorizedException).getResponse()).toMatchObject({
        code: 'INTERNAL_UNAUTHORIZED',
      });
    }
  });
});
