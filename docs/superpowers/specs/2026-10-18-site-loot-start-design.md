# Site Loot Start — design

**Data:** 2026-10-18 · **Decisões do PI:** mesma data, em pop-up.
**Estado:** implementado na PR #218 e no ar em https://rodreis.github.io/rrb-godot/. Documento vivo: `docs/SITE.md`; decisão: ADR-0017. Mudanças em relação a este texto: o hero usa `arena_night` com o véu roxo do splash (o `splash.png` tem "ARENA 1V1" gravado), os heróis ganharam retrato por card e a arena mostra dia/noite e o mapa de cima em quadros grandes.

## 1. O que é

Landing page pública do jogo, com a marca **Loot Start** (nome só no site por enquanto; rename do jogo é card/ADR futuro do Cowork). Página única, estática, pt-BR, sem login e sem backend. Referência visual: splash do launcher (`shared/assets/ui/loading/splash.png`) e protótipos de `docs/prd/telas/`.

Fora da v1: i18n, newsletter, analytics, launcher web, rename do jogo.

## 2. Onde mora e como publica

- `site/` no monorepo (3º módulo; nota para o Cowork atualizar ADR-0002).
- Vite + React 19 + TypeScript. CSS puro com custom properties; sem Tailwind, sem lib de UI, sem roteador.
- Deploy: `.github/workflows/site.yml` → GitHub Pages do repo `RodReis/rrb-godot` (`base: /rrb-godot/`), disparado em push na `main` que toque `site/**`, `shared/data/heroes/**`, `docs/roadmap/**` ou `docs/STATUS.md`. O `ci.yml` ganha filtro `site: ['site/**']` que roda `npm ci && npm run build` em PR.
- Fontes do Google Fonts: Cinzel (display/logo, como o splash), Outfit (corpo), JetBrains Mono (números) — as duas últimas são as do launcher (F24).

## 3. Dados (abordagem A — extração em build)

`site/scripts/extract.mjs` (Node 18+, sem dependências) gera `site/src/data/`:

| Saída | Fonte | Campos |
|---|---|---|
| `heroes.json` | `shared/data/heroes/*.tres` | `id`, `display_name`, `role`, `weapon_name`, `summary`, skills `q/e/r` (`display_name`, `description`, `icon` → caminho do SVG copiado para `site/public/icons/`) |
| `historia.json` | `docs/roadmap/historia.json` | cópia |
| `roadmap.json` | `docs/STATUS.md` §2/§3 + `.proplan/STATUS.md`, pela função `parseStatus()` extraída de `tools/roadmap/build-roadmap.mjs` para `tools/roadmap/status.mjs` (o gerador do roadmap passa a importar dela; o teste existente cobre) | por MVP: `id`, `titulo`, `pergunta`, `estado` (`concluido`/`andamento`/`planejado`), `entregues`, `total` |
| `capturas.json` | `historia.json` → `capitulos.*.imagens` com `tipo: "entregue"` | `arquivo`, `legenda`, `mvp` |

Imagens: o script copia `docs/roadmap/img/*.webp` usados e converte `splash.png`, `arena_day.png`, `arena_night.png`, `heroes.png` para `.webp` ≤ 1920 px em `site/public/img/` (conversão com `sharp` como devDependency; se o PI rejeitar a dependência, converter uma vez à mão e versionar).

`npm run build` = `extract` + `tsc --noEmit` + `vite build`. Os JSON gerados ficam no `.gitignore`.

Teste: `site/scripts/extract.test.mjs` com `node --test` cobre o parser `.tres` (sub_resource de skill, `&"id"`, multiline) e o mapeamento de estado do roadmap.

## 4. Marca

Logo em SVG inline (`site/src/brand/Logo.tsx`), sem PNG:

- **Wordmark** "LOOT START" em Cinzel 700, caps, tracking 0,12 em, preenchimento gradiente vertical `#FFC174` → `#F59E0B`, contorno 1 px `#78350F` a 40 %.
- **Ícone**: baú aberto visto de frente (tampa levantada), com um raio/lâmina vertical saindo do interior — "loot" + "start". Duas cores: ouro e `#DAE2FD`. Legível em 24 px (favicon `site/public/favicon.svg`) e em 240 px.
- Variantes: horizontal (ícone + wordmark em linha, nav) e empilhada (ícone sobre wordmark, hero). Prop `variant`.

