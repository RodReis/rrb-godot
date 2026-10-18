import { historia } from "../data";
import "./HowItWorks.css";

const mmss = (s: number) => `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;

export function HowItWorks() {
  const { partida, projeto } = historia;
  const total = partida.duracao_total_s;
  const resumo = partida.faixas.map((f) => `${f.rotulo} de ${mmss(f.de)} a ${mmss(f.ate)}`).join("; ");
  return (
    <section id="como-funciona" className="section container">
      <div className="section-head reveal">
        <span className="eyebrow">Como funciona</span>
        <h2>{partida.titulo}</h2>
        <p>{projeto.pitch[0]}</p>
      </div>
      <div className="timeline glass reveal" role="img" aria-label={`Linha do tempo da partida: ${resumo}`}>
        <div className="timeline-bar">
          {partida.faixas.map((f) => (
            <div key={f.rotulo} className={`timeline-seg seg-${f.cor}`} style={{ flexGrow: f.ate - f.de }}>
              <strong>{f.rotulo}</strong>
              <small>{f.detalhe}</small>
            </div>
          ))}
        </div>
        <ul className="timeline-marks">
          {partida.marcos.map((m) => (
            <li key={m.t} style={{ left: `${(m.t / total) * 100}%` }}><span>{mmss(m.t)}</span>{m.rotulo}</li>
          ))}
        </ul>
      </div>
      <ul className="rules">
        {partida.regras.map((r, i) => <li key={r} className="glass reveal"><span className="rule-n">{i + 1}</span>{r}</li>)}
      </ul>
    </section>
  );
}
