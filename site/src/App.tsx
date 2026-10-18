import { Logo } from "./brand/Logo";

export default function App() {
  return (
    <main style={{ display: "grid", placeItems: "center", minHeight: "100vh" }}>
      <h1><Logo variant="stacked" size={40} /></h1>
    </main>
  );
}