Tokens (`site/src/styles/tokens.css`), valores de `docs/design-system/TOKENS.md` §1: `--bg-surface #0B1326`, `--bg-panel #171F33`, `--bg-card #222A3D`, `--gold #F59E0B`, `--gold-bright #FFC174`, `--gold-edge #78350F`, `--on-gold #613B00`, `--blue #3198DC`, `--cyan #93CCFF`, `--red #EF4444`, `--green #22C55E`, `--purple #A855F7`, `--text #DAE2FD`, `--text-muted #D8C3AD`, `--border #534434`. Raios 4/8/12/16. Durações 0,15/0,3/0,6 s.

Atmosfera: neblina roxo-escura do splash por gradientes radiais (`#3a1f3a` a 35 % sobre `--bg-surface`) + grain SVG `feTurbulence` a 4 % de opacidade; painéis "vidro" (`--bg-panel` 85 %, borda 1 px ouro 35 %, sombra preta 55 %/16 px) com cantoneiras douradas 8×2 px, iguais ao `PanelCardGlass` da HUD. Botão primário: fundo ouro, texto `--on-gold`, borda inferior 3 px `--gold-edge`.

Motion: entrada por `IntersectionObserver` (fade + 12 px, 0,3 s, `cubic-bezier(0.16,1,0.3,1)`); parallax de 2 camadas de neblina no hero (translate no scroll, `transform` só). Tudo desligado em `prefers-reduced-motion`.

## 5. Seções (ordem na página)

1. **Nav** fixa, vidro: logo horizontal, âncoras Como funciona · Heróis · Arena · Roadmap, botão "Baixar". Colapsa em menu simples (`<details>`) abaixo de 768 px.
2. **Hero**: `splash.webp` em tela cheia com véu escuro; logo empilhada; tagline de `historia.json.projeto.tagline`; CTA primário "Baixar para Windows" → `https://github.com/RodReis/rrb-godot/releases` (sem Release ainda: a página de Releases mostra vazio; o botão leva um rótulo "em breve" enquanto `historia.json` não tiver `release_url`); CTA secundário "Ver no GitHub". Três chips: 1x1 · ≤ 10 min · Godot 4.7.
3. **Como funciona**: linha do tempo horizontal 0–10 min com as 3 faixas (ouro/vermelho/roxo) e marcos de `historia.json.partida`; abaixo, as 3 `regras`.
4. **Heróis**: fundo `heroes.webp`; grid responsivo de cards (3 col ≥ 1024, 2 col ≥ 640, 1 col abaixo), um por `.tres`: nome, papel, arma, resumo, três skills com ícone SVG + nome + descrição em tooltip nativo (`title`). Cresce sozinho quando entra herói novo.
5. **Arena**: `arena_day.webp` ↔ `arena_night.webp` em crossfade de 8 s (CSS animation); texto de `historia.json.pilares` sobre a arena; **galeria** com as capturas `entregue` (lazy, `<dialog>` nativo como lightbox, setas por teclado).
6. **Roadmap**: um card por MVP (MVP0…MVP4, inclusive os decimais): título, pergunta, estado (`feito` ouro / `andamento` azul / `futuro` cinza), barra de fatias feitas/total.
7. **Rodapé**: GitHub, créditos CC0 (KayKit, Quaternius), "projeto solo de aprendizado e portfólio".

Acessibilidade: landmarks (`header/nav/main/section/footer`), `h1` único, foco visível ouro, contraste conforme TOKENS.md (vermelho/roxo só em texto ≥ 24 px bold). Página sem rolagem horizontal em 375 px.

## 6. Estrutura

```
site/
  index.html  package.json  vite.config.ts  tsconfig.json  .gitignore (dist/, src/data/, public/img/, public/icons/)
  scripts/extract.mjs  scripts/extract.test.mjs
  public/favicon.svg
  src/main.tsx  src/App.tsx
  src/brand/Logo.tsx
  src/styles/tokens.css  src/styles/global.css
  src/components/{Nav,Hero,HowItWorks,Heroes,Arena,Gallery,Roadmap,Footer}.tsx (+ .css ao lado)
  src/hooks/useReveal.ts
  src/data/*.json (gerado)
```

## 7. Pronto quando

- `npm run build` verde na CI e Pages publicado.
- Todas as seções do §5 com dados reais das fontes do §3.
- Screenshots em 1440/768/375 sem overflow, aceitas pelo PI lado a lado com o splash.
- `node --test site/scripts` verde.
