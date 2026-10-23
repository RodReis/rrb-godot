import { FormEvent, useState } from 'react';
import { AdminMatch, AdminPlayer, Api, MatchFilters } from '../api/client';
import { Empty, ErrorBox, Loading } from '../components/States';
import { formatDateTime, formatDuration, formatNumber } from '../format';
import { AuthFailure, useLoad } from '../useLoad';

interface MatchesScreenProps {
  api: Api;
  token: string;
  onAuthFailure: (failure: AuthFailure) => void;
  /** Entrega o CSV ao navegador (troca nos testes: jsdom não baixa arquivo). */
  saveFile?: (blob: Blob, name: string) => void;
}

const NO_FILTERS: MatchFilters = { endReason: '', heroId: '' };
const CSV_NAME = 'partidas.csv';
const PLAYER_COLUMNS = 14;
const SHORT_ID = 8;

const STATUS_LABEL: Record<AdminMatch['status'], string> = {
  assigned: 'Atribuída',
  running: 'Em andamento',
  finished: 'Finalizada',
  aborted: 'Abortada',
};

function downloadBlob(blob: Blob, name: string): void {
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = name;
  document.body.append(link);
  link.click();
  link.remove();
  URL.revokeObjectURL(url);
}

const orDash = (value: string | null): string => value ?? '—';
const ms = (value: number | null): string => (value === null ? '—' : `${formatNumber(value)} ms`);

function MatchCell({ match, rows }: { match: AdminMatch; rows: number }) {
  return (
    <th scope="rowgroup" rowSpan={rows} className="match-cell">
      <span className="match-when">{formatDateTime(match.createdAt)}</span>
      <span className={`status status-${match.status}`}>{STATUS_LABEL[match.status]}</span>
      <code>{orDash(match.endReason)}</code>
      <span className="match-meta">{formatDuration(match.durationS)}</span>
      <span className="match-meta match-id">{match.matchId.slice(0, SHORT_ID)}</span>
    </th>
  );
}

function PlayerCells({ player }: { player: AdminPlayer }) {
  return (
    <>
      <td className="nick">
        {orDash(player.nickname)}
        {player.isWinner && <span className="winner">Vencedor</span>}
      </td>
      <td>{orDash(player.heroId)}</td>
      <td className="num">
        {player.kills} / {player.deaths}
      </td>
      <td className="num">{player.finalLevel}</td>
      <td className="num">{player.levelAtPhase1End ?? '—'}</td>
      <td className="num">{formatNumber(player.damageDealt)}</td>
      <td className="num">{formatNumber(player.damageTaken)}</td>
      <td className="num">{player.monstersKilled}</td>
      <td className="num">{player.chestsOpened}</td>
      <td>{player.bossKill ? 'Sim' : 'Não'}</td>
      <td>{orDash(player.setActive)}</td>
      <td className="num">{ms(player.avgPingMs)}</td>
      <td className="num" title="Relatado pelo cliente: dado não confiável">
        {player.teleportCount ?? '—'}
      </td>
    </>
  );
}

function MatchBody({ match }: { match: AdminMatch }) {
  const { players } = match;
  if (players.length === 0) {
    return (
      <tbody>
        <tr>
          <MatchCell match={match} rows={1} />
          <td colSpan={PLAYER_COLUMNS - 1} className="muted">
            Sem jogadores registrados
          </td>
        </tr>
      </tbody>
    );
  }
  return (
    <tbody>
      {players.map((player, index) => (
        <tr key={index}>
          {index === 0 && <MatchCell match={match} rows={players.length} />}
          <PlayerCells player={player} />
        </tr>
      ))}
    </tbody>
  );
}

