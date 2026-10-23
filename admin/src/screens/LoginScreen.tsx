import { FormEvent, useState } from 'react';
import { Api, ApiError } from '../api/client';
import { Logo } from '../brand/Logo';

interface LoginScreenProps {
  api: Api;
  /** Aviso de uma sessão que acabou (ex.: token vencido). */
  notice: string | null;
  onSuccess: (accessToken: string) => void;
}

const MESSAGES: Record<string, string> = {
  INVALID_CREDENTIALS: 'E-mail ou senha inválidos.',
  RATE_LIMITED: 'Muitas tentativas. Aguarde um minuto e tente de novo.',
  NETWORK: 'Sem conexão com o servidor.',
};

function messageFor(error: unknown): string {
  const code = error instanceof ApiError ? error.code : '';
  return MESSAGES[code] ?? 'Não foi possível entrar. Tente de novo.';
}

export function LoginScreen({ api, notice, onSuccess }: LoginScreenProps) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit(event: FormEvent): Promise<void> {
    event.preventDefault();
    if (email.trim() === '' || password === '') {
      setError('Informe e-mail e senha.');
      return;
    }
    setBusy(true);
    setError(null);
    try {
      const tokens = await api.login(email.trim(), password);
      onSuccess(tokens.accessToken);
    } catch (failure) {
      setError(messageFor(failure));
      setBusy(false);
    }
  }

  const message = error ?? notice;
  return (
    <main className="login">
      <div className="login-plate glass">
        <Logo variant="stacked" size={20} />
        <p className="eyebrow">Painel de playtest</p>
        <h1>Entrar</h1>
        <p className="login-lede">Painel interno de KPIs e partidas. Use a conta de jogador marcada como admin.</p>
        <form onSubmit={(event) => void submit(event)} noValidate>
          <label className="field">
            <span>E-mail</span>
            <input
              type="email"
              autoComplete="username"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
            />
          </label>
          <label className="field">
            <span>Senha</span>
            <input
              type="password"
              autoComplete="current-password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
            />
          </label>
          {message && (
            <p role="alert" className="form-error">
              {message}
            </p>
          )}
          <button type="submit" className="btn btn-primary" disabled={busy}>
            {busy ? 'Entrando…' : 'Entrar'}
          </button>
        </form>
      </div>
    </main>
  );
}
