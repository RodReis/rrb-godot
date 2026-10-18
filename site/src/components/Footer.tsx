import { Logo } from "../brand/Logo";
import { historia, REPO_URL } from "../data";
import "./Footer.css";

export function Footer() {
  return (
    <footer className="footer">
      <div className="container footer-grid">
        <div>
          <Logo size={20} />
          <p>Projeto solo de aprendizado e portfólio. Godot 4, GDScript, servidor autoritativo.</p>
          <a href={REPO_URL}>Código no GitHub</a>
        </div>
        <div>
          <span className="eyebrow">Créditos</span>
          <ul>{historia.creditos.map((c) => <li key={c}>{c}</li>)}</ul>
        </div>
      </div>
    </footer>
  );
}
