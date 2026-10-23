import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import { ApiError } from '../api/client';
import { fakeApi, kpi, report } from '../test-helpers';
import { KpiScreen } from './KpiScreen';

function renderScreen(api = fakeApi(), onAuthFailure = vi.fn()) {
  render(<KpiScreen api={api} token="t" onAuthFailure={onAuthFailure} />);
  return { api, onAuthFailure };
}

describe('KpiScreen', () => {
  it('mostra carregando e depois o valor, o limite, o N e a origem do dado', async () => {
    renderScreen();

    expect(screen.getByRole('status')).toHaveTextContent(/carregando/i);
    const row = (await screen.findByText('Ping médio')).closest('[data-kpi]') as HTMLElement;
    expect(within(row).getByText('66,36 ms')).toBeInTheDocument();
    expect(within(row).getByText(/≤ 80 ms/)).toBeInTheDocument();
    expect(within(row).getByText(/N = 11/)).toBeInTheDocument();
    expect(within(row).getByText('Servidor')).toBeInTheDocument();
  });

  it('valor dentro do limite diz "Dentro do limite"', async () => {
    renderScreen(fakeApi({ kpis: vi.fn().mockResolvedValue(report([kpi({ withinLimit: true })])) }));

    const row = (await screen.findByText('Ping médio')).closest('[data-kpi]') as HTMLElement;
    expect(within(row).getByText('Dentro do limite')).toBeInTheDocument();
    expect(row).toHaveAttribute('data-verdict', 'within');
  });

  it('valor fora do limite diz "Fora do limite"', async () => {
    renderScreen(
      fakeApi({ kpis: vi.fn().mockResolvedValue(report([kpi({ value: 105, withinLimit: false })])) }),
    );

    const row = (await screen.findByText('Ping médio')).closest('[data-kpi]') as HTMLElement;
    expect(within(row).getByText('105 ms')).toBeInTheDocument();
    expect(within(row).getByText('Fora do limite')).toBeInTheDocument();
    expect(row).toHaveAttribute('data-verdict', 'outside');
  });

  it('KPI sem limite no PRD diz isso; sem dados mostra traço', async () => {
    renderScreen(
      fakeApi({
        kpis: vi.fn().mockResolvedValue(
          report([
            kpi({ key: 'ping_over_limit', label: 'Ping acima de 80 ms', unit: 'percent', value: 27.27, limit: null, limitLabel: null, withinLimit: null }),
            kpi({ key: 'duration_avg', label: 'Duração média', unit: 's', value: null, n: 0, limit: null, limitLabel: null, withinLimit: null }),
          ]),
        ),
      }),
    );

    const noLimit = (await screen.findByText('Ping acima de 80 ms')).closest('[data-kpi]') as HTMLElement;
    expect(within(noLimit).getByText('Sem limite no PRD')).toBeInTheDocument();
    const noData = screen.getByText('Duração média').closest('[data-kpi]') as HTMLElement;
    expect(within(noData).getByText('Sem dados')).toBeInTheDocument();
    expect(within(noData).getByText('—')).toBeInTheDocument();
  });

  it('teleportes são rotulados como dado do cliente, não confiável', async () => {
    renderScreen(
      fakeApi({
        kpis: vi.fn().mockResolvedValue(
          report([kpi({ key: 'teleports_total', label: 'Teleportes (total)', unit: 'count', value: 7, source: 'client', limit: null, limitLabel: null, withinLimit: null })]),
        ),
      }),
    );

    const row = (await screen.findByText('Teleportes (total)')).closest('[data-kpi]') as HTMLElement;
    expect(within(row).getByText(/Cliente · não confiável/)).toBeInTheDocument();
  });

  it('sem nenhuma partida finalizada: estado vazio, sem os KPIs', async () => {
    renderScreen(fakeApi({ kpis: vi.fn().mockResolvedValue(report([kpi({ value: null, n: 0 })], 0)) }));

    expect(await screen.findByText(/nenhuma partida finalizada/i)).toBeInTheDocument();
    expect(screen.queryByText('Ping médio')).not.toBeInTheDocument();
  });

  it('erro de rede: mostra a mensagem e "Tentar de novo" recarrega', async () => {
    const kpis = vi
      .fn()
      .mockRejectedValueOnce(new ApiError(0, 'NETWORK'))
      .mockResolvedValueOnce(report([kpi()]));
    renderScreen(fakeApi({ kpis }));

    expect(await screen.findByRole('alert')).toHaveTextContent(/não foi possível carregar/i);
    await userEvent.click(screen.getByRole('button', { name: /tentar de novo/i }));

    expect(await screen.findByText('Ping médio')).toBeInTheDocument();
    expect(kpis).toHaveBeenCalledTimes(2);
  });

  it('403 e 401 viram falha de autenticação em vez de erro na tela', async () => {
    const forbidden = renderScreen(fakeApi({ kpis: vi.fn().mockRejectedValue(new ApiError(403, 'ADMIN_REQUIRED')) }));
    await vi.waitFor(() => expect(forbidden.onAuthFailure).toHaveBeenCalledWith('forbidden'));
  });
});
