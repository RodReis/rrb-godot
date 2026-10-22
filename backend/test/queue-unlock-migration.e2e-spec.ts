import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { Client } from 'pg';

const DATABASE_URL = process.env.TEST_DATABASE_URL ?? 'postgres://rrb:rrb@localhost:5432/rrb_test';
const MIGRATIONS_DIR = join(process.cwd(), 'drizzle', 'migrations');
const TARGET = '0004_fila_liberada.sql';
const SCRATCH = 'mig_queue_unlock';
const STATEMENT_BREAKPOINT = '--> statement-breakpoint';

/** Statements de uma migração drizzle, já apontados para o schema de rascunho (o SQL grava `"public".`). */
function statements(file: string): string[] {
  return readFileSync(join(MIGRATIONS_DIR, file), 'utf8')
    .replaceAll('"public".', `"${SCRATCH}".`)
    .split(STATEMENT_BREAKPOINT)
    .map((sql) => sql.trim())
    .filter(Boolean);
}

/**
 * A migração 0004 libera quem já tem partida no histórico. Para provar isso sem tocar nas tabelas
 * dos outros e2e, repete as migrações anteriores num schema de rascunho dentro de uma transação,
 * cria as contas com partidas ANTES da 0004, aplica o arquivo real e desfaz tudo no fim.
 */
describe('migração 0004: fila liberada para quem tem histórico (e2e)', () => {
  let client: Client;

  beforeAll(async () => {
    client = new Client({ connectionString: DATABASE_URL });
    await client.connect();
  });

  afterAll(async () => {
    await client.end();
  });

  async function account(email: string): Promise<string> {
    const res = await client.query('INSERT INTO users (email, password_hash) VALUES ($1, $2) RETURNING id', [
      email,
      'x',
    ]);
    return (res.rows[0] as { id: string }).id;
  }

  async function playMatch(status: string, userId: string): Promise<void> {
    const match = await client.query(
      `INSERT INTO matches (status, server_host, server_port, seed) VALUES ($1, 'h', 7000, 1) RETURNING id`,
      [status],
    );
    await client.query(`INSERT INTO match_players (match_id, user_id, token_hash) VALUES ($1, $2, 'x')`, [
      (match.rows[0] as { id: string }).id,
      userId,
    ]);
  }

  it('libera contas com partida finished/aborted e mantém bloqueadas as demais', async () => {
    const earlier = readdirSync(MIGRATIONS_DIR)
      .filter((file) => file.endsWith('.sql') && file < TARGET)
      .sort();
    await client.query('BEGIN');
    try {
      await client.query(`CREATE SCHEMA "${SCRATCH}"`);
      await client.query(`SET LOCAL search_path TO "${SCRATCH}"`);
      for (const file of earlier) for (const sql of statements(file)) await client.query(sql);

      // Estado "antes da 0004": contas jogaram (ou não) numa base que ainda não tem a coluna.
      for (const status of ['finished', 'aborted', 'running', 'assigned']) {
        await playMatch(status, await account(`${status}@rrb.dev`));
      }
      await account('none@rrb.dev');

      for (const sql of statements(TARGET)) await client.query(sql);

      const result = await client.query('SELECT email, queue_unlock_reason AS reason FROM users');
      const byEmail = Object.fromEntries(
        (result.rows as { email: string; reason: string | null }[]).map((row) => [row.email, row.reason]),
      );
      expect(byEmail).toEqual({
        'finished@rrb.dev': 'history',
        'aborted@rrb.dev': 'history',
        'running@rrb.dev': null,
        'assigned@rrb.dev': null,
        'none@rrb.dev': null,
      });
    } finally {
      await client.query('ROLLBACK');
    }
  });
});
