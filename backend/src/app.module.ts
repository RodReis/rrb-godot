import { DynamicModule, Module } from '@nestjs/common';
import { APP_FILTER, APP_PIPE } from '@nestjs/core';
import { JwtModule } from '@nestjs/jwt';
import { ThrottlerModule } from '@nestjs/throttler';
import { LoggerModule } from 'nestjs-pino';
import { AuthController } from './auth/auth.controller';
import { AuthService } from './auth/auth.service';
import { APP_CONFIG } from './common/app-config';
import { Clock, SystemClock } from './common/clock';
import { HttpErrorFilter, ZodValidationPipe } from './common/http-error.filter';
import { InternalGuard } from './common/internal.guard';
import { JwtGuard } from './common/jwt.guard';
import { AppConfig } from './config';
import { Database } from './db/database';
import { HealthController } from './health.controller';
import { InternalMatchesController, MatchesController } from './matches/matches.controller';
import { DrizzleMatchesRepository, MatchesRepository } from './matches/matches.repository';
import { MatchesService } from './matches/matches.service';
import { QueueController } from './matchmaking/queue.controller';
import { DrizzleQueueRepository, QueueRepository } from './matchmaking/queue.repository';
import { QueueService } from './matchmaking/queue.service';
import { ContainerRuntime } from './orchestrator/container-runtime';
import { DockerRuntime } from './orchestrator/docker-runtime';
import { MatchTokenService } from './orchestrator/match-token.service';
import { OrchestratorService } from './orchestrator/orchestrator.service';
import { SweeperService } from './sweeper.service';
import { UsersController } from './users/users.controller';
import { DrizzleUsersRepository, UsersRepository } from './users/users.repository';

// ponytail: um módulo só (Database, JwtService e config são compartilhados por tudo); separar em
// módulos de feature quando houver um segundo processo ou o grafo de providers ficar difícil de ler.
@Module({})
export class AppModule {
  /** Config explícita (não lida do env aqui) para o e2e e o gerador de OpenAPI montarem o app. */
  static forRoot(config: AppConfig): DynamicModule {
    return {
      module: AppModule,
      imports: [
        LoggerModule.forRoot({
          pinoHttp: {
            level: config.LOG_LEVEL,
            redact: ['req.headers.authorization', 'req.headers.cookie', 'req.headers["x-internal-secret"]'],
          },
        }),
        // Dois limiters nomeados: cada controller pula o do outro (@SkipThrottle).
        ThrottlerModule.forRoot([
          { name: 'auth', ttl: config.AUTH_RATE_TTL_MS, limit: config.AUTH_RATE_LIMIT },
          { name: 'queue', ttl: config.QUEUE_RATE_TTL_MS, limit: config.QUEUE_RATE_LIMIT },
        ]),
        JwtModule.register({
          secret: config.JWT_SECRET,
          signOptions: { algorithm: 'HS256' },
          verifyOptions: { algorithms: ['HS256'] },
        }),
      ],
      controllers: [
        HealthController,
        AuthController,
        UsersController,
        QueueController,
        MatchesController,
        InternalMatchesController,
      ],
      providers: [
        { provide: APP_CONFIG, useValue: config },
        { provide: Database, useFactory: () => new Database(config.DATABASE_URL) },
        { provide: Clock, useClass: SystemClock },
        { provide: ContainerRuntime, useClass: DockerRuntime },
        { provide: UsersRepository, useClass: DrizzleUsersRepository },
        { provide: MatchesRepository, useClass: DrizzleMatchesRepository },
        { provide: QueueRepository, useClass: DrizzleQueueRepository },
        { provide: APP_PIPE, useClass: ZodValidationPipe },
        { provide: APP_FILTER, useClass: HttpErrorFilter },
        AuthService,
        MatchTokenService,
        OrchestratorService,
        MatchesService,
        QueueService,
        SweeperService,
        JwtGuard,
        InternalGuard,
      ],
    };
  }
}
