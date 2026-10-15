import { join } from 'node:path';
import { OnApplicationShutdown } from '@nestjs/common';
import { drizzle, NodePgDatabase } from 'drizzle-orm/node-postgres';
import { migrate } from 'drizzle-orm/node-postgres/migrator';
import { Pool } from 'pg';
import * as schema from '../../drizzle/schema';

// ponytail: relativo ao cwd (backend/ em scripts, CI e Docker); copiar para dist/ se o cwd mudar.
const MIGRATIONS_DIR = join(process.cwd(), 'drizzle', 'migrations');

/** Pool do Postgres. Conecta só na primeira query, então gerar o OpenAPI não precisa de banco. */
export class Database implements OnApplicationShutdown {
  readonly pool: Pool;
  readonly db: NodePgDatabase<typeof schema>;

  constructor(connectionString: string) {
    this.pool = new Pool({ connectionString });
    this.db = drizzle(this.pool, { schema });
  }

  migrate(): Promise<void> {
    return migrate(this.db, { migrationsFolder: MIGRATIONS_DIR });
  }

  async onApplicationShutdown(): Promise<void> {
    await this.pool.end();
  }
}
