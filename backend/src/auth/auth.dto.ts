import { createZodDto } from 'nestjs-zod';
import { z } from 'zod';

// Mensagens são códigos de erro: o filtro devolve a primeira como `code` e o Launcher (F25) traduz.

/** RFC 5321; acima disso o índice único do Postgres pode estourar (500). */
const EMAIL_MAX_LENGTH = 254;
/** Teto técnico contra DoS no argon2 (corpo de até 100 KB), não regra de produto. */
const PASSWORD_MAX_LENGTH = 128;

const Email = z
  .string()
  .trim()
  .toLowerCase()
  .pipe(z.email('INVALID_EMAIL').max(EMAIL_MAX_LENGTH, 'INVALID_EMAIL'))
  .meta({ format: 'email' });

/** CONVENTION.md §4.8: mínimo 8 caracteres, com pelo menos uma letra e um número (PI 2026-10-10). */
const Password = z
  .string()
  .min(8, 'WEAK_PASSWORD')
  .max(PASSWORD_MAX_LENGTH, 'PASSWORD_TOO_LONG')
  // Um regex só (lookaheads): dois `.regex` viram `allOf` e o OpenAPI perde o `type`.
  .regex(/^(?=.*\p{L})(?=.*\d)/su, 'WEAK_PASSWORD')
  .meta({ description: 'Mínimo 8 caracteres, com pelo menos uma letra e um número' });

export const RegisterSchema = z.object({ email: Email, password: Password });
export class RegisterDto extends createZodDto(RegisterSchema) {}

// Login não reaplica a regra de senha: conta antiga com senha fora da regra ainda entra.
export const LoginSchema = z.object({ email: Email, password: z.string().min(1).max(PASSWORD_MAX_LENGTH) });
export class LoginDto extends createZodDto(LoginSchema) {}

export const RefreshSchema = z.object({ refreshToken: z.string().min(1) });
export class RefreshDto extends createZodDto(RefreshSchema) {}

export const AuthTokensSchema = z.object({ accessToken: z.string(), refreshToken: z.string() });
export class AuthTokensDto extends createZodDto(AuthTokensSchema) {}
export type AuthTokens = z.infer<typeof AuthTokensSchema>;
