# STATUS-ARQUIVO.md — Histórico detalhado

Complementa `STATUS.md`: prosa longa, decisões de rota, fatias canceladas, resultados de gate. Ordem cronológica inversa.

## 2026-10-09 — B-02: câmera em 3ª pessoa mantida (F31, #20)

- Avaliação do PI com a cápsula do M0 na arena do F7, servidor + 2 clientes: **mantém a 3ª pessoa**; plano B isométrico (PRD §3.6) segue em `FORA-DE-ESCOPO.md` para o M4.
- Câmera avaliada: atrás e acima do herói a 45°, 14 u, yaw fixo do time (trava olhando o centro a partir do spawn; decisão do PI na mesma data), sem colisão de câmera. Movimento relativo à câmera; mira no mouse ou no analógico direito.
- Observação (sem ação): sem colisão de câmera, os pilares da cratera tapam o herói quando ele está atrás deles — esperado pela PRD §3.6 nesta fatia.
- Escala conferida em `shared/assets/_alignment.tscn`: Cavaleiro 1,92 u com elmo (1,80 sem), esqueleto 1,69 u, cápsula 1,8 u (personagens KayKit a 0,78).

## 2026-10-08 — Governança criada; projeto dividido em dois módulos

- Documentos recebidos do PI: `PRD.md` (v0.1), `GDB.md` (v1.0), `REFER.md` (benchmark), `DESIGN-VISUAL-LAUNCHER.md` (9 telas).
- Decisões do PI (pop-up): launcher em **Godot, projeto separado**; backend NestJS **dentro do módulo Launcher**; Seleção de Heróis e Fim de Partida **no Game**; em divergência numérica **GDB vence**; MVP-n = marco M-n; commit de governança direto na `main`.
- Criados: ADR-0002/0003/0004, `DECISIONS.md`, `ARCHITECTURE-GAME.md`, `ARCHITECTURE-LAUNCHER.md`, `CONVENTION.md`, `RASTREABILIDADE.md`, `FORA-DE-ESCOPO.md`, `PRIVACIDADE.md`, `FRONTEND-LAUNCHER.md`, `design-system/` (4 + índice), `DEVELOPMENT.md`, `STATUS.md`, `APRENDIZADOS.md`, `PRS.md`, `CI-PR.md`, `docs/prd/mvp/MVP-0..4.md`. Corrigidos: `CLAUDE.md` (estrutura, "interface web" → Godot, caminhos dos PRDs) e `GITHUB.md` (escopos e referências de outro projeto).
- Índice Fatia ↔ SPEC alocado: F1–F30. Plano do M0 (12 tarefas) mapeado em F1–F5 + `[GATE]`; o plano continua sendo o passo a passo.
- Achados que viraram pendência do PI (R-PEND-01…10): épico em baú raro, perfil de conta no lobby, "lembrar-me", herói padrão no timeout de pick, aviso do boss aos 3:00, monstros vivos na fase 2, recuperação de senha, bestiário em partida, Golem × Aranha, renomear `PRD.md`.
- Contraste da paleta do DV medido: `BLUE`, `RED`, `PURPLE` não passam 4,5:1 como texto (DS-04).
- Estado do repo antes desta entrega: starter 2D ainda na raiz, quase tudo sem rastreio (`git status`); a Tarefa 0 do plano M0 faz o snapshot.

## Gates

| Gate | Data | Resultado | ADR |
|---|---|---|---|
| M0 Godot × Unity | 2026-10-09 | **segue Godot** — A e B (100 ms RTT simétrico, 2% perda) com 7/7 OK; C (200 ms, jitter 30, 5%) falhou só no item 2 (informativo); netem passou a simétrico após o B inicial reprovar no item 2 | [0001](adr/0001-gate-m0.md) |
| MVP1 fase 1 contra bot, offline | 2026-10-10 | **aprovado pelo PI** — `--offline --bot`, 5:00 como Cavaleiro: base farmada, 17/17 baús, conjuntos, aviso 3:00 (tick 5400), boss 3:30, fim 5:00 (tick 9000), bestiário por `B` ok; stderr vazio. Lint verde na CI (`no-magic-numbers`); câmera do F31 mantida (B-02, 2026-10-09). Placar aos 5:00: jogador Nv 3 × bot Nv 5. Observações para o PI, sem bloqueio: o boss só caiu depois dos 5:00 (bot Nv 5 sozinho; balanceamento é do F30); o bot entra em `FIGHT` contra o herói, mas PvP chega no F15. [FIX] #52 entrou antes do gate. A gravação da janela saiu preta (gdigrab + Vulkan); as capturas do roadmap são screenshots do PI | — |
| MVP2 partida em rede (#69) | 2026-10-13 | **aprovado pelo PI** — 2 partidas 1×1 reais (2 clientes + servidor, Docker com netem 100 ms/2 % de perda) na arena do F46, pick → fase 1 → transição → fase 2 → fim por morte súbita; PI conferiu laterais e respawn, pontes, mato alto, neblina, zona, HUD da fase 2, tela de fim, baú e card (F47), equipamento visível (F48) e dia/noite (F49) e disse "falta só o soak" (2026-10-12). Soak local de 50 partidas bot × bot (`tools/soak.ps1 -Count 50 -Parallel 8`, 4 heróis com espelhos): **50/50 terminadas, todas com vencedor (`kill_goal`), mín 362 s, média 396 s, máx 489 s (limite 600 s), 0 `ERROR`/`SCRIPT ERROR` nos logs**; lados A 22 × B 28; nível aos 5:00: Cavaleiro 5,3, Arqueira 5,0, Bárbaro 5,6, Bruxo 4,4. Rede (2 bots, 100 ms, 2 %, 9 min): checkpoints de monstros/baús 54/54 nos dois clientes, servidor 234 kbit/s enviados e 207 kbit/s recebidos, 0 `Node not found`. **Risco "remoto parado" (meta ≤ 20 %): medido 24 % e 39 %, registrado como inconclusivo por decisão do PI (2026-10-12); medição fina fica para o MVP3.** Bugs achados nas partidas do PI e corrigidos antes do aceite: [FIX] #148 (sonda lia `?` nos monstros), #153/#155 (Concealment com `SCRIPT ERROR` ao fim da partida), #154 (aviso de habilidade a aprender). F57 (HUD moderna) entrou antes do gate. Observação: as duas primeiras tentativas do PI em 2026-10-12 20:04 e 20:14 não foram jogadas (herói parado, morte súbita aos 9:00); valem as partidas da verificação do F57. | — |
