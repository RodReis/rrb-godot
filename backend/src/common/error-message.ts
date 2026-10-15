import { safeForLog } from './http-error.filter';

/** Texto de erro para log sem o SQL e os `params` que o `DrizzleQueryError` carrega (tokens, ids). */
export function errorMessage(error: unknown): string {
  const safe = safeForLog(error);
  if (safe instanceof Error) return safe.message;
  return typeof safe === 'string' ? safe : JSON.stringify(safe);
}
