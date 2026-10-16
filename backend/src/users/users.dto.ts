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

/**
 * `nickname` nulo = a conta ainda não passou pela tela de definir nickname (F35). O `meta` fixa o
 * OpenAPI 3.0 (`nullable`): com `type: [string, null]` no topo o @nestjs/swagger lê um array.
 */
export const UserProfileSchema = z.object({
  id: z.uuid(),
  email: z.email(),
  nickname: z.string().nullable().meta({ type: 'string', nullable: true }),
  createdAt: z.iso.datetime(),
});
export class UserProfileDto extends createZodDto(UserProfileSchema) {}
export type UserProfile = z.infer<typeof UserProfileSchema>;
