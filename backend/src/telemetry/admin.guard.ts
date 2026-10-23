import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { AuthenticatedRequest, JwtGuard } from '../common/jwt.guard';
import { UsersRepository } from '../users/users.repository';

/**
 * JWT válido (401 sem ele) **e** `role = admin` lido do banco a cada chamada, não do token:
 * rebaixar ou apagar a conta vale na hora. Qualquer outra conta recebe 403 (SPEC-029 §3.3.4).
 */
@Injectable()
export class AdminGuard implements CanActivate {
  constructor(
    private readonly jwt: JwtGuard,
    private readonly users: UsersRepository,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    await this.jwt.canActivate(context);
    const { userId } = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const user = await this.users.findById(userId);
    if (user?.role !== 'admin') {
      throw new ForbiddenException({ code: 'ADMIN_REQUIRED', message: 'Acesso restrito a administradores' });
    }
    return true;
  }
}
