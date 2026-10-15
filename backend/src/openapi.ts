import 'reflect-metadata';
import { writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { cleanupOpenApiDoc } from 'nestjs-zod';
import { AppModule } from './app.module';
import { loadConfig } from './config';

/**
 * Gera `backend/openapi.json` (versionado; o Launcher gera `models/` dele — ARCHITECTURE-LAUNCHER §4.1).
 * Não conecta no banco nem escuta porta. A CI falha se o arquivo commitado divergir.
 */
async function generate(): Promise<void> {
  const config = loadConfig({
    DATABASE_URL: 'postgres://openapi@localhost/openapi',
    JWT_SECRET: 'openapi-nao-assina-nada-0123456789abcdef',
    INTERNAL_SECRET: 'openapi-nao-protege-nada-0123456789abcdef',
    LOG_LEVEL: 'silent',
  });
  const app = await NestFactory.create(AppModule.forRoot(config), { logger: false });
  const document = SwaggerModule.createDocument(
    app,
    new DocumentBuilder()
      .setTitle('rrb-godot backend')
      .setDescription('Erros: { statusCode, code, message }. `code` é o contrato com o Launcher.')
      .setVersion('0.1.0')
      .addBearerAuth()
      .addApiKey({ type: 'apiKey', in: 'header', name: 'x-internal-secret' }, 'internal-secret')
      .build(),
  );
  const path = join(process.cwd(), 'openapi.json');
  writeFileSync(path, `${JSON.stringify(cleanupOpenApiDoc(document), null, 2)}\n`);
  await app.close();
  console.log(`openapi.json gerado em ${path}`);
}

void generate();
