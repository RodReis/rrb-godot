# ITCH.md — Página do Loot Start no itch.io

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

## 4. Capturas (até 5; escolha do Code, o PI aprova)

Todas já versionadas, em WebP; o itch.io aceita PNG, JPG e GIF, então converta antes de subir (ex.: `magick entrada.webp saida.png`).

1. `docs/roadmap/img/mvp3-f82-loot-start-login.webp` — Launcher: marca e os 10 heróis.
2. `docs/roadmap/img/mvp4-ajustes-base-fase1.webp` — preparação: pátio da base, HUD, minimapa.
3. `docs/roadmap/img/mvp2.8-f77-ocultista-circulo.webp` — herói em ação (Ocultista) na preparação.
4. `docs/roadmap/img/mvp2.5-f57-hud-moderna.webp` — confronto: zona fechando, placar, HUD.
5. `docs/roadmap/img/mvp4-ajustes-carrasco-fase2.webp` — confronto à noite, o Carrasco em chamas.

Limites: a 4 é de antes dos ajustes de arte recentes; a 2 e a 5 são as mais atuais. Não há captura atual da seleção de heróis (a mais recente, `mvp2.7-f71-tela-herois.webp`, mostra 6 heróis e a marca antiga "ARENA 1V1"); se o PI quiser uma, o Code tira numa verificação visual.
