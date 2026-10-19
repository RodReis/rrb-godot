import { Logo } from "../brand/Logo";
import { historia, img, RELEASES_URL, REPO_URL, HAS_RELEASE } from "../data";
import "./Hero.css";

const MODES = [
  { nome: "1x1", detalhe: "Duelo. O modo atual.", ativo: true },
  { nome: "2x2", detalhe: "Duplas. Em breve.", ativo: false },
  { nome: "3x3", detalhe: "Trios. Em breve.", ativo: false },
];

export function Hero() {
  return (
    <section id="top" className="hero grain" style={{ backgroundImage: `url(${img("arena_night.webp")})` }}>
      <div className="hero-fog hero-fog-a" aria-hidden="true" />
      <div className="hero-fog hero-fog-b" aria-hidden="true" />
      <div className="hero-content container">
        <h1 className="hero-title"><Logo variant="stacked" size={40} /></h1>
        <p className="hero-tagline">{historia.projeto.tagline}</p>
        <div className="hero-ctas">
          <a className="btn btn-primary" href={RELEASES_URL}>
            Baixar para Windows{!HAS_RELEASE && <span className="chip hero-soon">em breve</span>}
          </a>
          <a className="btn btn-ghost" href={REPO_URL}>Ver no GitHub</a>
        </div>
        <ul className="hero-modes" aria-label="Modos de jogo">
          {MODES.map((m) => (
            <li key={m.nome} className={`glass hero-mode ${m.ativo ? "is-active" : ""}`}>
              <strong>{m.nome}</strong>
              <span>{m.detalhe}</span>
              <span className="chip">{m.ativo ? "ativo" : "em breve"}</span>
            </li>
          ))}
        </ul>
        <ul className="hero-chips" aria-label="Resumo">
          <li className="chip">≤ 10 min</li><li className="chip">Godot 4.7</li><li className="chip">Servidor autoritativo</li><li className="chip">Windows</li>
        </ul>
      </div>
      <a className="hero-scroll" href="#como-funciona" aria-label="Rolar para Como funciona">↓</a>
    </section>
  );
}
