# STATUS-ARQUIVO.md — Histórico detalhado

Complementa `STATUS.md`: prosa longa, decisões de rota, fatias canceladas, resultados de gate. Ordem cronológica inversa.

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
