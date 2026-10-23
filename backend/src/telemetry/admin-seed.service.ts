import { Inject, Injectable, Logger } from '@nestjs/common';
import { APP_CONFIG } from '../common/app-config';
import type { AppConfig } from '../config';
import { UsersRepository } from '../users/users.repository';

/**
 * Seed de admins (SPEC-029, ADR-0033): na subida promove as contas de `ADMIN_EMAILS`. Só promove
 * contas que já existem e nunca rebaixa; não há endpoint de promoção. Conta criada depois só vira
 * admin na próxima subida.
 */
@Injectable()
export class AdminSeedService {
  private readonly logger = new Logger(AdminSeedService.name);

  constructor(
    private readonly users: UsersRepository,
    @Inject(APP_CONFIG) private readonly config: AppConfig,
  ) {}

  async seed(): Promise<number> {
    const emails = this.config.ADMIN_EMAILS.map((email) => email.toLowerCase());
    const promoted = await this.users.promoteToAdmin(emails);
    this.logger.log(`ADMIN_EMAILS: ${emails.length} listado(s), ${promoted} promovido(s)`);
    return promoted;
  }
}
