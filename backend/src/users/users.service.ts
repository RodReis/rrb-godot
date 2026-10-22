import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import type { QueueUnlockReason, User } from '../../drizzle/schema';
import type { UserProfile } from './users.dto';
import { UsersRepository } from './users.repository';

function toProfile(user: User): UserProfile {
  return {
    id: user.id,
    email: user.email,
    nickname: user.nickname,
    queueUnlockReason: user.queueUnlockReason,
    createdAt: user.createdAt.toISOString(),
  };
}

@Injectable()
export class UsersService {
  constructor(private readonly users: UsersRepository) {}

  async profile(userId: string): Promise<UserProfile> {
    return toProfile(await this.find(userId));
  }

  /**
   * 1º login (F35): define o nickname uma única vez. Trocar depois não é requisito da spec; fica
   * `NICKNAME_ALREADY_SET` até o PI decidir o contrário.
   */
  async setNickname(userId: string, nickname: string): Promise<UserProfile> {
    if ((await this.find(userId)).nickname !== null) throw alreadySet();
    const result = await this.users.setNickname(userId, nickname);
    if (result.status === 'taken') {
      throw new ConflictException({ code: 'NICKNAME_TAKEN', message: 'Este nickname já está em uso' });
    }
    if (result.status === 'already_set') throw alreadySet();
    return toProfile(result.user);
  }

  /** SPEC-085: o Launcher registra tutorial/vitória contra bot; já liberada mantém o motivo original. */
  async unlockQueue(userId: string, reason: QueueUnlockReason): Promise<UserProfile> {
    const user = await this.find(userId);
    if (user.queueUnlockReason !== null) return toProfile(user);
    await this.users.unlockQueue(userId, reason);
    return toProfile(await this.find(userId));
  }

  private async find(userId: string): Promise<User> {
    const user = await this.users.findById(userId);
    if (!user) throw new NotFoundException({ code: 'USER_NOT_FOUND', message: 'Conta não encontrada' });
    return user;
  }
}

const alreadySet = (): ConflictException =>
  new ConflictException({ code: 'NICKNAME_ALREADY_SET', message: 'O nickname desta conta já foi definido' });
