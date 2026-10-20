import {
  ArgumentsHost,
  BadRequestException,
  Catch,
  ExceptionFilter,
  HttpException,
  Logger,
} from '@nestjs/common';
import { DrizzleQueryError } from 'drizzle-orm/errors';
import type { Response } from 'express';
import { createZodValidationPipe } from 'nestjs-zod';
import { ZodError } from 'zod';

/** `code` padrão quando quem lançou não informou um. */
const DEFAULT_CODES: Record<number, string> = {
  400: 'VALIDATION_FAILED',
  401: 'UNAUTHORIZED',
  403: 'FORBIDDEN',
  404: 'NOT_FOUND',
  409: 'CONFLICT',
  413: 'PAYLOAD_TOO_LARGE',
  426: 'CLIENT_OUTDATED',
  429: 'RATE_LIMITED',
};

const ERROR_CODE = /^[A-Z_]+$/;

/** Mensagem do zod em SCREAMING_SNAKE vira `code` (ex.: WEAK_PASSWORD); o resto, VALIDATION_FAILED. */
export const ZodValidationPipe = createZodValidationPipe({
  createValidationException: (error: unknown) => {
    const issues = error instanceof ZodError ? error.issues : [];
    const first = issues[0]?.message ?? '';
    return new BadRequestException({
      code: ERROR_CODE.test(first) ? first : 'VALIDATION_FAILED',
      message: 'Dados inválidos',
      fields: issues.map((issue) => issue.path.join('.')),
    });
  },
});

/**
 * Contrato de erro com o Launcher: todo erro sai como `{ statusCode, code, message, ...}`.
 * Nunca loga o corpo da requisição nem os parâmetros de query do banco (e-mail, hash).
 */
@Catch()
export class HttpErrorFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpErrorFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const res = host.switchToHttp().getResponse<Response>();
    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const body = exception.getResponse();
      const fields = typeof body === 'object' ? body : { message: body };
      res.status(status).json({
        code: DEFAULT_CODES[status] ?? 'HTTP_ERROR',
        ...fields,
        statusCode: status,
      });
      return;
    }
    // Erro do body-parser (http-errors) traz o próprio 4xx: ex. 413 corpo acima de 100 KB.
    const status = (exception as { status?: unknown }).status;
    if (typeof status === 'number' && status >= 400 && status < 500) {
      res.status(status).json({
        statusCode: status,
        code: DEFAULT_CODES[status] ?? 'HTTP_ERROR',
        message: 'Requisição inválida',
      });
      return;
    }
    this.logger.error(safeForLog(exception));
    res.status(500).json({ statusCode: 500, code: 'INTERNAL_ERROR', message: 'Erro interno' });
  }
}

/** `DrizzleQueryError` leva SQL e `params` na mensagem e no stack; loga só o nome e a causa. */
export function safeForLog(exception: unknown): unknown {
  return exception instanceof DrizzleQueryError
    ? { name: exception.name, cause: exception.cause?.message }
    : exception;
}
