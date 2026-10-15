import { RegisterSchema } from './auth.dto';

function firstMessage(input: unknown): string | undefined {
  const result = RegisterSchema.safeParse(input);
  return result.success ? undefined : result.error.issues[0]?.message;
}

describe('RegisterSchema', () => {
  it('aceita senha com 8+ caracteres, letra e número', () => {
    expect(firstMessage({ email: 'a@b.com', password: 'abcdefg1' })).toBeUndefined();
  });

  it.each([
    ['curta', 'abc1234'],
    ['sem número', 'abcdefgh'],
    ['sem letra', '12345678'],
  ])('rejeita senha %s com WEAK_PASSWORD', (_caso, password) => {
    expect(firstMessage({ email: 'a@b.com', password })).toBe('WEAK_PASSWORD');
  });

  it('aceita letra acentuada como letra', () => {
    expect(firstMessage({ email: 'a@b.com', password: 'ççççççç1' })).toBeUndefined();
  });

  it('rejeita e-mail inválido com INVALID_EMAIL', () => {
    expect(firstMessage({ email: 'nao-e-email', password: 'abcdefg1' })).toBe('INVALID_EMAIL');
  });

  it('normaliza e-mail (trim + minúsculas)', () => {
    const parsed = RegisterSchema.parse({ email: '  Foo@Bar.COM ', password: 'abcdefg1' });
    expect(parsed.email).toBe('foo@bar.com');
  });
});
