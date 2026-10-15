import { sql } from 'drizzle-orm';
import {
  boolean,
  doublePrecision,
  index,
  integer,
  pgEnum,
  pgTable,
  primaryKey,
  serial,
  text,
  timestamp,
  uniqueIndex,
  uuid,
} from 'drizzle-orm/pg-core';

/** ARCHITECTURE-LAUNCHER.md §4.3. `nickname` entra no F35. */
export const users = pgTable('users', {
  id: uuid('id').primaryKey().defaultRandom(),
  email: text('email').notNull().unique(),
  passwordHash: text('password_hash').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export type User = typeof users.$inferSelect;

export const matchStatus = pgEnum('match_status', ['assigned', 'running', 'finished', 'aborted']);
export type MatchStatus = (typeof matchStatus.enumValues)[number];

export const ticketStatus = pgEnum('ticket_status', ['waiting', 'matched', 'cancelled', 'expired']);
export type TicketStatus = (typeof ticketStatus.enumValues)[number];

/** Partida: `assigned` (token emitido) → `running` (validate) → `finished` (result) | `aborted`. */
export const matches = pgTable('matches', {
  id: uuid('id').primaryKey().defaultRandom(),
  status: matchStatus('status').notNull().default('assigned'),
  serverHost: text('server_host').notNull(),
  serverPort: integer('server_port').notNull(),
  tokenHash: text('token_hash').notNull(),
  seed: integer('seed').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  startedAt: timestamp('started_at', { withTimezone: true }),
  /** Último heartbeat do game server (§4.2); o `validate` conta como o primeiro. */
  lastHeartbeatAt: timestamp('last_heartbeat_at', { withTimezone: true }),
  endedAt: timestamp('ended_at', { withTimezone: true }),
  winnerUserId: uuid('winner_user_id').references(() => users.id),
  endReason: text('end_reason'),
  durationS: integer('duration_s'),
});

export type Match = typeof matches.$inferSelect;

/**
 * Participantes da partida. As linhas nascem na atribuição (para saber quem pode
 * abandonar e quem o resultado pode citar) e as estatísticas entram no `result`.
 */
export const matchPlayers = pgTable(
  'match_players',
  {
    matchId: uuid('match_id')
      .notNull()
      .references(() => matches.id),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id),
    heroId: text('hero_id'),
    kills: integer('kills').notNull().default(0),
    deaths: integer('deaths').notNull().default(0),
    finalLevel: integer('final_level').notNull().default(0),
    damageDealt: doublePrecision('damage_dealt').notNull().default(0),
    damageTaken: doublePrecision('damage_taken').notNull().default(0),
    monstersKilled: integer('monsters_killed').notNull().default(0),
    chestsOpened: integer('chests_opened').notNull().default(0),
    bossKill: boolean('boss_kill').notNull().default(false),
    setActive: text('set_active'),
    levelAtPhase1End: integer('level_at_phase1_end'),
    avgPingMs: integer('avg_ping_ms'),
  },
  (table) => [primaryKey({ columns: [table.matchId, table.userId] }), index('match_players_user_idx').on(table.userId)],
);

export type MatchPlayer = typeof matchPlayers.$inferSelect;

/** `seq` dá a ordem FIFO sem depender da resolução do relógio. */
export const queueTickets = pgTable(
  'queue_tickets',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    seq: serial('seq').notNull(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id),
    status: ticketStatus('status').notNull().default('waiting'),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    /** Última consulta do Launcher (polling); ticket sem consulta há tempo demais expira. */
    lastSeenAt: timestamp('last_seen_at', { withTimezone: true }).notNull().defaultNow(),
    matchId: uuid('match_id').references(() => matches.id),
  },
  (table) => [
    // I8 (CONVENTION §5): um ticket ativo por conta; a corrida entre dois POST cai aqui.
    uniqueIndex('queue_tickets_one_waiting_per_user')
      .on(table.userId)
      .where(sql`${table.status} = 'waiting'`),
    index('queue_tickets_waiting_idx').on(table.seq).where(sql`${table.status} = 'waiting'`),
  ],
);

export type QueueTicket = typeof queueTickets.$inferSelect;
