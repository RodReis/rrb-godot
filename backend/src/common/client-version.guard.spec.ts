import { ExecutionContext, HttpException } from '@nestjs/common';
import type { AppConfig } from '../config';
import { CLIENT_VERSION_HEADER, ClientVersionGuard, UPGRADE_REQUIRED } from './client-version.guard';
import { isClientVersionAtLeast } from './client-version';

function contextWith(headers: Record<string, string>): ExecutionContext {
  return {
    switchToHttp: () => ({ getRequest: () => ({ headers }) }),
  } as unknown as ExecutionContext;
}

describe('isClientVersionAtLeast', () => {
  it.each([
    ['v0.2.0', 'v0.2.0', true],
    ['v0.10.0', 'v0.9.9', true],
    ['v1.0.0', 'v0.99.99', true],
    ['0.2.1', 'v0.2.0', true],
    ['v0.1.9', 'v0.2.0', false],
    ['dev', 'v0.2.0', false],
    [undefined, 'v0.2.0', false],
  ])('%s >= %s: %s', (given, minimum, ok) => {
    expect(isClientVersionAtLeast(given, minimum)).toBe(ok);
  });
});

describe('ClientVersionGuard', () => {
  const guard = (minimum?: string): ClientVersionGuard =>
    new ClientVersionGuard({ MIN_CLIENT_VERSION: minimum } as AppConfig);

  it('sem MIN_CLIENT_VERSION aceita qualquer cliente, até sem cabeçalho', () => {
    expect(guard(undefined).canActivate(contextWith({}))).toBe(true);
  });

  it('aceita a versão mínima', () => {
    expect(guard('v0.2.0').canActivate(contextWith({ [CLIENT_VERSION_HEADER]: 'v0.2.0' }))).toBe(true);
  });

  it.each([
    ['antiga', { [CLIENT_VERSION_HEADER]: 'v0.1.0' }],
    ['ausente (ZIP v0.1.0)', {}],
  ])('recusa versão %s com 426 CLIENT_OUTDATED', (_caso, headers) => {
    expect.assertions(2);
    try {
      guard('v0.2.0').canActivate(contextWith(headers));
    } catch (error) {
      expect((error as HttpException).getStatus()).toBe(UPGRADE_REQUIRED);
      expect((error as HttpException).getResponse()).toMatchObject({ code: 'CLIENT_OUTDATED' });
    }
  });
});
