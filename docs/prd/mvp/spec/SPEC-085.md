# SPEC-085 — Tutorial guiado: obrigatório na 1ª vez, pulável, libera a fila online

**Fatia:** F85 / SPEC-085 (MVP4, Slice 4.4) · **Issue:** #251 (issue-pai #246) · **Status:** decidida pelo PI em 2026-10-19 (pop-ups do Cowork: "6 passos completos"; "Cavaleiro fixo"; "Na conta, no backend"; "Qualquer nível"; "Arena real, roteirizada"; "Após o nickname; pular vai ao lobby"; "Recomeça do início"; "Liberadas se já jogaram online"; "Arquivo de resultado")
**ADR:** ADR-0026 itens 5–6 · ADR-0029 (contrato) · ADR-0027 (nível do bot)
**Fontes:** F31/F45/F66/F67 (câmera e controle), F61 (baú com menu), F62 (ficha `B`), F16/F17 (fase 2), F35 (nickname no 1º login), F25 (lobby, fila, treino), F81 (#239, níveis do bot) · `ARCHITECTURE-LAUNCHER.md` §5 · `ARCHITECTURE-GAME.md` (modo offline)
**Escopo:** Game (modo tutorial), Launcher (abertura, bloqueio da fila, leitura do resultado), backend (fila liberada na conta). Números de herói, itens e regras da partida não mudam.

## 1. Motivo

Hoje o jogador novo cai direto na partida. O PI decidiu um tutorial obrigatório na primeira vez, que pode ser pulado, e que a fila online só libere depois do tutorial ou de uma vitória contra o bot (ADR-0026).

## 2. Tutorial (Game)

- Abre com `game.exe -- --offline --tutorial` (ADR-0029). **Herói fixo: Cavaleiro.** Arena real, regras reais, servidor embutido.
- **6 passos, nesta ordem**, cada um com instrução na tela e avanço quando o jogador faz a ação:
  1. **Mover e câmera:** andar, girar a câmera, zoom.
  2. **Alvo e auto-ataque:** travar um alvo e atacar.
  3. **Habilidades:** usar Q, E e R (o roteiro garante o nível necessário para o R).
  4. **Monstro e XP:** matar um monstro, subir de nível e gastar o ponto.
  5. **Baú e ficha:** abrir um baú com `F`, escolher um item; abrir a ficha com `B`.
  6. **Fase 2:** a zona fecha; um bot Fácil (nível 1 do ADR-0027) entra; vencer termina o tutorial.
- O roteiro só ordena eventos e mostra instruções (monstro perto, baú marcado, relógio adiantado); não muda números.
- Duração-alvo ≤ 5 min.
- **Pular** a qualquer momento (botão na tela + confirmação): fecha o Game com `outcome=quit`.
- **Sair no meio** recomeça do início na próxima vez; nenhum passo é salvo.
- Fim: grava `user://offline_result.cfg` com `kind=tutorial`, `outcome=completed` (ou `quit`).

## 3. Treino contra bot (Game)

- Ao fim de todo treino (`--offline --bot`), o Game grava `kind=bot`, `outcome=win|loss|quit`, `bot_difficulty=<n>` (ADR-0029). Qualquer nível conta como vitória para liberar a fila.

## 4. Launcher

- **1º login:** depois do nickname (F35), o Launcher abre o tutorial uma vez. Ao pular ou terminar, volta ao lobby.
- **Lobby:** botão **Tutorial** sempre disponível para refazer.
- **Fila bloqueada** enquanto a conta não tiver a fila liberada: o botão de fila mostra o motivo e oferece "Fazer tutorial" ou "Treinar contra bot".
- Ao fim do processo do Game, lê e apaga `offline_result.cfg`; se `tutorial/completed` ou `bot/win`, envia ao backend e atualiza o lobby. Sem sessão (treino pela tela de Login): não envia.
- Telas e mensagens seguem o design system (`FRONTEND-LAUNCHER.md`); o bloqueio cabe no card de fila existente, sem tela nova.

## 5. Backend

- A conta guarda se a fila está liberada e por qual motivo (`tutorial` ou `bot_win`).
- Endpoint autenticado para o Launcher registrar a liberação.
- A entrada na fila **recusa** conta sem fila liberada (garantia no servidor, como o `426` do ADR-0023); o Launcher só espelha.
- **Contas existentes:** quem já tem partida online no histórico fica com a fila liberada (migração); as outras seguem a regra nova.

## 6. Critério de aceite

1. Testes GUT: parse de `--tutorial`; gravação e leitura de `offline_result.cfg` (`shared/core`, nos dois projetos); avanço dos 6 passos como regra pura onde couber.
2. Testes do backend: registrar liberação; fila recusa conta bloqueada; migração libera quem tem histórico.
3. Teste do Launcher: 1º login abre o tutorial; fila bloqueada mostra o motivo; resultado lido e enviado; sem sessão não envia.
4. Soak curto (`soak.ps1 -Count 10`) verde: o treino normal não regride.
5. **Verificação do PI**: tutorial completo do 1º login até o lobby com a fila liberada; pular e liberar por vitória contra bot Fácil.
6. Capturas no roadmap. CI verde.

## 7. Fora

Tutorial por herói, tutorial online, recompensa por concluir, salvar passo, separar fila por Patente (F87).
