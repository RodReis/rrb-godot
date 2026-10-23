import { DependencyList, useCallback, useEffect, useState } from 'react';
import { ApiError } from './api/client';

export type LoadState<T> =
  | { status: 'loading' }
  | { status: 'ready'; data: T }
  | { status: 'error'; error: ApiError };

export type AuthFailure = 'expired' | 'forbidden';

/** 401 = sessão vencida; 403 = conta sem papel admin. Os outros erros ficam na tela. */
export function authFailureOf(error: ApiError): AuthFailure | null {
  if (error.status === 401) return 'expired';
  if (error.status === 403) return 'forbidden';
  return null;
}

function asApiError(error: unknown): ApiError {
  return error instanceof ApiError ? error : new ApiError(0, 'UNEXPECTED');
}

/**
 * Carrega dados assíncronos com os estados carregando / pronto / erro. Respostas de uma carga
 * antiga (filtro ou página trocados no meio do voo) são descartadas. `reload` repete a carga.
 */
export function useLoad<T>(
  loader: () => Promise<T>,
  deps: DependencyList,
  onAuthFailure: (failure: AuthFailure) => void,
): { state: LoadState<T>; reload: () => void } {
  const [state, setState] = useState<LoadState<T>>({ status: 'loading' });
  const [attempt, setAttempt] = useState(0);

  useEffect(() => {
    let current = true;
    setState({ status: 'loading' });
    loader().then(
      (data) => {
        if (current) setState({ status: 'ready', data });
      },
      (raw: unknown) => {
        if (!current) return;
        const error = asApiError(raw);
        const failure = authFailureOf(error);
        if (failure) onAuthFailure(failure);
        else setState({ status: 'error', error });
      },
    );
    return () => {
      current = false;
    };
    // `loader` e `onAuthFailure` mudam a cada render; o que decide recarregar são `deps` e `attempt`.
  }, [...deps, attempt]);

  const reload = useCallback(() => setAttempt((n) => n + 1), []);
  return { state, reload };
}
