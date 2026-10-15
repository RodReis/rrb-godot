import { Controller, Get } from '@nestjs/common';
import { ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { SkipThrottle } from '@nestjs/throttler';
import { createZodDto } from 'nestjs-zod';
import { z } from 'zod';

const HealthSchema = z.object({ status: z.literal('ok') });
export class HealthDto extends createZodDto(HealthSchema) {}

/** Status e ping HTTP do rodapé do Launcher (RASTREABILIDADE V-01b): sem conta, sem banco. */
@ApiTags('health')
@SkipThrottle({ auth: true, queue: true })
@Controller('health')
export class HealthController {
  @Get()
  @ApiOkResponse({ type: HealthDto })
  health(): z.infer<typeof HealthSchema> {
    return { status: 'ok' };
  }
}
