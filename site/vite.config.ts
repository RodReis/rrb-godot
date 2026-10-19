import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// O site e servido pelo VPS na raiz de https://lootstart.cloud (#237): base "/". SITE_BASE troca o
// base se o site voltar a morar num subcaminho (ex.: "/rrb-godot/" no GitHub Pages).
export default defineConfig({
  plugins: [react()],
  base: process.env.SITE_BASE ?? "/",
});
