import 'reflect-metadata';
import { existsSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { Logger } from 'nestjs-pino';
import { AppModule } from './app.module';
import { loadConfig } from './config';
import { Database } from './db/database';
import { OrchestratorService } from './orchestrator/orchestrator.service';
import { AdminSeedService } from './telemetry/admin-seed.service';

/** Web-admin (SPEC-029): estáticos do build do `admin/` em `/admin-ui`, mesma origem da API (sem CORS). */
function serveAdminUi(app: NestExpressApplication, dir: string): void {
  const root = resolve(process.cwd(), dir);
  if (!existsSync(join(root, 'index.html'))) {
    app.get(Logger).warn(`web-admin não encontrado em ${root}; /admin-ui fica fora do ar`);
    return;
  }
  app.useStaticAssets(root, { prefix: '/admin-ui' });
}

async function bootstrap(): Promise<void> {
  const config = loadConfig();
  // CORS fica desligado (padrão do Nest): o cliente é o Launcher, não um browser (§4.4).
  const app = await NestFactory.create<NestExpressApplication>(AppModule.forRoot(config), {
    bufferLogs: true,
  });
  app.useLogger(app.get(Logger));
  app.set('trust proxy', config.TRUST_PROXY_HOPS);
  app.enableShutdownHooks();
  // ponytail: migra no boot (uma instância só, Coolify); job separado se houver réplicas.
  await app.get(Database).migrate();
  await app.get(AdminSeedService).seed();
  serveAdminUi(app, config.ADMIN_UI_DIR);
  // Remove containers e partidas de execuções anteriores e pré-aquece o pool (não derruba o boot se o Docker faltar).
  await app.get(OrchestratorService).warm();
  await app.listen(config.PORT);
}

void bootstrap();
