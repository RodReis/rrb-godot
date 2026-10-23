import { InMemoryUsersRepository } from '../../test/support/fakes';
import type { AppConfig } from '../config';
import { AdminSeedService } from './admin-seed.service';

function seedWith(users: InMemoryUsersRepository, adminEmails: string[]): AdminSeedService {
  return new AdminSeedService(users, { ADMIN_EMAILS: adminEmails } as AppConfig);
}

describe('AdminSeedService (SPEC-029)', () => {
  let users: InMemoryUsersRepository;

  beforeEach(async () => {
    users = new InMemoryUsersRepository();
    await users.create('dono@rrb.dev', 'h');
    await users.create('jogador@rrb.dev', 'h');
  });

  const roleOf = (email: string): string | undefined => users.rows.find((u) => u.email === email)?.role;

  it('contas novas nascem player', () => {
    expect(users.rows.map((u) => u.role)).toEqual(['player', 'player']);
  });

  it('promove só os e-mails listados', async () => {
    const promoted = await seedWith(users, ['dono@rrb.dev']).seed();

    expect(promoted).toBe(1);
    expect(roleOf('dono@rrb.dev')).toBe('admin');
    expect(roleOf('jogador@rrb.dev')).toBe('player');
  });

  it('não diferencia caixa e ignora e-mail sem conta (não cria conta)', async () => {
    await seedWith(users, ['DONO@rrb.dev', 'fantasma@rrb.dev']).seed();

    expect(roleOf('dono@rrb.dev')).toBe('admin');
    expect(users.rows).toHaveLength(2);
  });

  it('nunca rebaixa: e-mail fora da lista continua admin na subida seguinte', async () => {
    await seedWith(users, ['dono@rrb.dev']).seed();
    const promoted = await seedWith(users, []).seed();

    expect(promoted).toBe(0);
    expect(roleOf('dono@rrb.dev')).toBe('admin');
  });

  it('é idempotente: promover quem já é admin não conta', async () => {
    await seedWith(users, ['dono@rrb.dev']).seed();

    expect(await seedWith(users, ['dono@rrb.dev']).seed()).toBe(0);
  });

  it('lista vazia não consulta nem altera nada', async () => {
    expect(await seedWith(users, []).seed()).toBe(0);
    expect(users.rows.every((u) => u.role === 'player')).toBe(true);
  });
});
