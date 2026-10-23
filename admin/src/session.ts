const KEY = 'rrb-admin-access-token';

/**
 * Access token só em `sessionStorage` (morre com a aba) e na memória do React; nunca na URL.
 * O storage pode lançar (modo privado, site data bloqueado): sem ele a sessão vale só até recarregar.
 */
export function loadToken(): string | null {
  try {
    return window.sessionStorage.getItem(KEY);
  } catch {
    return null;
  }
}

export function saveToken(token: string | null): void {
  try {
    if (token === null) window.sessionStorage.removeItem(KEY);
    else window.sessionStorage.setItem(KEY, token);
  } catch {
    // ignorado de propósito: ver comentário acima.
  }
}
