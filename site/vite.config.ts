import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// Pages serve em https://rodreis.github.io/rrb-godot/ ; `vite build` e `vite preview` rodam em
// mode "production" e usam esse base; `vite dev` (mode "development") fica na raiz.
export default defineConfig(({ mode }) => ({
  plugins: [react()],
  base: mode === "production" ? "/rrb-godot/" : "/",
}));
