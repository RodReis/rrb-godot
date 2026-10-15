import { DynamicModule, Module } from '@nestjs/common';
import { APP_FILTER, APP_PIPE } from '@nestjs/core';
import { JwtModule } from '@nestjs/jwt';
import { ThrottlerModule } from '@nestjs/throttler';
import { LoggerModule } from 'nestjs-pino';
import { AuthController } from './auth/auth.controller';
import { AuthService } from './auth/auth.service';
import { HttpErrorFilter, ZodValidationPipe } from './common/http-error.filter';
import { JwtGuard } from './common/jwt.guard';
import { AppConfig } from './config';
import { Database } from './db/database';
import { UsersController } from './users/users.controller';
import { DrizzleUsersRepository, UsersRepository } from './users/users.repository';

// ponytail: um módulo só; separar AuthModule/UsersModule quando F22 trouxer matchmaking/orchestrator.
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
            redact: ['req.headers.authorization', 'req.headers.cookie'],
          },
        }),
        ThrottlerModule.forRoot([{ ttl: config.AUTH_RATE_TTL_MS, limit: config.AUTH_RATE_LIMIT }]),
        JwtModule.register({
          secret: config.JWT_SECRET,
          signOptions: { algorithm: 'HS256' },
          verifyOptions: { algorithms: ['HS256'] },
        }),
      ],
      controllers: [AuthController, UsersController],
      providers: [
        { provide: Database, useFactory: () => new Database(config.DATABASE_URL) },
        { provide: UsersRepository, useClass: DrizzleUsersRepository },
        { provide: APP_PIPE, useClass: ZodValidationPipe },
        { provide: APP_FILTER, useClass: HttpErrorFilter },
        AuthService,
        JwtGuard,
      ],
    };
  }
}
