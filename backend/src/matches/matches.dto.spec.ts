import { MatchResultSchema } from './matches.dto';

const USER = '11111111-1111-4111-8111-111111111111';
const player = {
  userId: USER,
  heroId: 'arqueiro',
  kills: 1,
  deaths: 0,
  finalLevel: 5,
  damageDealt: 10,
  damageTaken: 5,
  monstersKilled: 0,
  chestsOpened: 0,
  bossKill: false,
};
const result = (extra: Record<string, unknown>): unknown => ({
  winnerUserId: USER,
  endReason: 'kill_goal',
  durationS: 300,
  players: [{ ...player, ...extra }],
});

describe('MatchResultSchema: teleportCount (SPEC-029)', () => {
  it.each([0, 1, 10_000])('aceita %s', (teleportCount) => {
    const parsed = MatchResultSchema.safeParse(result({ teleportCount }));
    expect(parsed.success).toBe(true);
    expect(parsed.data?.players[0]?.teleportCount).toBe(teleportCount);
  });

  it('é opcional e aceita nulo (cliente que caiu ou não enviou)', () => {
    expect(MatchResultSchema.safeParse(result({})).success).toBe(true);
    expect(MatchResultSchema.safeParse(result({ teleportCount: null })).success).toBe(true);
  });

  it.each([-1, 10_001, 1.5, '3', Number.NaN])('rejeita %s', (teleportCount) => {
    expect(MatchResultSchema.safeParse(result({ teleportCount })).success).toBe(false);
  });
});
