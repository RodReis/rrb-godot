import { DrizzleQueryError } from 'drizzle-orm/errors';
import { safeForLog } from './http-error.filter';

describe('safeForLog', () => {
  it('tira SQL e params (e-mail, hash) de erro do Drizzle', () => {
    const error = new DrizzleQueryError(
      'insert into "users" ("email", "password_hash") values ($1, $2)',
      ['jogador@rrb.dev', '$argon2id$v=19$segredo'],
      new Error('connection terminated'),
    );
    const logged = JSON.stringify(safeForLog(error));
    expect(logged).not.toContain('jogador@rrb.dev');
    expect(logged).not.toContain('argon2id');
    expect(logged).toContain('connection terminated');
  });

  it('mantém outros erros intactos (stack útil)', () => {
    const error = new Error('boom');
    expect(safeForLog(error)).toBe(error);
  });
});
