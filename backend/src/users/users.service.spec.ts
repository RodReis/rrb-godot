import { InMemoryUsersRepository } from '../../test/support/fakes';
import { UsersService } from './users.service';

function errorCode(promise: Promise<unknown>): Promise<unknown> {
  return promise.then(
    () => undefined,
    (error: { getResponse(): { code: string } }) => error.getResponse().code,
  );
}

describe('UsersService', () => {
  let repo: InMemoryUsersRepository;
  let service: UsersService;

  beforeEach(async () => {
    repo = new InMemoryUsersRepository();
    await repo.create('a@b.com', 'hash');
    await repo.create('c@d.com', 'hash');
    service = new UsersService(repo);
  });

  it('conta nova não tem nickname (a sessão informa que falta)', async () => {
    expect(await service.profile('u1')).toEqual({
      id: 'u1',
      email: 'a@b.com',
      nickname: null,
      queueUnlockReason: null,
      createdAt: '2026-01-01T12:00:00.000Z',
    });
  });

  it('define o nickname e passa a devolvê-lo no perfil, na grafia escolhida', async () => {
    const profile = await service.setNickname('u1', 'RodReis');

    expect(profile.nickname).toBe('RodReis');
    expect((await service.profile('u1')).nickname).toBe('RodReis');
  });

  it('nickname em uso por outra conta → NICKNAME_TAKEN, sem diferenciar maiúsculas', async () => {
    await service.setNickname('u1', 'RodReis');

    expect(await errorCode(service.setNickname('u2', 'rodreis'))).toBe('NICKNAME_TAKEN');
    expect(await errorCode(service.setNickname('u2', 'RODREIS'))).toBe('NICKNAME_TAKEN');
    expect((await service.profile('u2')).nickname).toBeNull();
  });

  it('conta que já definiu o nickname não o troca → NICKNAME_ALREADY_SET', async () => {
    await service.setNickname('u1', 'RodReis');

    expect(await errorCode(service.setNickname('u1', 'Outro'))).toBe('NICKNAME_ALREADY_SET');
    expect((await service.profile('u1')).nickname).toBe('RodReis');
  });

  it('corrida: o banco recusa por já definido entre a leitura e a gravação → NICKNAME_ALREADY_SET', async () => {
    jest.spyOn(repo, 'setNickname').mockResolvedValueOnce({ status: 'already_set' });

    expect(await errorCode(service.setNickname('u1', 'RodReis'))).toBe('NICKNAME_ALREADY_SET');
  });

  it('conta inexistente → USER_NOT_FOUND', async () => {
    expect(await errorCode(service.profile('nao-existe'))).toBe('USER_NOT_FOUND');
    expect(await errorCode(service.setNickname('nao-existe', 'RodReis'))).toBe('USER_NOT_FOUND');
  });

  describe('liberação da fila (SPEC-085)', () => {
    it.each(['tutorial', 'bot_win'] as const)('registra %s e o perfil passa a expor o motivo', async (reason) => {
      expect((await service.unlockQueue('u1', reason)).queueUnlockReason).toBe(reason);
      expect((await service.profile('u1')).queueUnlockReason).toBe(reason);
      expect((await service.profile('u2')).queueUnlockReason).toBeNull();
    });

    it('idempotente: conta já liberada mantém o motivo original e não dá erro', async () => {
      await service.unlockQueue('u1', 'tutorial');
      const again = await service.unlockQueue('u1', 'bot_win');
      expect(again.queueUnlockReason).toBe('tutorial');
      expect(repo.rows[0]?.queueUnlockReason).toBe('tutorial');
    });

    it('conta liberada pela migração (history) não é sobrescrita', async () => {
      repo.rows[0]!.queueUnlockReason = 'history';
      expect((await service.unlockQueue('u1', 'tutorial')).queueUnlockReason).toBe('history');
    });

    it('conta inexistente → USER_NOT_FOUND', async () => {
      expect(await errorCode(service.unlockQueue('nao-existe', 'tutorial'))).toBe('USER_NOT_FOUND');
    });
  });
});
