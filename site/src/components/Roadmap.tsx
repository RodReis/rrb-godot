import { roadmap, ROADMAP_URL } from "../data";
import "./Roadmap.css";

const LABEL = { concluido: "Concluído", andamento: "Em andamento", planejado: "Planejado" } as const;

export function Roadmap() {
  return (
    <section id="roadmap" className="section container">
      <div className="section-head reveal">
        <span className="eyebrow">Roadmap</span>
        <h2>O que já existe e o que falta</h2>
        <p>Cada marco responde a uma pergunta. O estado vem direto do quadro de trabalho do projeto.</p>
      </div>
      <ol className="mvps">
        {roadmap.map((m) => (
          <li key={m.id} className={`mvp glass reveal is-${m.estado}`}>
            <header>
              <span className="eyebrow">{m.id}</span>
              <span className={`mvp-state state-${m.estado}`}>{LABEL[m.estado]}</span>
            </header>
            <h3>{m.titulo}</h3>
            {m.pergunta && <p className="mvp-q">{m.pergunta}</p>}
            <div className="mvp-bar" role="progressbar" aria-valuemin={0} aria-valuemax={m.total} aria-valuenow={m.entregues} aria-label={`${m.entregues} de ${m.total} entregas`}>
              <span style={{ width: m.total ? `${(m.entregues / m.total) * 100}%` : 0 }} />
            </div>
            <small>{m.entregues}/{m.total} entregas</small>
          </li>
        ))}
      </ol>
      <p className="roadmap-more reveal">
        Versão longa, com capturas e aprendizados: <a href={ROADMAP_URL}>roadmap completo</a>.
      </p>
    </section>
  );
}
