import { createZodDto } from 'nestjs-zod';
import { z } from 'zod';

const MAX_TOKEN_LENGTH = 2048;
const MAX_DURATION_S = 24 * 60 * 60;
const MAX_NAME_LENGTH = 64;
const MAX_COUNT = 2_147_483_647; // int4 do Postgres
const count = z.number().int().min(0).max(MAX_COUNT);

export const ValidateSchema = z.object({ token: z.string().min(1).max(MAX_TOKEN_LENGTH) });
export class ValidateDto extends createZodDto(ValidateSchema) {}

/** `userId`: a conta dona do token apresentado (cada jogador tem o seu, §4.2). */
const ValidatedMatchSchema = z.object({
  matchId: z.uuid(),
  userId: z.uuid(),
  playerIds: z.array(z.uuid()),
  seed: z.number().int(),
});
export class ValidatedMatchDto extends createZodDto(ValidatedMatchSchema) {}

const PlayerResultSchema = z.object({
  userId: z.uuid(),
  heroId: z.string().min(1).max(MAX_NAME_LENGTH),
  kills: count,
  deaths: count,
  finalLevel: count,
  damageDealt: z.number().min(0).max(Number.MAX_SAFE_INTEGER),
  damageTaken: z.number().min(0).max(Number.MAX_SAFE_INTEGER),
  monstersKilled: count,
  chestsOpened: count,
  bossKill: z.boolean(),
  setActive: z.string().max(MAX_NAME_LENGTH).nullish(),
  levelAtPhase1End: count.nullish(),
  avgPingMs: count.nullish(),
});

/** Sem `players` ou com a lista vazia = partida encerrada sem estatística (ex.: `abandoned`). */
export const MatchResultSchema = z.object({
  winnerUserId: z.uuid().nullable(),
  endReason: z.string().regex(/^[a-z_]{1,32}$/),
  durationS: z.number().int().min(0).max(MAX_DURATION_S),
  players: z.array(PlayerResultSchema).max(2),
});
export class MatchResultDto extends createZodDto(MatchResultSchema) {}

/** `GET /matches?mine=1`: só a própria conta (JWT); `mine` obrigatório deixa o contrato explícito. */
export class MineQueryDto extends createZodDto(z.object({ mine: z.literal('1') })) {}

const HistorySideSchema = z.object({
  heroId: z.string().nullable(),
  kills: count,
  finalLevel: count,
});

/** Só o lado do oponente que a tela mostra: herói, kills e nível. Nunca id, e-mail ou token. */
const HistoryMatchSchema = z.object({
  matchId: z.uuid(),
  result: z.enum(['win', 'loss', 'interrupted']),
  playedAt: z.iso.datetime(),
  endReason: z.string().nullable(),
  durationS: count.nullable(),
  me: HistorySideSchema.extend({
    deaths: count,
    bossKill: z.boolean(),
    setActive: z.string().nullable(),
  }),
  opponent: HistorySideSchema,
});
const MatchHistorySchema = z.object({
  totals: z.object({ wins: count, losses: count }),
  matches: z.array(HistoryMatchSchema),
});
export class MatchHistoryDto extends createZodDto(MatchHistorySchema) {}
