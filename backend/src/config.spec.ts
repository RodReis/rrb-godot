import { loadConfig } from './config';

const base = {
  DATABASE_URL: 'postgres://rrb:rrb@localhost:5432/rrb',
  JWT_SECRET: 'segredo-jwt-com-pelo-menos-32-caracteres',
  INTERNAL_SECRET: 'segredo-interno-com-pelo-menos-32-caracteres',
};

describe('loadConfig', () => {
  it('aceita segredos distintos e aplica os padrões da fila e do pool', () => {
    const config = loadConfig(base);

    expect(config).toMatchObject({ MATCH_TOKEN_TTL_S: 120, POOL_SIZE: 2, GAME_PORT_MIN: 7000, GAME_PORT_MAX: 7020 });
  });

  it('INTERNAL_SECRET igual ao JWT_SECRET falha o boot (vazar um não pode forjar o outro)', () => {
    expect(() => loadConfig({ ...base, INTERNAL_SECRET: base.JWT_SECRET })).toThrow(/diferente de JWT_SECRET/);
  });

  it('INTERNAL_SECRET ausente ou curto falha o boot', () => {
    expect(() => loadConfig({ ...base, INTERNAL_SECRET: undefined })).toThrow();
    expect(() => loadConfig({ ...base, INTERNAL_SECRET: 'curto' })).toThrow();
  });

  it('GAMESERVER_NETWORK é opcional: vazio = rede padrão do Docker; preenchido entra no config', () => {
    expect(loadConfig(base).GAMESERVER_NETWORK).toBeUndefined();
    expect(loadConfig({ ...base, GAMESERVER_NETWORK: 'rrb-net' }).GAMESERVER_NETWORK).toBe('rrb-net');
    expect(loadConfig({ ...base, GAMESERVER_NETWORK: '' }).GAMESERVER_NETWORK).toBeUndefined();
  });
});
