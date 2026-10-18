import { heroes, icon, img } from "../data";
import "./Heroes.css";

export function Heroes() {
  return (
    <section id="herois" className="section heroes">
      <div className="heroes-banner" aria-hidden="true">
        <img src={img("heroes.webp")} alt="" loading="lazy" />
      </div>
      <div className="container">
        <div className="section-head reveal">
          <span className="eyebrow">Heróis</span>
          <h2>{heroes.length} heróis, três habilidades cada</h2>
          <p>Nome, papel e habilidades vêm dos mesmos arquivos de dados que o jogo usa.</p>
        </div>
        <ul className="hero-grid">
          {heroes.map((h) => (
            <li key={h.id} className="hero-card glass reveal">
              {h.portrait && <img className="hero-portrait" src={img(h.portrait)} alt={`Retrato: ${h.name}`} width="192" height="192" loading="lazy" />}
              <div className="hero-body">
                <header>
                  <h3>{h.name}</h3>
                  <span className="chip">{h.role}{h.weapon && ` · ${h.weapon}`}</span>
                </header>
                <p>{h.summary}</p>
                <ul className="skills">
                  {h.skills.map((s) => (
                    <li key={s.key} title={`${s.name}: ${s.description}`}>
                      {s.icon ? <img src={icon(s.icon)} alt="" width="48" height="48" loading="lazy" /> : <span className="skill-fallback" />}
                      <span className="skill-key">{s.key}</span>
                      <span className="skill-name">{s.name}</span>
                    </li>
                  ))}
                </ul>
              </div>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
