import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import { ApiError } from '../api/client';
import { fakeApi, match, matchList, player } from '../test-helpers';
import { MatchesScreen } from './MatchesScreen';

function renderScreen(api = fakeApi(), saveFile = vi.fn()) {
  render(<MatchesScreen api={api} token="t" onAuthFailure={vi.fn()} saveFile={saveFile} />);
  return { api, saveFile };
}

describe('MatchesScreen', () => {
  it('lista a partida com os dois jogadores e os campos de estatística', async () => {
    renderScreen();

    expect(await screen.findByText('Alfa')).toBeInTheDocument();
    expect(screen.getByText('Beta')).toBeInTheDocument();
    const row = screen.getByText('Alfa').closest('tr') as HTMLElement;
    expect(within(row).getByText('Vencedor')).toBeInTheDocument();
    expect(within(row).getByText('knight')).toBeInTheDocument();
    expect(within(row).getByText('50 ms')).toBeInTheDocument();
    expect(screen.getByText('9 min 0 s')).toBeInTheDocument();
    expect(screen.getByText('kill_goal')).toBeInTheDocument();
  });

  it('teleporte nulo aparece como traço e a coluna avisa que o dado é do cliente', async () => {
    renderScreen();

    const row = (await screen.findByText('Beta')).closest('tr') as HTMLElement;
    expect(within(row).getAllByText('—').length).toBeGreaterThan(0);
    expect(screen.getByRole('columnheader', { name: /teleportes/i })).toHaveTextContent(/cliente/i);
  });

  it('aplica os filtros ao enviar e volta para a página 1', async () => {
    const { api } = renderScreen();
    await screen.findByText('Alfa');

    await userEvent.type(screen.getByLabelText(/motivo do fim/i), 'abandoned');
    await userEvent.type(screen.getByLabelText(/herói/i), 'rogue');
    await userEvent.click(screen.getByRole('button', { name: 'Filtrar' }));

    await vi.waitFor(() =>
      expect(api.matches).toHaveBeenLastCalledWith('t', { endReason: 'abandoned', heroId: 'rogue' }, 1),
    );
  });

  it('paginação: próxima/anterior pedem a página certa e respeitam os limites', async () => {
    const api = fakeApi({
      matches: vi.fn().mockImplementation(async (_t: string, _f: unknown, page: number) =>
        matchList([match()], { page, total: 120 }),
      ),
    });
    renderScreen(api);
    await screen.findByText('Alfa');

    expect(screen.getByText(/página 1 de 3/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /anterior/i })).toBeDisabled();
    await userEvent.click(screen.getByRole('button', { name: /próxima/i }));

    await vi.waitFor(() => expect(api.matches).toHaveBeenLastCalledWith('t', { endReason: '', heroId: '' }, 2));
    expect(await screen.findByText(/página 2 de 3/i)).toBeInTheDocument();
  });

  it('"Baixar CSV" pede o arquivo com os filtros aplicados e entrega ao navegador', async () => {
    const { api, saveFile } = renderScreen();
    await screen.findByText('Alfa');

    await userEvent.type(screen.getByLabelText(/motivo do fim/i), 'kill_goal');
    await userEvent.click(screen.getByRole('button', { name: 'Filtrar' }));
    await vi.waitFor(() => expect(api.matches).toHaveBeenCalledTimes(2));
    await userEvent.click(screen.getByRole('button', { name: /baixar csv/i }));

    await vi.waitFor(() => expect(saveFile).toHaveBeenCalledTimes(1));
    expect(api.matchesCsv).toHaveBeenCalledWith('t', { endReason: 'kill_goal', heroId: '' });
    expect(saveFile.mock.calls[0]?.[1]).toBe('partidas.csv');
  });

  it('falha no CSV avisa sem derrubar a lista', async () => {
    renderScreen(fakeApi({ matchesCsv: vi.fn().mockRejectedValue(new ApiError(500, 'HTTP_ERROR')) }));
    await screen.findByText('Alfa');

    await userEvent.click(screen.getByRole('button', { name: /baixar csv/i }));

    expect(await screen.findByRole('alert')).toHaveTextContent(/não foi possível baixar/i);
    expect(screen.getByText('Alfa')).toBeInTheDocument();
  });

  it('sem partidas: estado vazio', async () => {
    renderScreen(fakeApi({ matches: vi.fn().mockResolvedValue(matchList([])) }));

    expect(await screen.findByText(/nenhuma partida encontrada/i)).toBeInTheDocument();
  });

  it('erro: mensagem e "Tentar de novo"', async () => {
    const matches = vi.fn().mockRejectedValueOnce(new ApiError(500, 'HTTP_ERROR')).mockResolvedValueOnce(matchList([match()]));
    renderScreen(fakeApi({ matches }));

    expect(await screen.findByRole('alert')).toHaveTextContent(/não foi possível carregar/i);
    await userEvent.click(screen.getByRole('button', { name: /tentar de novo/i }));

    expect(await screen.findByText('Alfa')).toBeInTheDocument();
  });

  it('partida sem jogador ainda aparece (uma linha sem jogador)', async () => {
    renderScreen(fakeApi({ matches: vi.fn().mockResolvedValue(matchList([match({ players: [], status: 'aborted', endReason: 'abandoned' })])) }));

    expect(await screen.findByText('abandoned')).toBeInTheDocument();
    expect(screen.getByText(/sem jogadores/i)).toBeInTheDocument();
  });

  it('boss e set ativo aparecem', async () => {
    renderScreen(fakeApi({ matches: vi.fn().mockResolvedValue(matchList([match({ players: [player({ nickname: 'Solo', bossKill: true, setActive: 'cacador' })] })])) }));

    const row = (await screen.findByText('Solo')).closest('tr') as HTMLElement;
    expect(within(row).getByText('cacador')).toBeInTheDocument();
    expect(within(row).getByText('Sim')).toBeInTheDocument();
  });
});
