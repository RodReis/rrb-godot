# ADR-0017 — Site público "Loot Start": landing em React no monorepo (`site/`), publicada no GitHub Pages

**Status:** aceito — 2026-10-18
**Decisor:** Rodrigo Reis (PI), em pop-up na sessão do Code
**Emenda:** [ADR-0002](0002-dois-modulos-launcher-e-game.md) — acrescenta um terceiro diretório de código (`site/`), sem relação de código com Game, Launcher ou Backend
**Mantém:** ADR-0002 (Game e Launcher independentes; Launcher continua em Godot) · ADR-0003 (`shared/`) · ADR-0006 (direção visual do jogo)
**Relacionados:** [`docs/SITE.md`](../SITE.md) · spec `docs/superpowers/specs/2026-10-18-site-loot-start-design.md` · PR #218

## Contexto

O PI pediu um site para o jogo, em React, com a mesma referência visual do Launcher (`docs/prd/telas/`), uma logo nova e o estilo do splash do Launcher. O jogo ainda não tem domínio. O nome "Loot Start" foi dado pelo PI para o site.

O ADR-0002 descartou "Launcher web" porque o Launcher precisa de login, fila e processo do Game. Um site público de apresentação não tem nada disso: é estático, sem conta e sem backend.

## Decisão

1. **Escopo:** landing page única em pt-BR: apresentação, como funciona uma partida, heróis, arena com galeria, roadmap e link de download. Sem login, sem backend, sem analytics, sem i18n. Modos 1x1 (ativo), 2x2 e 3x3 aparecem como "em breve".
2. **Nome:** "Loot Start" vale **só no site**. O jogo, o Launcher e o README continuam "ARENA 1V1" até o PI decidir o rename (card futuro).
3. **Onde mora:** `site/` no monorepo, projeto Vite + React 19 + TypeScript, CSS puro com os tokens de `TOKENS.md`. Sem Tailwind, sem biblioteca de UI, sem roteador.
4. **Dados vêm do jogo, em build:** `site/scripts/extract.mjs` lê `shared/data/heroes/*.tres`, `shared/ui/icons`, `shared/assets/ui`, `docs/roadmap/historia.json`, `docs/roadmap/img` e `docs/STATUS.md` + `.proplan/STATUS.md`. O parser de STATUS é o mesmo do roadmap público (`tools/roadmap/status.mjs`). Nenhum texto de herói ou número de entrega é escrito à mão no site.
5. **Publicação:** GitHub Pages, por GitHub Actions (`.github/workflows/site.yml`), a cada push na `main` que mude as fontes. Endereço: `https://rodreis.github.io/rrb-godot/` (`base: /rrb-godot/`). Quando houver domínio próprio, o `base` volta a `/`.
6. **Marca:** logo SVG própria (baú aberto com um "play" subindo) e wordmark em Cinzel dourada, gradiente `GOLD_BRIGHT` → `GOLD`; fundo `BG_SURFACE`, painéis "vidro" iguais ao `PanelCardGlass` da HUD (F57). Hero com a arena à noite e o véu roxo do splash do Launcher (o `splash.png` tem "ARENA 1V1" gravado, por isso não é usado no site).
7. **Dependência nova:** `sharp` (devDependency do `site/`) converte PNG em WebP no build. Aprovado pelo PI.
8. **CI:** job `site` no `ci.yml` (testes do parser, testes do roadmap e `pnpm build`), com filtro de path próprio, dentro do `needs` do `gate`.
9. **Download:** o botão leva à página de Releases do repositório e mostra "em breve" até existir `projeto.release_url` em `historia.json`.

## Alternativas descartadas

| Alternativa | Por que não |
|---|---|
| Launcher web (login, lobby, fila no browser) | Reabre o ADR-0002: backend, fila e handoff de token para o Game. Não valida nenhum risco do PRD. |
| Repositório separado | Perde `shared/data` e `historia.json` como fonte única; o texto dos heróis diverge do jogo. |
| Copiar os dados à mão para JSON do site | Diverge a cada card entregue. |
| Ler os dados em runtime (`raw.githubusercontent.com`) | O site quebra quando o repositório muda; CORS e cache. |
| Vercel ou Netlify | Pages basta, é de graça e não pede conta nova. Pode-se migrar depois sem mudar o código (só o `base`). |
| Reaproveitar `docs/roadmap/index.html` como site | É uma página de história única, gerada, com imagens embutidas (22 MB); não serve de landing. |

## Consequências

- **Positivas:** o site nunca desatualiza em relação a heróis e roadmap; custo zero de hospedagem; o PI tem um link público para sócios e playtesters.
- **Custos:** um terceiro conjunto de dependências (`site/pnpm-lock.yaml`); `shared/data/heroes/**` e `docs/STATUS.md` passam a disparar o job `site` e o deploy; as imagens `docs/roadmap/img` entram no site (o texto público segue as regras de `docs/roadmap/README.md`).
- **A vigiar:**
  - O site mostra só capturas `tipo: "entregue"`; mockups continuam proibidos como se fossem o jogo.
  - Créditos do rodapé vêm de `historia.json` e não citam a fonte Cinzel (usada no site e na HUD): completar na próxima revisão do roadmap.
  - Pages exige **Settings → Pages → Source: GitHub Actions** (feito em 2026-10-18).
  - Rename "Loot Start" no jogo, se o PI quiser, é card próprio e exige trocar README, Launcher e roadmap.
