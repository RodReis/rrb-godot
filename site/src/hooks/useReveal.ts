import { useEffect } from "react";

/** Marca cada .reveal com .is-in quando entra na viewport (uma vez). */
export function useReveal() {
  useEffect(() => {
    const els = document.querySelectorAll<HTMLElement>(".reveal");
    if (!("IntersectionObserver" in window)) { els.forEach((e) => e.classList.add("is-in")); return; }
    const io = new IntersectionObserver((entries) => {
      for (const en of entries) if (en.isIntersecting) { en.target.classList.add("is-in"); io.unobserve(en.target); }
    }, { rootMargin: "0px 0px -10% 0px" });
    els.forEach((e) => io.observe(e));
    return () => io.disconnect();
  }, []);
}
