# SITE.md — Site público "Loot Start"

Landing page do jogo, em `site/`. Atualizada em 2026-10-19 (autorizada pelo PI) para os 11 heróis, o MVP4 em andamento, a arena nova (F94 a F96) e a vitrine com as capturas dos ajustes de 2026-10-22. **No ar:** https://lootstart.cloud (VPS, desde 2026-10-19, #237; antes GitHub Pages em `rodreis.github.io/rrb-godot`). Download do jogo em https://lootstart.cloud/download/ e roadmap completo em https://lootstart.cloud/roadmap/. Decisão: [ADR-0017](adr/0017-site-publico-loot-start.md). Spec e plano originais: `docs/superpowers/specs/2026-10-18-site-loot-start-design.md` e `docs/superpowers/plans/2026-10-18-site-loot-start.md`.

Não é fatia nem card do board: foi pedido direto pelo PI em 2026-10-18 (PR #218). Desde o F82 (ADR-0022), "Loot Start" é o nome do jogo inteiro, não só do site.

## Stack

Vite 8 + React 19 + TypeScript 7, CSS puro com custom properties, pnpm. Sem Tailwind, sem biblioteca de UI, sem roteador. Fontes do Google Fonts: Cinzel (títulos e logo), Outfit (corpo), JetBrains Mono (rótulos numéricos). Dependência de build: `sharp` (PNG → WebP).

## Estrutura

```text
site/
  index.html  vite.config.ts  tsconfig.json  package.json  pnpm-lock.yaml
  scripts/extract.mjs    gera src/data/*.json e public/{img,icons} a partir do monorepo
  scripts/tres.mjs       parser mínimo de .tres (HeroData); teste em tres.test.mjs
  public/favicon.svg
  src/main.tsx  src/App.tsx  src/data.ts   data.ts tipa e importa os JSON gerados
  src/brand/Logo.tsx     logo (ícone + wordmark), variantes horizontal e empilhada
  src/styles/            tokens.css (TOKENS.md §1) e global.css (base, .glass, .btn, .reveal)
  src/hooks/useReveal.ts entrada por IntersectionObserver
  src/components/        Nav, Hero, HowItWorks, Heroes, Arena, Gallery, Roadmap, Footer (+ .css)
```

`src/data/`, `public/img/`, `public/icons/` e `dist/` são gerados e ficam no `.gitignore`.

## De onde vem cada dado

| No site | Fonte | Observação |
|---|---|---|
| Heróis: nome, papel, arma, resumo, Q/E/R | `shared/data/heroes/*.tres` | cresce sozinho quando entra herói novo; hoje são 11 |
| Ordem dos heróis na seção | pilar "Heróis" de `historia.json` (ordem de lançamento) | herói fora da lista vai para o fim e o `extract` avisa |
| Ícones de habilidade | `shared/ui/icons/*.svg` | copiados para `public/icons` |
| Retrato de cada herói | `shared/assets/ui/heroes/large/<id>.png` | WebP 384 px |
| Fundos (arena dia, arena noite, lineup) e mapa de cima | `shared/assets/ui/loading/*.png`, `shared/assets/ui/arena_map.png` | WebP ≤ 1920 px |
| Linha do tempo, regras, bestiário, créditos, tagline | `docs/roadmap/historia.json` | texto público: regras de `docs/roadmap/README.md` |
| Galeria | `historia.json` → `capitulos.*.imagens` com o campo `vitrine` (legenda do site) + `docs/roadmap/img/` | no máximo 10 (o `extract` falha acima disso), escolhidas para mostrar o jogo; o roadmap longo segue com todas |
| Roadmap por MVP (estado e entregas) | `docs/STATUS.md` §2/§3 + `.proplan/STATUS.md` | `tools/roadmap/status.mjs`; Issues vencem o STATUS |
| Link de download | `historia.json` → `projeto.release_url` | sem ele: Releases do repo + "em breve" |

## Comandos

| O quê | Comando |
|---|---|
| Instalar (uma vez) | `pnpm -C site install` |
| Desenvolver | `pnpm -C site dev` (extrai e abre `http://localhost:5173`) |
| Testes | `pnpm -C site test` e `node --test tools/roadmap/build-roadmap.test.mjs` |
| Build de produção | `pnpm -C site build` (extrai, `tsc --noEmit`, `vite build`) |
| Ver o build | `pnpm -C site exec vite preview --port 4173` → `http://localhost:4173/` |
| Imagem do VPS | `docker build -f site/Dockerfile -t rrb-site .` (da raiz; contexto em `site/Dockerfile.dockerignore`) |

O `base` é `/` (site na raiz do domínio); `SITE_BASE` troca, se o site voltar a um subcaminho.

## Publicação e CI

- **Deploy (VPS, #237):** serviço `site` do `infra/docker-compose.prod.yml` no Coolify (domínio `https://lootstart.cloud`, porta 80). `site/Dockerfile` constrói da raiz do repo (o extract lê `shared/` e `docs/`) e serve com nginx (`site/nginx.conf`): o site, `/download/` (pasta do host `/srv/rrb-download`, só leitura) e `/roadmap/` (`docs/roadmap/index.html`). Atualiza a cada Redeploy do recurso. O workflow `site.yml` (GitHub Pages) saiu: o repositório é privado.
- **Download (F83, ADR-0023):** só o instalador. O `release.yml` envia `LootStart-Setup-<tag>.exe` para `/srv/rrb-download` (usuário `rrbdl`, só upload; segredo `VPS_UPLOAD_KEY`; chave do host em `infra/known_hosts`), aponta `LootStart-Setup.exe` para ele e publica o `latest.json` do Launcher. O botão "Baixar" usa `historia.json` → `projeto.release_url` (`.../download/LootStart-Setup.exe`).
- **Links para o GitHub** ("Ver no GitHub", "Código no GitHub", roadmap no repo) saíram: o repo é privado.
- **CI:** job `site` em `ci.yml` (path filter `site`), com `pnpm test`, o teste do parser de STATUS e `pnpm build`; entra no `needs` do `gate`. `pnpm/action-setup` exige `packageManager` no `site/package.json`.

## Marca e estilo

- **Logo:** `Logo.tsx` (SVG inline) e `public/favicon.svg`. Baú aberto, com um "play" subindo do interior (loot + start); ouro + `TEXT`. Wordmark "LOOT START" em Cinzel 900, caixa alta, gradiente `GOLD_BRIGHT` → `GOLD`.
- **Tokens:** os de `TOKENS.md` §1 em `tokens.css`. Painel "vidro" (`.glass`) = `PanelCardGlass` da HUD (`BG_PANEL` 85 %, borda `GOLD` 35 %, cantoneiras 8×2 px). Botão primário: ouro, texto `ON_GOLD`, borda 3D `GOLD_EDGE`.
- **Hero:** arena à noite com o véu roxo do splash do Launcher e neblina em duas camadas. O `splash.png` do Launcher (marca "Loot Start" desde o F82) não é usado no hero.
- **Movimento:** entrada por `IntersectionObserver` e neblina por `transform`; tudo cai para estático em `prefers-reduced-motion`.
- **Acessibilidade:** landmarks, `h1` único, foco dourado visível, lightbox em `<dialog>` com setas e Esc, sem rolagem horizontal em 375 px.

## Como mexer

- **Novo herói:** nada no código do site. Entrando em `shared/data/heroes`, ícones e retrato (`shared/ui/icons/<id>_{q,e,r}.svg`, `shared/assets/ui/heroes/large/<id>.png`), o próximo build o mostra. Sem retrato, o card sai sem imagem e o `extract` avisa. Para ele sair na ordem de lançamento, acrescente-o ao fim do pilar "Heróis" de `docs/roadmap/historia.json` (nome igual ao `display_name`); se faltar, ele aparece por último.
- **Arena:** as duas imagens da seção são 16:9 em colunas iguais (`Arena.css`, quadros esticados para a mesma altura: simetria); dia e noite vêm de `shared/assets/ui/loading/arena_{day,night}.png` e o mapa de `shared/assets/ui/arena_map.png`, então regere-os (`tools/ui/render_loading.gd`, `tools/ui/render_arena_map.gd`) quando a arena mudar. O texto da seção (`Arena.tsx`) descreve o mapa à mão (80 × 80 m, castelos em cantos opostos, rio, pontes, cratera central, mato alto, Rei Esqueleto aos 3:30). Se a arena mudar, revisar esse texto e o `shared/assets/ui/arena_map.png`.
- **Nova seção:** componente em `src/components/`, tipos em `src/data.ts`, entrada em `App.tsx` e âncora na `Nav`. Dado novo vem do `extract.mjs`, não de texto à mão.
- **Texto público:** edita-se `docs/roadmap/historia.json`; vale para o site e para o roadmap longo.

## Pendências conhecidas

- Rename do jogo para "Loot Start" (Launcher, README, roadmap): decisão do PI, card futuro.
- Créditos do rodapé (`historia.json`) não citam a fonte Cinzel.
- Botão de download sem destino até o primeiro Release (F28, aguarda o VPS do PI). O cartão "1x1 · Disponível agora" do hero (`Hero.tsx`) contradiz o "em breve" do botão até lá: decisão do PI se muda o texto.
- Galeria = vitrine curada (PI, 2026-10-19: "no máximo 10 imagens que mostram o que é o jogo"). Tela do Launcher, antes/depois e captura de arte antiga não entram; para trocar uma, mova o campo `vitrine` em `historia.json`.
- Modos 2x2 e 3x3 só como "em breve" (PRD: pós-M4).
