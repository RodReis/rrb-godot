import { Logo } from "../brand/Logo";
import { RELEASES_URL } from "../data";
import "./Nav.css";

const LINKS = [["#como-funciona", "Como funciona"], ["#herois", "Heróis"], ["#arena", "Arena"], ["#roadmap", "Roadmap"]];

export function Nav() {
  return (
    <header className="nav glass">
      <a href="#top" className="nav-logo" aria-label="Loot Start, início"><Logo size={22} /></a>
      <nav aria-label="Seções">
        <details className="nav-menu">
          <summary aria-label="Menu">☰</summary>
          <ul>{LINKS.map(([href, label]) => <li key={href}><a href={href}>{label}</a></li>)}</ul>
        </details>
        <ul className="nav-links">{LINKS.map(([href, label]) => <li key={href}><a href={href}>{label}</a></li>)}</ul>
      </nav>
      <a className="btn btn-primary nav-cta" href={RELEASES_URL}>Baixar</a>
    </header>
  );
}
