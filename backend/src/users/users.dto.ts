import { createZodDto } from 'nestjs-zod';
import { z } from 'zod';

/** CONVENTION.md §4.8: 3–16 caracteres, só `A–Z a–z 0–9 _`. O `#` de exibição não é digitado nem guardado. */
export const NICKNAME_PATTERN = /^[A-Za-z0-9_]{3,16}$/;

// Mensagem = código de erro: o filtro devolve como `code` e o Launcher traduz.
export const SetNicknameSchema = z.object({
  nickname: z
    .string()
    .regex(NICKNAME_PATTERN, 'INVALID_NICKNAME')
    .meta({ description: '3–16 caracteres: A–Z a–z 0–9 _ (único sem diferenciar maiúsculas)' }),
});
export class SetNicknameDto extends createZodDto(SetNicknameSchema) {}

/** Motivos que o Launcher pode registrar; `history` (migração) não vem do cliente. */
export const CLIENT_QUEUE_UNLOCK_REASONS = ['tutorial', 'bot_win'] as const;

export const QueueUnlockSchema = z.object({
  reason: z.enum(CLIENT_QUEUE_UNLOCK_REASONS).meta({ description: 'Por que a fila online foi liberada' }),
});
export class QueueUnlockDto extends createZodDto(QueueUnlockSchema) {}

/**
 * `nickname` nulo = a conta ainda não passou pela tela de definir nickname (F35). O `meta` fixa o
 * OpenAPI 3.0 (`nullable`): com `type: [string, null]` no topo o @nestjs/swagger lê um array.
 */
export const UserProfileSchema = z.object({
  id: z.uuid(),
  email: z.email(),
  nickname: z.string().nullable().meta({ type: 'string', nullable: true }),
  queueUnlockReason: z.string().nullable().meta({
    type: 'string',
    nullable: true,
    description: '`tutorial` | `bot_win` | `history`; nulo = fila online bloqueada (SPEC-085)',
  }),
  createdAt: z.iso.datetime(),
});
export class UserProfileDto extends createZodDto(UserProfileSchema) {}
export type UserProfile = z.infer<typeof UserProfileSchema>;
