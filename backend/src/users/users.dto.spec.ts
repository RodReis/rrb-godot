import { QueueUnlockSchema, SetNicknameSchema } from './users.dto';

function firstMessage(nickname: unknown): string | undefined {
  const result = SetNicknameSchema.safeParse({ nickname });
  return result.success ? undefined : result.error.issues[0]?.message;
}

describe('SetNicknameSchema', () => {
  it.each(['abc', 'Rod_Reis', 'a1b2c3d4e5f6g7h8', '___', '123'])('aceita %s', (nickname) => {
    expect(firstMessage(nickname)).toBeUndefined();
  });

  it.each([
    ['curto (2)', 'ab'],
    ['longo (17)', 'a'.repeat(17)],
    ['vazio', ''],
    ['com espaço', 'rod reis'],
    ['com hífen', 'rod-reis'],
    ['acentuado', 'ródrigo'],
    ['com # (o prefixo é só de exibição)', '#RodReis'],
    ['com quebra de linha no fim', 'RodReis\n'],
    ['unicode fora de A–Z', 'ｒｏｄｒｅｉｓ'],
  ])('rejeita nickname %s com INVALID_NICKNAME', (_caso, nickname) => {
    expect(firstMessage(nickname)).toBe('INVALID_NICKNAME');
  });

  it('corpo sem campo ou com tipo errado cai em erro de validação', () => {
    expect(SetNicknameSchema.safeParse({}).success).toBe(false);
    expect(SetNicknameSchema.safeParse({ nickname: 42 }).success).toBe(false);
  });
});

describe('QueueUnlockSchema', () => {
  it.each(['tutorial', 'bot_win'])('aceita %s', (reason) => {
    expect(QueueUnlockSchema.safeParse({ reason }).success).toBe(true);
  });

  it.each([['history'], ['outro'], [''], [42], [null], [undefined]])('rejeita reason %p', (reason) => {
    expect(QueueUnlockSchema.safeParse({ reason }).success).toBe(false);
  });

  it('corpo sem o campo é rejeitado', () => {
    expect(QueueUnlockSchema.safeParse({}).success).toBe(false);
  });
});
