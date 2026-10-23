import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import { App } from './App';
import { ApiError } from './api/client';
import { fakeApi } from './test-helpers';

async function login(email = 'dono@rrb.dev', password = 'senha1234'): Promise<void> {
  await userEvent.type(screen.getByLabelText(/e-mail/i), email);
  await userEvent.type(screen.getByLabelText(/senha/i), password);
  await userEvent.click(screen.getByRole('button', { name: /entrar/i }));
}

describe('App', () => {
  it('começa no login e, com credenciais válidas, abre os KPIs com o token da sessão', async () => {
    const api = fakeApi();
    render(<App api={api} />);

    expect(screen.getByRole('heading', { name: /entrar/i })).toBeInTheDocument();
    await login();

    expect(await screen.findByText('Ping médio')).toBeInTheDocument();
    expect(api.login).toHaveBeenCalledWith('dono@rrb.dev', 'senha1234');
    expect(api.kpis).toHaveBeenCalledWith('jwt-de-teste');
    expect(window.sessionStorage.getItem('rrb-admin-access-token')).toBe('jwt-de-teste');
  });

  it('o token nunca vai para a URL', async () => {
    render(<App api={fakeApi()} />);
    await login();
    await screen.findByText('Ping médio');

    expect(window.location.href).not.toContain('jwt-de-teste');
    expect(window.location.search).toBe('');
  });

  it('credenciais erradas: mensagem no formulário e continua no login', async () => {
    const api = fakeApi({ login: vi.fn().mockRejectedValue(new ApiError(401, 'INVALID_CREDENTIALS')) });
    render(<App api={api} />);

    await login('x@y.z', 'errada123');

    expect(await screen.findByRole('alert')).toHaveTextContent(/e-mail ou senha inválidos/i);
    expect(api.kpis).not.toHaveBeenCalled();
    expect(window.sessionStorage.getItem('rrb-admin-access-token')).toBeNull();
  });

  it('muitas tentativas e falha de rede têm mensagem própria', async () => {
    const api = fakeApi({ login: vi.fn().mockRejectedValueOnce(new ApiError(429, 'RATE_LIMITED')).mockRejectedValueOnce(new ApiError(0, 'NETWORK')) });
    render(<App api={api} />);

    await login();
    expect(await screen.findByRole('alert')).toHaveTextContent(/muitas tentativas/i);
    await userEvent.click(screen.getByRole('button', { name: /entrar/i }));
    expect(await screen.findByText(/sem conexão/i)).toBeInTheDocument();
  });

  it('não envia o formulário vazio', async () => {
    const api = fakeApi();
    render(<App api={api} />);

    await userEvent.click(screen.getByRole('button', { name: /entrar/i }));

    expect(api.login).not.toHaveBeenCalled();
    expect(await screen.findByRole('alert')).toHaveTextContent(/informe e-mail e senha/i);
  });

  it('conta sem papel admin (403) vê "Sem acesso" e pode sair', async () => {
    const api = fakeApi({ kpis: vi.fn().mockRejectedValue(new ApiError(403, 'ADMIN_REQUIRED')) });
    render(<App api={api} />);
    await login('jogador@rrb.dev');

    expect(await screen.findByRole('heading', { name: /sem acesso/i })).toBeInTheDocument();
    expect(screen.queryByText('Ping médio')).not.toBeInTheDocument();

    await userEvent.click(screen.getByRole('button', { name: /sair/i }));
    expect(screen.getByRole('heading', { name: /entrar/i })).toBeInTheDocument();
    expect(window.sessionStorage.getItem('rrb-admin-access-token')).toBeNull();
  });

  it('sessão vencida (401) volta ao login com aviso', async () => {
    const api = fakeApi({ kpis: vi.fn().mockRejectedValue(new ApiError(401, 'UNAUTHORIZED')) });
    render(<App api={api} />);
    await login();

    expect(await screen.findByRole('heading', { name: /entrar/i })).toBeInTheDocument();
    expect(screen.getByRole('alert')).toHaveTextContent(/sessão expirada/i);
  });

  it('com token na sessão pula o login; "Partidas" abre a lista; "Sair" limpa o token', async () => {
    window.sessionStorage.setItem('rrb-admin-access-token', 'jwt-guardado');
    const api = fakeApi();
    render(<App api={api} />);

    expect(await screen.findByText('Ping médio')).toBeInTheDocument();
    expect(api.login).not.toHaveBeenCalled();
    expect(api.kpis).toHaveBeenCalledWith('jwt-guardado');

    await userEvent.click(screen.getByRole('button', { name: 'Partidas' }));
    expect(await screen.findByText('Alfa')).toBeInTheDocument();

    await userEvent.click(screen.getByRole('button', { name: /sair/i }));
    expect(screen.getByRole('heading', { name: /entrar/i })).toBeInTheDocument();
    expect(window.sessionStorage.getItem('rrb-admin-access-token')).toBeNull();
  });
});
