import { Injectable } from '@nestjs/common';
import { and, asc, eq, inArray, lt } from 'drizzle-orm';
import { QueueTicket, queueTickets } from '../../drizzle/schema';
import { Database } from '../db/database';

/** Transições condicionais a `waiting`: `false`/`null` = o ticket já saiu da fila. */
export abstract class QueueRepository {
  /** Devolve `null` se a conta já tem ticket `waiting` (I8). */
  abstract create(userId: string, now: Date): Promise<QueueTicket | null>;
  abstract findById(id: string): Promise<QueueTicket | null>;
  abstract touch(id: string, now: Date): Promise<void>;
  abstract cancel(id: string): Promise<boolean>;
  /** Ordem FIFO (`seq`). */
  abstract listWaiting(limit: number): Promise<QueueTicket[]>;
  /** `true` só se todos os tickets estavam `waiting`. */
  abstract markMatched(ids: string[], matchId: string): Promise<boolean>;
  abstract expireStale(lastSeenBefore: Date): Promise<number>;
}

@Injectable()
export class DrizzleQueueRepository extends QueueRepository {
  constructor(private readonly database: Database) {
    super();
  }

  async create(userId: string, now: Date): Promise<QueueTicket | null> {
    const [ticket] = await this.database.db
      .insert(queueTickets)
      .values({ userId, createdAt: now, lastSeenAt: now })
      .onConflictDoNothing()
      .returning();
    return ticket ?? null;
  }

  async findById(id: string): Promise<QueueTicket | null> {
    const [ticket] = await this.database.db.select().from(queueTickets).where(eq(queueTickets.id, id));
    return ticket ?? null;
  }

  async touch(id: string, now: Date): Promise<void> {
    await this.database.db
      .update(queueTickets)
      .set({ lastSeenAt: now })
      .where(and(eq(queueTickets.id, id), eq(queueTickets.status, 'waiting')));
  }

  async cancel(id: string): Promise<boolean> {
    const rows = await this.database.db
      .update(queueTickets)
      .set({ status: 'cancelled' })
      .where(and(eq(queueTickets.id, id), eq(queueTickets.status, 'waiting')))
      .returning({ id: queueTickets.id });
    return rows.length > 0;
  }

  listWaiting(limit: number): Promise<QueueTicket[]> {
    return this.database.db
      .select()
      .from(queueTickets)
      .where(eq(queueTickets.status, 'waiting'))
      .orderBy(asc(queueTickets.seq))
      .limit(limit);
  }

  // ponytail: um UPDATE só; toda mutação da fila passa pelo mutex do QueueService, então não há
  // corrida em instância única. Com réplicas, vira transação com SELECT ... FOR UPDATE SKIP LOCKED.
  async markMatched(ids: string[], matchId: string): Promise<boolean> {
    const rows = await this.database.db
      .update(queueTickets)
      .set({ status: 'matched', matchId })
      .where(and(inArray(queueTickets.id, ids), eq(queueTickets.status, 'waiting')))
      .returning({ id: queueTickets.id });
    return rows.length === ids.length;
  }

  async expireStale(lastSeenBefore: Date): Promise<number> {
    const rows = await this.database.db
      .update(queueTickets)
      .set({ status: 'expired' })
      .where(and(eq(queueTickets.status, 'waiting'), lt(queueTickets.lastSeenAt, lastSeenBefore)))
      .returning({ id: queueTickets.id });
    return rows.length;
  }
}
