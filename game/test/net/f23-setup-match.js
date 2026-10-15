// Roteiro F23: cria 2 contas e uma partida `assigned` com 1 token por jogador, como o orquestrador
// do backend faria (sem Docker). Rode da raiz do repo, com o backend local no ar:
//   JWT_SECRET=... DATABASE_URL=... node game/test/net/f23-setup-match.js <saida.json> [url-do-backend]
// A saida tem os tokens: nao commite nem cole em log.
const path = require('node:path');
const crypto = require('node:crypto');
const fs = require('node:fs');

const backend = path.join(__dirname, '..', '..', '..', 'backend');
const { Client } = require(path.join(backend, 'node_modules', 'pg'));
const { JwtService } = require(path.join(backend, 'node_modules', '@nestjs', 'jwt'));

const [outFile, base = 'http://localhost:3000'] = process.argv.slice(2);
if (!outFile || !process.env.JWT_SECRET || !process.env.DATABASE_URL) {
  console.error('uso: JWT_SECRET=... DATABASE_URL=... node f23-setup-match.js <saida.json> [url]');
  process.exit(1);
}
const jwt = new JwtService({ secret: process.env.JWT_SECRET });
const hash = (token) => crypto.createHash('sha256').update(token).digest('hex');
const TOKEN_TTL_S = 120;
const SERVER_PORT = 7000;
const SEED = 4242;

async function register(email) {
  const res = await fetch(`${base}/auth/register`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ email, password: 'senha-forte-12345' }),
  });
  if (!res.ok) throw new Error(`register ${email}: ${res.status} ${await res.text()}`);
  return jwt.decode((await res.json()).accessToken).sub;
}

(async () => {
  const suffix = crypto.randomBytes(3).toString('hex');
  const players = [await register(`a-${suffix}@teste.dev`), await register(`b-${suffix}@teste.dev`)];
  const matchId = crypto.randomUUID();
  const tokens = {};
  for (const userId of players) {
    const claims = { typ: 'match', sub: userId, match_id: matchId, player_ids: players };
    tokens[userId] = await jwt.signAsync(claims, { expiresIn: TOKEN_TTL_S });
  }
  const db = new Client({ connectionString: process.env.DATABASE_URL });
  await db.connect();
  await db.query(
    "INSERT INTO matches (id, status, server_host, server_port, seed, created_at) VALUES ($1, 'assigned', '127.0.0.1', $2, $3, now())",
    [matchId, SERVER_PORT, SEED],
  );
  for (const userId of players) {
    await db.query('INSERT INTO match_players (match_id, user_id, token_hash) VALUES ($1, $2, $3)', [
      matchId,
      userId,
      hash(tokens[userId]),
    ]);
  }
  await db.end();
  const [a, b] = players;
  fs.writeFileSync(outFile, JSON.stringify({ matchId, a, b, tokenA: tokens[a], tokenB: tokens[b] }));
  console.log(`partida ${matchId} (token valido por ${TOKEN_TTL_S} s)`);
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
