import { Injectable } from '@nestjs/common';
import { DrizzleQueryError } from 'drizzle-orm/errors';
import { and, eq, inArray, isNull, ne, sql } from 'drizzle-orm';
import { QueueUnlockReason, User, users } from '../../drizzle/schema';
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
  /** Grava o motivo só se a conta ainda está bloqueada: nunca sobrescreve (idempotente). */
  abstract unlockQueue(id: string, reason: QueueUnlockReason): Promise<void>;
  /** Seed do `ADMIN_EMAILS` (SPEC-029): só promove contas existentes (e-mails em minúsculas), nunca rebaixa. Devolve quantas mudaram. */
  abstract promoteToAdmin(emails: string[]): Promise<number>;
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

  async unlockQueue(id: string, reason: QueueUnlockReason): Promise<void> {
    await this.database.db
      .update(users)
      .set({ queueUnlockReason: reason })
      .where(and(eq(users.id, id), isNull(users.queueUnlockReason)));
  }

  async promoteToAdmin(emails: string[]): Promise<number> {
    if (emails.length === 0) return 0;
    const rows = await this.database.db
      .update(users)
      .set({ role: 'admin' })
      .where(and(inArray(sql`lower(${users.email})`, emails), ne(users.role, 'admin')))
      .returning({ id: users.id });
    return rows.length;
  }
}
