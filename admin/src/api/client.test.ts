import { describe, expect, it, vi } from 'vitest';
import { ApiError, createApi } from './client';

function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });
}

describe('createApi', () => {
  it('login: POST /auth/login com e-mail e senha no corpo (nunca na URL)', async () => {
    const fetchFn = vi.fn().mockResolvedValue(jsonResponse(200, { accessToken: 'a', refreshToken: 'r' }));

    const tokens = await createApi(fetchFn).login('dono@rrb.dev', 'senha1234');

    expect(tokens.accessToken).toBe('a');
    const [url, init] = fetchFn.mock.calls[0] as [string, RequestInit];
    expect(url).toBe('/auth/login');
    expect(init.method).toBe('POST');
    expect(JSON.parse(init.body as string)).toEqual({ email: 'dono@rrb.dev', password: 'senha1234' });
  });

  it('kpis: GET /admin/kpis com Authorization Bearer e o token fora da URL', async () => {
    const fetchFn = vi.fn().mockResolvedValue(jsonResponse(200, { matches: 0, kpis: [] }));

    await createApi(fetchFn).kpis('segredo-jwt');

    const [url, init] = fetchFn.mock.calls[0] as [string, RequestInit];
    expect(url).toBe('/admin/kpis');
    expect((init.headers as Record<string, string>).Authorization).toBe('Bearer segredo-jwt');
    expect(url).not.toContain('segredo-jwt');
  });

  it('matches: manda página e só os filtros preenchidos, codificados', async () => {
    const fetchFn = vi
      .fn()
      .mockImplementation(async () => jsonResponse(200, { page: 2, pageSize: 50, total: 0, matches: [] }));

    await createApi(fetchFn).matches('t', { endReason: 'kill_goal', heroId: ' ' }, 2);
    await createApi(fetchFn).matches('t', { endReason: '', heroId: 'bruxo de fogo' }, 1);

    expect(fetchFn.mock.calls[0]?.[0]).toBe('/admin/matches?page=2&endReason=kill_goal');
    expect(fetchFn.mock.calls[1]?.[0]).toBe('/admin/matches?page=1&heroId=bruxo+de+fogo');
  });

  it('matchesCsv: GET /admin/matches.csv com os mesmos filtros e devolve o Blob', async () => {
    const fetchFn = vi.fn().mockResolvedValue(new Response('a,b\r\n', { status: 200 }));

    const blob = await createApi(fetchFn).matchesCsv('t', { endReason: 'abandoned', heroId: '' });

    expect(fetchFn.mock.calls[0]?.[0]).toBe('/admin/matches.csv?endReason=abandoned');
    expect(await blob.text()).toBe('a,b\r\n');
  });

  it('erro do backend vira ApiError com status e code', async () => {
    const fetchFn = vi
      .fn()
      .mockImplementation(async () => jsonResponse(403, { statusCode: 403, code: 'ADMIN_REQUIRED', message: 'x' }));

    await expect(createApi(fetchFn).kpis('t')).rejects.toMatchObject({ status: 403, code: 'ADMIN_REQUIRED' });
    await expect(createApi(fetchFn).kpis('t')).rejects.toBeInstanceOf(ApiError);
  });

  it('resposta de erro sem JSON usa o code HTTP_ERROR', async () => {
    const fetchFn = vi.fn().mockResolvedValue(new Response('<html>', { status: 502 }));

    await expect(createApi(fetchFn).kpis('t')).rejects.toMatchObject({ status: 502, code: 'HTTP_ERROR' });
  });

  it('falha de rede vira ApiError NETWORK (status 0)', async () => {
    const fetchFn = vi.fn().mockRejectedValue(new TypeError('Failed to fetch'));

    await expect(createApi(fetchFn).kpis('t')).rejects.toMatchObject({ status: 0, code: 'NETWORK' });
  });
});