function MatchesTable({ matches }: { matches: AdminMatch[] }) {
  return (
    <div className="table-wrap" tabIndex={0} role="region" aria-label="Tabela de partidas">
      <table className="matches">
        <thead>
          <tr>
            <th scope="col">Partida</th>
            <th scope="col">Jogador</th>
            <th scope="col">Herói</th>
            <th scope="col">K / D</th>
            <th scope="col">Nível final</th>
            <th scope="col">Nível F1</th>
            <th scope="col">Dano causado</th>
            <th scope="col">Dano sofrido</th>
            <th scope="col">Monstros</th>
            <th scope="col">Baús</th>
            <th scope="col">Boss</th>
            <th scope="col">Set</th>
            <th scope="col">Ping</th>
            <th scope="col">
              Teleportes <small>(cliente, não confiável)</small>
            </th>
          </tr>
        </thead>
        {matches.map((match) => (
          <MatchBody key={match.matchId} match={match} />
        ))}
      </table>
    </div>
  );
}

function FilterForm({ applied, onApply }: { applied: MatchFilters; onApply: (filters: MatchFilters) => void }) {
  const [draft, setDraft] = useState(applied);
  const submit = (event: FormEvent): void => {
    event.preventDefault();
    onApply({ endReason: draft.endReason.trim(), heroId: draft.heroId.trim() });
  };
  const clear = (): void => {
    setDraft(NO_FILTERS);
    onApply(NO_FILTERS);
  };
  return (
    <form className="filters" onSubmit={submit}>
      <label className="field">
        <span>Motivo do fim</span>
        <input value={draft.endReason} onChange={(e) => setDraft({ ...draft, endReason: e.target.value })} />
      </label>
      <label className="field">
        <span>Herói</span>
        <input value={draft.heroId} onChange={(e) => setDraft({ ...draft, heroId: e.target.value })} />
      </label>
      <button type="submit" className="btn btn-primary">
        Filtrar
      </button>
      <button type="button" className="btn" onClick={clear}>
        Limpar
      </button>
    </form>
  );
}

export function MatchesScreen({ api, token, onAuthFailure, saveFile = downloadBlob }: MatchesScreenProps) {
  const [filters, setFilters] = useState(NO_FILTERS);
  const [page, setPage] = useState(1);
  const [csvError, setCsvError] = useState(false);
  const { state, reload } = useLoad(
    () => api.matches(token, filters, page),
    [api, token, filters.endReason, filters.heroId, page],
    onAuthFailure,
  );

  function apply(next: MatchFilters): void {
    setFilters(next);
    setPage(1);
  }

  async function downloadCsv(): Promise<void> {
    setCsvError(false);
    try {
      saveFile(await api.matchesCsv(token, filters), CSV_NAME);
    } catch {
      setCsvError(true);
    }
  }

  const pages = state.status === 'ready' ? Math.max(1, Math.ceil(state.data.total / state.data.pageSize)) : 1;
  return (
    <section aria-labelledby="matches-title">
      <header className="section-head">
        <h2 id="matches-title">Partidas</h2>
        <button type="button" className="btn" onClick={() => void downloadCsv()}>
          Baixar CSV
        </button>
      </header>
      <FilterForm applied={filters} onApply={apply} />
      {csvError && (
        <p role="alert" className="form-error">
          Não foi possível baixar o CSV.
        </p>
      )}
      {state.status === 'loading' && <Loading what="partidas" />}
      {state.status === 'error' && <ErrorBox message="Não foi possível carregar as partidas." onRetry={reload} />}
      {state.status === 'ready' && state.data.matches.length === 0 && (
        <Empty title="Nenhuma partida encontrada" hint="Ajuste os filtros ou jogue uma partida." />
      )}
      {state.status === 'ready' && state.data.matches.length > 0 && (
        <>
          <MatchesTable matches={state.data.matches} />
          <nav className="pager" aria-label="Paginação">
            <button type="button" className="btn" disabled={page <= 1} onClick={() => setPage(page - 1)}>
              Anterior
            </button>
            <span>
              Página {page} de {pages} · {state.data.total} partidas
            </span>
            <button type="button" className="btn" disabled={page >= pages} onClick={() => setPage(page + 1)}>
              Próxima
            </button>
          </nav>
        </>
      )}
    </section>
  );
}
