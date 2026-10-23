# ITCH.md — Página do Loot Start no itch.io

**No ar (2026-10-23):** página https://rodreisb.itch.io/loot-start, em **Restricted** (acesso por senha); canal `windows` com o `v0.4.0` (primeiro Release com o job `itch`, run `39883625301`). Site do jogo: https://lootstart.cloud/ (ver `docs/SITE.md`).

Publicação do canal itch.io (ADR-0024 item 2, SPEC-086, F86). O texto da §2 foi aprovado pelo PI em 2026-10-22 (SPEC-086 §4) e é a cópia para colar no painel do itch. Quem cola é o PI; o Code não configura a página.

## 1. Como funciona

- A cada tag `v*`, o `release.yml` gera o ZIP portátil do canal `itch` (`tools/build-package.ps1 -Channel itch`) e o job `itch` o envia com o **butler** para `$ITCH_TARGET:windows` (`--userversion` = tag). O job é separado: se falhar, o GitHub Release e o envio ao VPS ficam como estão, e ele pode ser executado de novo sozinho (Actions > release > Re-run failed jobs).
- No canal `itch` o `build_config.cfg` do pacote leva `channel="itch"` e `update_url=""`: o Launcher não checa nem baixa o Setup. Versão velha barrada pelo backend (`426`) mostra "Atualize pelo app do itch.io".
- `workflow_dispatch` (ensaio) gera o ZIP do itch como artefato do run e **não** envia.

## 2. Pré-condições do PI (SPEC-086 §2)

1. Conta e projeto no itch.io: "Downloadable", Windows, **grátis**.
2. Página em **Restricted** (acesso por senha) até o PI abrir o playtest.
3. Settings > Secrets do repositório: `BUTLER_API_KEY` (API key do itch.io).
4. Settings > Variables: `ITCH_TARGET` = `usuario/projeto` (slug da página).

Sem `BUTLER_API_KEY` ou `ITCH_TARGET`, o job `itch` falha com erro explícito.

## 3. Texto da página

- **Título:** Loot Start
- **Resumo (uma linha):** MOBA 3D de dois tempos: 5 minutos de preparação e depois a luta dentro de uma zona que fecha.
- **Descrição:**
  - Partida em dois tempos. Na preparação você abre baús, enfrenta monstros e monta seu herói. No confronto, uma zona fecha o mapa e o último time de pé vence.
  - 10 heróis jogáveis: Cavaleiro, Arqueiro, Bárbaro, Bruxo de Fogo, Ladina, Engenheiro, Protetor da Selva, Berserker, Paladino Radiante e Ocultista.
  - Partidas online pela fila, com servidor autoritativo. Treino contra bot, sem fila.
  - Windows. Precisa de conta (e-mail e senha) e de internet para jogar online.
  - Em playtest: o jogo muda entre versões e o app do itch.io atualiza sozinho.
  - Aviso do Windows (SmartScreen): o executável não tem assinatura de código. Clique em **Mais informações** e depois em **Executar assim mesmo**.
- **Gênero e tags:** Action, Strategy; moba, multiplayer, pvp, 3d, fantasy.
- **Preço:** grátis.
- **Canal do upload:** `windows` (o butler cria sozinho no primeiro envio).

## 4. Capturas (tiradas em 2026-10-23, jogo e Launcher atuais)

Versionadas em `docs/evidencias/f86/` (WebP; o itch.io aceita PNG, JPG e GIF, então converta antes de subir, ex.: `magick entrada.webp saida.png`). Geradas por `tools/perf/frametime_probe.gd --shot=` (só o viewport, 1920×1080, com `--bot-hero=<id>` para o herói) e `tools/ui/capture_launcher.gd`. Todas são da fase de preparação: a sonda só mede essa fase.

1. `01-arena-castelo-vista-aerea.webp` — base com o castelo e o pátio (`--intro`).
2. `02-preparacao-paladino.webp` — Paladino Radiante no pátio (`--bot-hero=paladin --paladin`).
3. `03-carrasco-centro.webp` — Carrasco, o 11º herói, no centro com a Dor e a luz das Correntes (`--bot-hero=carrasco --carrasco --at=0,0`).
4. `04-berserker.webp` — Berserker em chamas (`--bot-hero=berserker --berserker`).
5. `05-launcher-11-herois.webp` — login do Launcher com os 11 heróis.

Capa (630×500): `capa-630x500.webp`, recorte central da 1. Alternativas (prefixo `extra-`): heróis do Launcher, Ocultista e Cavaleiro na cratera.

## 5. Metadados da página (painel do itch.io)

Classificação: Keyboard e Mouse; sessão "A few minutes"; "Server-based networked multiplayer"; jogadores mín. 1 (treino contra o bot) e máx. 2 (duelo 1v1); idioma Portuguese (Brazil); acessibilidade e conteúdo sensível sem declarar nada. Licenças, data de lançamento, publisher, links externos e imagens promocionais ficam em branco/"No license" até decisão do PI.

## 6. Divergências do texto aprovado (aguardam o PI)

O texto da §3 é o aprovado na SPEC-086 §4 e não foi alterado. Duas coisas já não batem com o jogo:

- "**10** heróis jogáveis" e a lista sem o Carrasco: o jogo tem 11 heróis desde o F98.
- "o último **time** de pé vence": o jogo é duelo 1v1.
