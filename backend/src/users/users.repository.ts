import { Injectable } from '@nestjs/common';
import { DrizzleQueryError } from 'drizzle-orm/errors';
import { and, eq, isNull } from 'drizzle-orm';
import { User, users } from '../../drizzle/schema';
import { Database } from '../db/database';

/** Resultado de `setNickname`: gravado, em uso por outra conta (sem diferenciar maiúsculas) ou já definido. */
export type SetNicknameResult = { status: 'ok'; user: User } | { status: 'taken' } | { status: 'already_set' };

/** Violação de índice único do Postgres. */
const UNIQUE_VIOLATION = '23505';

/** Contrato usado pelos services; os testes unitários trocam por um repositório em memória. */
export abstract class UsersRepository {
  /** Devolve `null` se o e-mail já existe. */
  abstract create(email: string, passwordHash: string): Promise<User | null>;
  abstract findByEmail(email: string): Promise<User | null>;
  abstract findById(id: string): Promise<User | null>;
  /** Grava o nickname só se a conta ainda não tem um; a unicidade é do índice `lower(nickname)`. */
  abstract setNickname(id: string, nickname: string): Promise<SetNicknameResult>;
}

@Injectable()
export class DrizzleUsersRepository extends UsersRepository {
  constructor(private readonly database: Database) {
    super();
  }

  async create(email: string, passwordHash: string): Promise<User | null> {
    const [user] = await this.database.db
      .insert(users)
      .values({ email, passwordHash })
      .onConflictDoNothing({ target: users.email })
      .returning();
    return user ?? null;
  }

  async findByEmail(email: string): Promise<User | null> {
    const [user] = await this.database.db.select().from(users).where(eq(users.email, email));
    return user ?? null;
  }

  async findById(id: string): Promise<User | null> {
    const [user] = await this.database.db.select().from(users).where(eq(users.id, id));
    return user ?? null;
  }

  async setNickname(id: string, nickname: string): Promise<SetNicknameResult> {
    try {
      const [user] = await this.database.db
        .update(users)
        .set({ nickname })
        .where(and(eq(users.id, id), isNull(users.nickname)))
        .returning();
      return user ? { status: 'ok', user } : { status: 'already_set' };
    } catch (error) {
      // O índice único é o árbitro da corrida entre duas contas pedindo o mesmo nickname.
      const cause = error instanceof DrizzleQueryError ? error.cause : error;
      if ((cause as { code?: string }).code === UNIQUE_VIOLATION) return { status: 'taken' };
      throw error;
    }
  }
}
