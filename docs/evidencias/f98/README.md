# F98 / SPEC-098 — Carrasco, 11º herói (Tanque)

Evidência de aceite (issue #248, ADR-0032). Modelo do Tripo com rig e animações do Mixamo, kit completo no servidor, VFX, HUD e bot.

## Testes (aceite 1 e 7)

Suítes completas na branch `feat/f98-carrasco`:

| Suíte | Resultado |
|---|---|
| Game + shared (`tools/test.ps1 -Module game`) | 1.873/1.873 |
| Launcher + shared (`tools/test.ps1 -Module launcher`) | 781/781 |
| Backend (`pnpm -C backend test`) | 143/143 |
| `gdlint` / `gdformat --check` nos 48 `.gd` tocados | sem problemas |

Testes novos do Carrasco: `test_carrasco_data` (8), `test_carrasco_rules` (11), `test_carrasco` (10), `test_carrasco_thorns` (8), `test_carrasco_penance` (7), `test_carrasco_chains` (9), `test_carrasco_bot` (6), `test_carrasco_vfx` (15), além de casos novos em `test_hero_plate`, `test_hero_select`, `test_item_visuals` e `test_alignment`. Cobrem:

- Couraça só no básico de herói;
- ganho, teto e expiração da Dor;
- raiz × lentidão pela Dor;
- recast e recarga do Q;
- cancelamento da Penitência por atordoamento;
- execução abaixo de 25 % dentro da luz, bloqueada pela Bênção e valendo sob o Ragnarök.

## Soak (aceite 2)

`tools/soak.ps1 -Count 50 -Parallel 8 -Require carrasco` (relatórios em `soak/`):

- **50/50 terminadas, 0 falhas.** Todas terminaram por kill_goal, em 371–484 s (média 416 s). Lado A venceu 24 e lado B, 26.
- Uso pelo bot: Q 473, E 374, R 97 (logs das partidas).
- **Taxa de vitória para o F30:** o Carrasco venceu **34 de 46 partidas fora do espelho (74 %)**. Perdeu 4 para o Arqueiro, 4 para o Protetor da Selva e 4 para o Berserker. Chega aos 5:00 no nível 5,1 em média. Os números são os do GDB §4.11 (proposta aprovada pelo PI, a conferir no soak); o ajuste fica no F30.

## Rede (aceite 3, ADR-0006 item 7)

`tools/net-measure.ps1 -DelayMs 100 -BothBots -Heroes carrasco,<outro> -Level 6 -StartTime 240 -Minutes 3`: servidor em Docker com netem, os dois clientes no bot.

| Confronto | Conexões | `past the history limit` | `Node not found` / `Reference tick missing` / ERROR | Checkpoints iguais ao servidor | Banda do servidor (envio) |
|---|---|---|---|---|---|
| Carrasco × Cavaleiro | 3/3 | 0 | 0 / 0 / 0 | 17 e 17 (1 sem par no fim) | 232 kbit/s |
| Carrasco × Berserker | 3/3 | 0 | 0 / 0 / 0 | 17 e 18 (1)* | — |
| Carrasco × Paladino | 3/3 | 0 | 0 / 0 / 0 | 18 e 18 | 240 kbit/s |

Os três confrontos tiveram 0 estado recebido com o servidor dizendo "escondido" (neblina).

\* O checkpoint diferente é o primeiro (tick 270): o cliente 1 ainda não tinha os monstros no começo da sessão (`?` em todos). Não é dessincronia. Nas outras rodadas o mesmo efeito aparece como "sem par". A banda dessa rodada não ficou registrada.

## Frame time (aceite 4)

`tools/perf/frametime_probe.gd` em 1920x1080 (RTX 5060, Vulkan, vsync desligado), seed 98, com 3 rodadas alternadas na mesma build:

- **base:** Cavaleiro × Cavaleiro (`--bot-hero=knight`);
- **Carrasco:** Carrasco × Carrasco (`--bot-hero=carrasco --carrasco`), com Dor no máximo, a Penitência canalizando e a coluna de luz acesa no outro herói a medição inteira.

| | GPU média (ms) | GPU p99 (ms) |
|---|---|---|
| Base | 4,076 / 4,536 / 4,398 → **4,337** | 4,852 / 4,935 / 4,865 |
| Carrasco | 4,663 / 4,662 / 4,550 → **4,625** | 5,336 / 5,120 / 5,081 |

O delta é **+0,29 ms** de GPU, abaixo do teto de +4 ms do ADR-0006 item 7. A CPU fica em 16,7 ms nos dois casos, presa nos 60 quadros por segundo, como no F96. O orçamento do modelo é de 5.992 triângulos: corpo 5.103, espada 455 e escudo 434. Texturas: 2K no corpo e 1K nas armas.

JSONs: `frametime-base-<n>.json` e `frametime-carrasco-<n>.json`. Capturas da sonda: `frametime-carrasco-<n>.webp`.

## Capturas (aceite 6)

| Arquivo | O que mostra |
|---|---|
| `retrato.webp` | retrato de 512 px da Tela Heróis (render do modelo) |
| `vfx-folha.webp` | VFX de perto: espinhos do Q, aro da Penitência, explosão com raiz, coluna de luz e correntes em voo |
| `frametime-carrasco-2.webp` | partida com a coluna de luz e o medidor de Dor cheio na HUD |
| `../../roadmap/img/mvp4-f98-carrasco-kit.webm` | kit na câmera do jogo (Movie Maker do `vfx_showcase.gd`, só o viewport) |

## Ajustes da verificação visual do PI (2026-10-21)

| Pedido do PI | Ajuste |
|---|---|
| Corrida "meio agachada" | Coluna da `Run` endireitada no Blender: inclinação quadril→pescoço de 37° para 18° (idle: 13°), pescoço compensado para a cabeça seguir olhando para a frente |
| Atraso entre o clique e o golpe | `Attack_Basic` sem os 18 quadros de preparação: o pico da espada sai 0,15 s depois do clique (antes, 0,48 s; Cavaleiro, 0,25 s) |
| Pequeno perto do Cavaleiro | Modelo na escala 1,2 na cena do herói (topo da cabeça a 2,04 u), barra de HP e enquadramento da seleção acompanham |
| R não acerta boss nem monstros | Comportamento da SPEC-098 §2: as Correntes só param em herói; monstro e boss não são alvo (passa direto) |
