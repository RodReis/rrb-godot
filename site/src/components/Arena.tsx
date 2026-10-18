import { historia, img } from "../data";
import { Gallery } from "./Gallery";
import "./Arena.css";

export function Arena() {
  const bestiario = historia.pilares.find((p) => /besti/i.test(p.titulo));
  return (
    <section id="arena" className="section arena">
      <div className="container">
        <div className="section-head reveal">
          <span className="eyebrow">Arena</span>
          <h2>Um vale, dois portões, um centro disputado</h2>
          <p>Cada lado tem a própria base e metade do mapa para farmar. No meio, o Rei Esqueleto surge aos 3:30 e o centro vira disputa. O dia vira noite ao longo da partida.</p>
        </div>

        <div className="arena-showcase">
          <figure className="arena-frame glass reveal">
            <div className="arena-daynight">
              <img src={img("arena_day.webp")} alt="O vale da arena de dia, visto da base" loading="lazy" />
              <img src={img("arena_night.webp")} alt="O vale da arena à noite, visto da base" className="arena-night" loading="lazy" />
            </div>
            <figcaption>O vale visto da base: portões, rio em volta do centro e o castelo do outro lado. Dia e noite se alternam.</figcaption>
          </figure>
          <figure className="arena-frame glass reveal">
            <img src={img("arena_map.webp")} alt="Mapa da arena visto de cima, com duas bases, o rio e o centro" loading="lazy" />
            <figcaption>Vista de cima: duas bases nos cantos, rio em volta do centro e três caminhos entre elas.</figcaption>
          </figure>
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
