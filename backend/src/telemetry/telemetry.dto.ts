import { createZodDto } from 'nestjs-zod';
import { z } from 'zod';

const count = z.number().int().min(0);
const MAX_PAGE = 1_000_000;
const MAX_NAME_LENGTH = 64;

/**
 * Jogador de uma partida no painel: `nickname`, herói e estatísticas. Nunca e-mail, hash, token nem
 * id de conta (SPEC-029 §3.3.6; mesmo padrão do histórico, `matches.dto.ts`).
 */
const AdminPlayerSchema = z.object({
  nickname: z.string().nullable(),
  isWinner: z.boolean(),
  heroId: z.string().nullable(),
  kills: count,
  deaths: count,
  finalLevel: count,
  damageDealt: z.number(),
  damageTaken: z.number(),
  monstersKilled: count,
  chestsOpened: count,
  bossKill: z.boolean(),
  setActive: z.string().nullable(),
  levelAtPhase1End: count.nullable(),
  avgPingMs: count.nullable(),
  /** Relatado pelo cliente: dado não confiável. */
  teleportCount: count.nullable(),
});

const AdminMatchSchema = z.object({
  matchId: z.uuid(),
  status: z.enum(['assigned', 'running', 'finished', 'aborted']),
  seed: z.number().int(),
  serverHost: z.string(),
  serverPort: z.number().int(),
  createdAt: z.iso.datetime(),
  startedAt: z.iso.datetime().nullable(),
  lastHeartbeatAt: z.iso.datetime().nullable(),
  endedAt: z.iso.datetime().nullable(),
  endReason: z.string().nullable(),
  durationS: count.nullable(),
  players: z.array(AdminPlayerSchema),
});
export type AdminMatch = z.infer<typeof AdminMatchSchema>;
export type AdminPlayer = z.infer<typeof AdminPlayerSchema>;

export const ADMIN_PAGE_SIZE = 50;

const AdminMatchListSchema = z.object({
  page: z.number().int().min(1),
  pageSize: z.literal(ADMIN_PAGE_SIZE),
  total: count,
  matches: z.array(AdminMatchSchema),
});
export class AdminMatchListDto extends createZodDto(AdminMatchListSchema) {}
export type AdminMatchList = z.infer<typeof AdminMatchListSchema>;

const KpiSchema = z.object({
  key: z.string(),
  label: z.string(),
  value: z.number().nullable().describe('Nulo = sem dados (n = 0)'),
  unit: z.enum(['ms', 'percent', 's', 'count']),
  n: count.describe('Partidas ou jogador-partida que entraram no cálculo'),
  source: z.enum(['server', 'client']).describe('`client` = relatado pelo cliente, dado não confiável'),
  limit: z.number().nullable().describe('Limite do PRD §9.2; nulo = sem limite'),
  limitLabel: z.string().nullable(),
  withinLimit: z.boolean().nullable().describe('Nulo = sem limite ou sem dados'),
});
const KpiReportSchema = z.object({
  matches: count.describe('Partidas finished com pelo menos um jogador (base dos KPIs)'),
  kpis: z.array(KpiSchema),
});
export class KpiReportDto extends createZodDto(KpiReportSchema) {}

/** Filtros de `GET /admin/matches` e `.csv` (o CSV ignora `page`). */
const FilterShape = {
  endReason: z
    .string()
    .regex(/^[a-z_]{1,32}$/)
    .optional(),
  heroId: z.string().min(1).max(MAX_NAME_LENGTH).optional(),
};
export const AdminMatchesQuerySchema = z.object({
  page: z.coerce.number().int().min(1).max(MAX_PAGE).default(1),
  ...FilterShape,
});
export class AdminMatchesQueryDto extends createZodDto(AdminMatchesQuerySchema) {}
export class AdminMatchesCsvQueryDto extends createZodDto(z.object(FilterShape)) {}
