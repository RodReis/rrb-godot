import {
  ArgumentsHost,
  BadRequestException,
  Catch,
  ExceptionFilter,
  HttpException,
  Logger,
} from '@nestjs/common';
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
 * Nunca loga o corpo da requisição (senha).
 */
@Catch()
export class HttpErrorFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpErrorFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const res = host.switchToHttp().getResponse<Response>();
    if (!(exception instanceof HttpException)) {
      this.logger.error(exception);
      res.status(500).json({ statusCode: 500, code: 'INTERNAL_ERROR', message: 'Erro interno' });
      return;
    }
    const status = exception.getStatus();
    const body = exception.getResponse();
    const fields = typeof body === 'object' ? body : { message: body };
    res.status(status).json({
      code: DEFAULT_CODES[status] ?? 'HTTP_ERROR',
      ...fields,
      statusCode: status,
    });
  }
}
