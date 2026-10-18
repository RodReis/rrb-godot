import { Nav } from "./components/Nav";
import { Hero } from "./components/Hero";
import { useReveal } from "./hooks/useReveal";

export default function App() {
  useReveal();
  return (
    <>
      <Nav />
      <main>
        <Hero />
      </main>
    </>
  );
}
