import { z } from 'zod';

const EnvSchema = z
  .object({
  DATABASE_URL: z.url(),
  JWT_SECRET: z.string().min(32),
  PORT: z.coerce.number().int().positive().default(3000),
  /** Saltos de proxy confiáveis (Coolify/Traefik = 1); sem isso o rate limit vê só o IP do proxy. */
  TRUST_PROXY_HOPS: z.coerce.number().int().min(0).default(0),
  AUTH_RATE_LIMIT: z.coerce.number().int().positive().default(10),
  AUTH_RATE_TTL_MS: z.coerce.number().int().positive().default(60_000),
  /** Segredo compartilhado só entre backend e game server para `/internal/*` (§4.4). */
  INTERNAL_SECRET: z.string().min(32),
  /** Rate limit de `POST/DELETE /queue` (o polling do `GET` não conta). */
  QUEUE_RATE_LIMIT: z.coerce.number().int().positive().default(10),
  QUEUE_RATE_TTL_MS: z.coerce.number().int().positive().default(60_000),
  /** Validade do token de partida (§4.2 passo 3: 2 min). */
  MATCH_TOKEN_TTL_S: z.coerce.number().int().positive().default(120),
  /** Ticket sem polling do Launcher por esse tempo expira (o polling é de 2 s). */
  TICKET_STALE_MS: z.coerce.number().int().positive().default(10_000),
  /** O game server manda heartbeat a cada HEARTBEAT_INTERVAL_MS; HEARTBEAT_MISS_LIMIT faltas → `aborted`. */
  HEARTBEAT_INTERVAL_MS: z.coerce.number().int().positive().default(10_000),
  HEARTBEAT_MISS_LIMIT: z.coerce.number().int().positive().default(3),
  /** Varredura periódica (tickets velhos, tokens vencidos, heartbeats, pareamento pendente). 0 = desligada. */
  SWEEP_INTERVAL_MS: z.coerce.number().int().min(0).default(2_000),
  /** Pool de game servers: N pré-aquecidos, até POOL_MAX sob demanda, portas UDP da faixa abaixo. */
  POOL_SIZE: z.coerce.number().int().min(0).default(2),
  POOL_MAX: z.coerce.number().int().positive().default(10),
  GAME_PORT_MIN: z.coerce.number().int().min(1024).max(65535).default(7000),
  GAME_PORT_MAX: z.coerce.number().int().min(1024).max(65535).default(7020),
  GAMESERVER_IMAGE: z.string().min(1).default('rrb-gameserver:latest'),
  /** Host/IP que o Launcher recebe no `MatchAssignment`. */
  GAMESERVER_PUBLIC_HOST: z.string().min(1).default('127.0.0.1'),
  /** URL do backend vista de dentro do container do game server (endpoints `/internal/*`). */
  GAMESERVER_BACKEND_URL: z.string().min(1).default('http://host.docker.internal:3000'),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent']).default('info'),
  })
  .refine((env) => env.INTERNAL_SECRET !== env.JWT_SECRET, {
    path: ['INTERNAL_SECRET'],
    message: 'INTERNAL_SECRET tem de ser diferente de JWT_SECRET',
  });

export type AppConfig = z.infer<typeof EnvSchema>;

/** Falha no boot se faltar variável — `.env.example` lista todas. */
export function loadConfig(env: NodeJS.ProcessEnv = process.env): AppConfig {
  return EnvSchema.parse(env);
}
