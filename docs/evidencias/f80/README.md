# F80 — Sair do jogo: evidência (2026-10-19)

Fatia SPEC-080 (issue #230, ADR-0020). Menu no ESC com Continuar / Sair do jogo e derrota por abandono.

## Prova

| O quê | Resultado |
|---|---|
| GUT `game` + `shared` | **1744/1744** (eram 1718) |
| GUT `launcher` + `shared` | **719/719** |
| Backend (`pnpm -C backend test`) | **132/132** (14 suítes) |
| `gdlint`, `gdformat --check` (gdtoolkit 4.x), `no-magic-numbers`, `eslint` do backend | limpos |

Testes novos: `VictoryRules.forfeit` (quem sai perde, vale para qualquer um dos dois, ignora placar e vida,
sem adversário conectado, quem já estava desconectado, peer de fora, uma vaga só); `MatchController.leave_by_menu`
(seleção com o herói padrão para quem não escolheu, INTRO, fase 1, lobby não encerra, duas vezes não encerra de
novo, peer de fora, adversário desconectado só desconecta); `ExitMenu` (12 casos: abrir, Esc com algo na frente,
Esc fecha, confirmar, voltar, texto online × treino, travar ao sair); texto "Abandono" do Launcher; `left` no
serviço de resultado do backend.

## Como funciona

- **Esc** abre o menu se nada está na frente (partida acabada, erro de conexão, outro menu aberto, alvo
  selecionado: o 1º Esc solta o alvo, o 2º abre o menu). O jogo não pausa; enquanto aberto o herói local fica
  parado (`PlayerInput.suspended`, como o Bestiário).
- **Sair do jogo** pede confirmação. Online: "Sair agora conta como derrota por abandono." Treino
  (`--offline`, este processo é o servidor): sai na hora, sem consequência.
- **Online:** o RPC `MatchController.report_leave` vai ao servidor, que decide pelo peer do transporte (nunca
  pelo argumento) e, com os dois conectados, encerra com o adversário vencedor e o motivo `left` (`ENDED`).
  Quem estava na seleção sem escolher fica com o herói padrão do slot: o resultado precisa da linha dos dois.
  O cliente que saiu encerra com código 0 ao receber o fim (ou após 3 s sem resposta).
- **Backend:** nenhuma mudança. O `endReason` já era texto livre, guardado e devolvido; o Game manda `left`. O
  Launcher mostra "Abandono".

## Capturas

`exit-menu-menu.webp` e `exit-menu-confirmacao-online.webp`: o menu por cima da seleção de heróis (1920×1080).
Vitrine: `tools/ui/exit_menu_showcase.gd`.

## Não coberto (`not_run`)

- Fluxo de ponta a ponta com **2 clientes** (um sai, o outro vê a vitória) e o **card do Launcher** com a
  derrota por abandono: com o servidor sem backend o resultado não é reportado; validar contra o backend e o
  pool exige a partida real (PI / VPS depois do deploy).
- Fechar a janela, Alt+F4, queda de conexão e crash **não** viram abandono (lacuna aceita no ADR-0020).
