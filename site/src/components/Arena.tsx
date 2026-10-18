import { historia, img } from "../data";
import { Gallery } from "./Gallery";
import "./Arena.css";

export function Arena() {
  const bestiario = historia.pilares.find((p) => /besti/i.test(p.titulo));
  return (
    <section id="arena" className="section arena">
      <div className="arena-bg" aria-hidden="true">
        <img src={img("arena_day.webp")} alt="" className="arena-day" loading="lazy" />
        <img src={img("arena_night.webp")} alt="" className="arena-night" loading="lazy" />
      </div>
      <div className="container">
        <div className="section-head reveal">
          <span className="eyebrow">Arena</span>
          <h2>Um vale, dois portões, um centro disputado</h2>
          <p>Cada lado tem a própria base e metade do mapa para farmar. No meio, o Rei Esqueleto surge aos 3:30 e o centro vira disputa. O dia vira noite ao longo da partida.</p>
        </div>
        {bestiario && (
          <ul className="beasts">
            {bestiario.itens.map((b) => (
              <li key={b.nome} className="glass reveal">
                <strong>{b.nome}</strong>
                <span className="chip">{b.papel}</span>
                <p>{b.texto}</p>
              </li>
            ))}
          </ul>
        )}
        <Gallery />
      </div>
    </section>
  );
}
