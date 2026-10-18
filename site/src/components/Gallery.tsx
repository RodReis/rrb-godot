import { useEffect, useRef, useState } from "react";
import { capturas, img } from "../data";
import "./Gallery.css";

const PAGE = 12;

export function Gallery() {
  const [open, setOpen] = useState<number | null>(null);
  const [shown, setShown] = useState(PAGE);
  const dlg = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    const d = dlg.current;
    if (!d) return;
    if (open === null) { if (d.open) d.close(); return; }
    if (!d.open) d.showModal();
  }, [open]);

  const step = (d: number) => setOpen((v) => (v === null ? v : (v + d + capturas.length) % capturas.length));
  const atual = open === null ? null : capturas[open];

  return (
    <>
      <h3 className="gallery-title reveal">Capturas do jogo</h3>
      <ul className="gallery">
        {capturas.slice(0, shown).map((c, k) => (
          <li key={c.arquivo} className="reveal">
            <button type="button" onClick={() => setOpen(k)} aria-label={`Ampliar: ${c.legenda}`}>
              <img src={img(c.arquivo)} alt={c.legenda} loading="lazy" width="640" height="360" />
              <span className="chip">{c.mvp}</span>
            </button>
          </li>
        ))}
      </ul>
      {shown < capturas.length && (
        <button type="button" className="btn btn-ghost gallery-more" onClick={() => setShown((s) => s + PAGE)}>
          Mostrar mais ({capturas.length - shown})
        </button>
      )}
      <dialog
        ref={dlg}
        className="lightbox"
        aria-label="Captura ampliada"
        onClose={() => setOpen(null)}
        onKeyDown={(e) => { if (e.key === "ArrowRight") step(1); if (e.key === "ArrowLeft") step(-1); }}
        onClick={(e) => { if (e.target === dlg.current) setOpen(null); }}
      >
        {atual && open !== null && (
          <figure>
            <img src={img(atual.arquivo)} alt={atual.legenda} />
            <figcaption>{atual.legenda}</figcaption>
            <div className="lightbox-nav">
              <button type="button" onClick={() => step(-1)} aria-label="Anterior">‹</button>
              <span className="chip">{open + 1} / {capturas.length}</span>
              <button type="button" onClick={() => step(1)} aria-label="Próxima">›</button>
              <button type="button" onClick={() => setOpen(null)} aria-label="Fechar">×</button>
            </div>
          </figure>
        )}
      </dialog>
    </>
  );
}
