import { Injectable } from '@nestjs/common';
import { eq } from 'drizzle-orm';
import { User, users } from '../../drizzle/schema';
import { Database } from '../db/database';

/** Contrato usado pelos services; os testes unitários trocam por um repositório em memória. */
export abstract class UsersRepository {
  /** Devolve `null` se o e-mail já existe. */
  abstract create(email: string, passwordHash: string): Promise<User | null>;
  abstract findByEmail(email: string): Promise<User | null>;
  abstract findById(id: string): Promise<User | null>;
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
}
