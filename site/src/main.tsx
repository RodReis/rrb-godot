import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
// Estilos globais antes do App: os CSS dos componentes vêm depois e podem sobrescrever a base.
import "./styles/tokens.css";
import "./styles/global.css";
import App from "./App";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
