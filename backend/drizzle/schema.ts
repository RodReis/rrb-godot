import { pgTable, text, timestamp, uuid } from 'drizzle-orm/pg-core';

/** ARCHITECTURE-LAUNCHER.md §4.3. `nickname` entra no F35. */
export const users = pgTable('users', {
  id: uuid('id').primaryKey().defaultRandom(),
  email: text('email').notNull().unique(),
  passwordHash: text('password_hash').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export type User = typeof users.$inferSelect;
