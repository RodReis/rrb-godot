import type { AdminMatchList, AuthTokens, KpiReport } from './models';

export type { AdminMatchList, AuthTokens, KpiReport } from './models';
export type Kpi = KpiReport['kpis'][number];
export type AdminMatch = AdminMatchList['matches'][number];
export type AdminPlayer = AdminMatch['players'][number];

/** Filtros da lista e do CSV; texto vazio = sem filtro. */
export interface MatchFilters {
  endReason: string;
  heroId: string;
}

/** Erro do backend (`{ statusCode, code, message }`) ou da rede (`status` 0). */
export class ApiError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
  ) {
    super(`${status} ${code}`);
    this.name = 'ApiError';
  }
}

export interface Api {
  login(email: string, password: string): Promise<AuthTokens>;
  kpis(token: string): Promise<KpiReport>;
  matches(token: string, filters: MatchFilters, page: number): Promise<AdminMatchList>;
  matchesCsv(token: string, filters: MatchFilters): Promise<Blob>;
}

type FetchFn = typeof fetch;

async function send(fetchFn: FetchFn, url: string, init: RequestInit): Promise<Response> {
  let response: Response;
  try {
    response = await fetchFn(url, init);
  } catch {
    throw new ApiError(0, 'NETWORK');
  }
  if (!response.ok) {
    const body = (await response.json().catch(() => null)) as { code?: unknown } | null;
    throw new ApiError(response.status, typeof body?.code === 'string' ? body.code : 'HTTP_ERROR');
  }
  return response;
}

function query(params: Record<string, string | number>): string {
  const search = new URLSearchParams();
  for (const [key, value] of Object.entries(params)) {
    const text = String(value).trim();
    if (text !== '') search.set(key, text);
  }
  const text = search.toString();
  return text === '' ? '' : `?${text}`;
}

const authorized = (token: string): RequestInit => ({ headers: { Authorization: `Bearer ${token}` } });

/** Mesma origem do backend (`/admin-ui` é servido por ele): sem CORS e sem URL base. */
export function createApi(fetchFn: FetchFn = (...args) => fetch(...args)): Api {
  const json = async <T>(url: string, init: RequestInit): Promise<T> =>
    (await (await send(fetchFn, url, init)).json()) as T;

  return {
    login: (email, password) =>
      json<AuthTokens>('/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      }),
    kpis: (token) => json<KpiReport>('/admin/kpis', authorized(token)),
    matches: (token, filters, page) =>
      json<AdminMatchList>(`/admin/matches${query({ page, ...filters })}`, authorized(token)),
    matchesCsv: async (token, filters) =>
      (await send(fetchFn, `/admin/matches.csv${query({ ...filters })}`, authorized(token))).blob(),
  };
}
