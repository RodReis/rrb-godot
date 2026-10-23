import { Api, Kpi } from '../api/client';
import { Empty, ErrorBox, Loading } from '../components/States';
import { formatKpiValue } from '../format';
import { AuthFailure, useLoad } from '../useLoad';

interface KpiScreenProps {
  api: Api;
  token: string;
  onAuthFailure: (failure: AuthFailure) => void;
}

/** Ordem e agrupamento do painel (SPEC-029 §4); KPI de chave nova cai em "Outros". */
const GROUPS: { title: string; keys: string[] }[] = [
  { title: 'Rede', keys: ['ping_avg', 'ping_over_limit'] },
  { title: 'Duração', keys: ['duration_avg', 'duration_over_limit'] },
  { title: 'Equilíbrio do F1', keys: ['f1_leader_wins', 'f1_ties'] },
  { title: 'Teleportes', keys: ['teleports_total', 'teleports_avg'] },
];

type Verdict = 'within' | 'outside' | 'none';

function verdictOf(kpi: Kpi): { verdict: Verdict; text: string } {
  if (kpi.value === null) return { verdict: 'none', text: 'Sem dados' };
  if (kpi.withinLimit === null) return { verdict: 'none', text: 'Sem limite no PRD' };
  return kpi.withinLimit
    ? { verdict: 'within', text: 'Dentro do limite' }
    : { verdict: 'outside', text: 'Fora do limite' };
}

function KpiRow({ kpi }: { kpi: Kpi }) {
  const { verdict, text } = verdictOf(kpi);
  const fromClient = kpi.source === 'client';
  return (
    <li className="kpi" data-kpi={kpi.key} data-verdict={verdict}>
      <div className="kpi-name">
        <h4>{kpi.label}</h4>
        <p className={fromClient ? 'source source-client' : 'source'}>
          {fromClient ? 'Cliente · não confiável' : 'Servidor'}
        </p>
      </div>
      <p className="kpi-value">{formatKpiValue(kpi)}</p>
      <div className="kpi-verdict">
        <p className="verdict">{text}</p>
        <p className="kpi-meta">
          {kpi.limitLabel ? `Limite: ${kpi.limitLabel} · ` : ''}N = {kpi.n}
        </p>
      </div>
    </li>
  );
}

function groupsOf(kpis: Kpi[]): { title: string; kpis: Kpi[] }[] {
  const known = new Set(GROUPS.flatMap((group) => group.keys));
  const groups = GROUPS.map((group) => ({
    title: group.title,
    kpis: group.keys.flatMap((key) => kpis.filter((kpi) => kpi.key === key)),
  }));
  groups.push({ title: 'Outros', kpis: kpis.filter((kpi) => !known.has(kpi.key)) });
  return groups.filter((group) => group.kpis.length > 0);
}

export function KpiScreen({ api, token, onAuthFailure }: KpiScreenProps) {
  const { state, reload } = useLoad(() => api.kpis(token), [api, token], onAuthFailure);

  if (state.status === 'loading') return <Loading what="KPIs" />;
  if (state.status === 'error') {
    return <ErrorBox message="Não foi possível carregar os KPIs." onRetry={reload} />;
  }
  const { matches, kpis } = state.data;
  if (matches === 0) {
    return (
      <Empty
        title="Nenhuma partida finalizada ainda"
        hint="Os KPIs usam só partidas finalizadas com jogadores. Abandonadas e abortadas ficam na lista."
      />
    );
  }
  return (
    <section aria-labelledby="kpis-title">
      <header className="section-head">
        <h2 id="kpis-title">KPIs do playtest</h2>
        <p>
          Base: <strong>{matches}</strong> {matches === 1 ? 'partida finalizada' : 'partidas finalizadas'}. Limites do PRD §9.2.
        </p>
      </header>
      {groupsOf(kpis).map((group) => (
        <section key={group.title} className="kpi-group" aria-label={group.title}>
          <h3 className="group-title">{group.title}</h3>
          <ul className="kpi-list">
            {group.kpis.map((kpi) => (
              <KpiRow key={kpi.key} kpi={kpi} />
            ))}
          </ul>
        </section>
      ))}
    </section>
  );
}
