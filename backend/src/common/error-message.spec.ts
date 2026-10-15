import { DrizzleQueryError } from 'drizzle-orm/errors';
import { errorMessage } from './error-message';

describe('errorMessage', () => {
  it('erro comum: a mensagem', () => {
    expect(errorMessage(new Error('docker caiu'))).toBe('docker caiu');
  });

  it('DrizzleQueryError: sem o SQL nem os params (token_hash, ids)', () => {
    const error = new DrizzleQueryError('insert into matches ... token_hash', ['hash-secreto'], new Error('conexão recusada'));

    const text = errorMessage(error);

    expect(text).toContain('conexão recusada');
    expect(text).not.toContain('hash-secreto');
    expect(text).not.toContain('insert into');
  });

  it('valor que não é Error vira texto', () => {
    expect(errorMessage('quebrou')).toBe('quebrou');
  });
});
