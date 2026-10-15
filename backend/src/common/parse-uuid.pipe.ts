import { NotFoundException, PipeTransform } from '@nestjs/common';
import { z } from 'zod';

/** `:id` que não é UUID não pode chegar no Postgres (erro 22P02 viraria 500): é 404 com o `code` do recurso. */
export class ParseUuidPipe implements PipeTransform<string, string> {
  constructor(private readonly notFoundCode: string) {}

  transform(value: string): string {
    if (!z.uuid().safeParse(value).success) {
      throw new NotFoundException({ code: this.notFoundCode, message: 'Recurso não encontrado' });
    }
    return value;
  }
}
