import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// Pages serve em https://rodreis.github.io/rrb-godot/ ; dev e preview na raiz.
export default defineConfig(({ command }) => ({
  plugins: [react()],
  base: command === "build" ? "/rrb-godot/" : "/",
}));
