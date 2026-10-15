import { JwtService } from '@nestjs/jwt';
import type { AppConfig } from '../config';
import { MatchTokenService } from './match-token.service';

const SECRET = 'segredo-de-teste-com-32-caracteres!!';
const MATCH_ID = '11111111-1111-4111-8111-111111111111';
const PLAYERS = ['22222222-2222-4222-8222-222222222222', '33333333-3333-4333-8333-333333333333'];

async function rejectionCode(promise: Promise<unknown>): Promise<unknown> {
  return promise.then(
    () => undefined,
    (error: { getResponse(): { code: string } }) => error.getResponse().code,
  );
}

describe('MatchTokenService', () => {
  let jwt: JwtService;
  let tokens: MatchTokenService;

  beforeEach(() => {
    jwt = new JwtService({ secret: SECRET });
    tokens = new MatchTokenService(jwt, { MATCH_TOKEN_TTL_S: 120 } as AppConfig);
  });

  it('carrega match_id e player_ids e expira em 2 min', async () => {
    const token = await tokens.sign(MATCH_ID, PLAYERS);

    const payload = jwt.decode<{ iat: number; exp: number }>(token);
    expect(payload.exp - payload.iat).toBe(120);
    await expect(tokens.verify(token)).resolves.toMatchObject({
      typ: 'match',
      match_id: MATCH_ID,
      player_ids: PLAYERS,
    });
  });

  it('token vencido → TOKEN_EXPIRED', async () => {
    const expired = await jwt.signAsync(
      { typ: 'match', match_id: MATCH_ID, player_ids: PLAYERS },
      { expiresIn: -10 },
    );
    expect(await rejectionCode(tokens.verify(expired))).toBe('TOKEN_EXPIRED');
  });

  it('assinatura de outro segredo, lixo e token de usuário → TOKEN_INVALID', async () => {
    const foreign = await new JwtService({ secret: 'outro-segredo-com-pelo-menos-32-caracteres' }).signAsync({
      typ: 'match',
      match_id: MATCH_ID,
      player_ids: PLAYERS,
    });
    const access = await jwt.signAsync({ sub: PLAYERS[0], typ: 'access' }, { expiresIn: '15m' });

    expect(await rejectionCode(tokens.verify(foreign))).toBe('TOKEN_INVALID');
    expect(await rejectionCode(tokens.verify('nao-e-um-jwt'))).toBe('TOKEN_INVALID');
    expect(await rejectionCode(tokens.verify(access))).toBe('TOKEN_INVALID');
  });

  it('hash é sha256 hex estável e distinto por token', async () => {
    const a = await tokens.sign(MATCH_ID, PLAYERS);
    const b = await tokens.sign('44444444-4444-4444-8444-444444444444', PLAYERS);

    expect(MatchTokenService.hash(a)).toMatch(/^[0-9a-f]{64}$/);
    expect(MatchTokenService.hash(a)).toBe(MatchTokenService.hash(a));
    expect(MatchTokenService.hash(a)).not.toBe(MatchTokenService.hash(b));
  });
});
