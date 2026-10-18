import { Nav } from "./components/Nav";
import { Hero } from "./components/Hero";
import { HowItWorks } from "./components/HowItWorks";
import { Heroes } from "./components/Heroes";
import { useReveal } from "./hooks/useReveal";

export default function App() {
  useReveal();
  return (
    <>
      <Nav />
      <main>
        <Hero />
        <HowItWorks />
        <Heroes />
      </main>
    </>
  );
}
