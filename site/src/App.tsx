import { Nav } from "./components/Nav";
import { Hero } from "./components/Hero";
import { HowItWorks } from "./components/HowItWorks";
import { Heroes } from "./components/Heroes";
import { Arena } from "./components/Arena";
import { Roadmap } from "./components/Roadmap";
import { Footer } from "./components/Footer";
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
        <Arena />
        <Roadmap />
      </main>
      <Footer />
    </>
  );
}
