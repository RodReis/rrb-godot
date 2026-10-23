import { useCallback, useState } from 'react';
import { Api, createApi } from './api/client';
import { Logo } from './brand/Logo';
import { KpiScreen } from './screens/KpiScreen';
import { LoginScreen } from './screens/LoginScreen';
import { MatchesScreen } from './screens/MatchesScreen';
import { NoAccess } from './screens/NoAccess';
import { loadToken, saveToken } from './session';
import type { AuthFailure } from './useLoad';

type View = 'kpis' | 'matches';

const EXPIRED_NOTICE = 'Sessão expirada. Entre de novo.';
const TABS: { id: View; label: string }[] = [
  { id: 'kpis', label: 'KPIs' },
  { id: 'matches', label: 'Partidas' },
];
const defaultApi = createApi();

export function App({ api = defaultApi }: { api?: Api }) {
  const [token, setToken] = useState<string | null>(loadToken);
  const [view, setView] = useState<View>('kpis');
  const [forbidden, setForbidden] = useState(false);
  const [notice, setNotice] = useState<string | null>(null);

  const signOut = useCallback((message: string | null = null) => {
    saveToken(null);
    setToken(null);
    setForbidden(false);
    setNotice(message);
  }, []);

  const onAuthFailure = useCallback(
    (failure: AuthFailure) => (failure === 'forbidden' ? setForbidden(true) : signOut(EXPIRED_NOTICE)),
    [signOut],
  );

  if (token === null) {
    return (
      <LoginScreen
        api={api}
        notice={notice}
        onSuccess={(accessToken) => {
          saveToken(accessToken);
          setNotice(null);
          setToken(accessToken);
        }}
      />
    );
  }

  return (
    <div className="shell">
      <header className="topbar glass">
        <div className="brand">
          <Logo size={28} />
          <p className="eyebrow">Painel de playtest</p>
        </div>
        <nav aria-label="Seções">
          {TABS.map((tab) => (
            <button
              key={tab.id}
              type="button"
              className="tab"
              aria-current={view === tab.id ? 'page' : undefined}
              onClick={() => setView(tab.id)}
            >
              {tab.label}
            </button>
          ))}
        </nav>
        <button type="button" className="btn btn-quiet" onClick={() => signOut()}>
          Sair
        </button>
      </header>
      <main className="content">
        {forbidden && <NoAccess />}
        {!forbidden && view === 'kpis' && <KpiScreen api={api} token={token} onAuthFailure={onAuthFailure} />}
        {!forbidden && view === 'matches' && (
          <MatchesScreen api={api} token={token} onAuthFailure={onAuthFailure} />
        )}
      </main>
    </div>
  );
}
