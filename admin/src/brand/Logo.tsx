import type { CSSProperties } from "react";

type Props = { variant?: "horizontal" | "stacked"; size?: number; className?: string };

/** Ícone: baú aberto com um "play" subindo do interior (loot + start). */
export function LogoIcon({ size = 32 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 64 64" aria-hidden="true">
      <defs>
        <linearGradient id="ls-gold" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#ffc174" />
          <stop offset="1" stopColor="#f59e0b" />
        </linearGradient>
      </defs>
      {/* tampa aberta */}
      <path d="M10 30 L54 30 L50 14 Q32 8 14 14 Z" fill="url(#ls-gold)" stroke="#78350f" strokeWidth="1.5" strokeLinejoin="round" />
      {/* interior */}
      <rect x="14" y="30" width="36" height="7" fill="#0b1326" />
      {/* play subindo */}
      <path d="M26 6 L26 28 L44 17 Z" fill="#dae2fd" />
      {/* corpo */}
      <rect x="10" y="36" width="44" height="20" rx="3" fill="url(#ls-gold)" stroke="#78350f" strokeWidth="1.5" />
      <rect x="18" y="36" width="4" height="20" fill="#78350f" opacity="0.6" />
      <rect x="42" y="36" width="4" height="20" fill="#78350f" opacity="0.6" />
      {/* fechadura */}
      <rect x="28" y="40" width="8" height="9" rx="1.5" fill="#0b1326" />
      <circle cx="32" cy="43.5" r="1.4" fill="#ffc174" />
    </svg>
  );
}

export function Logo({ variant = "horizontal", size = 32, className = "" }: Props) {
  const stacked = variant === "stacked";
  const style = { "--logo-size": `${size}px` } as CSSProperties;
  return (
    <span className={`logo ${stacked ? "logo-stacked" : ""} ${className}`} style={style}>
      <LogoIcon size={stacked ? size * 2.4 : size} />
      <span className="logo-word">Loot Start</span>
    </span>
  );
}
