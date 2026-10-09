# MVP3 — Meta + deploy (= marco M3)

**Objetivo:** dois amigos jogam pela internet sem intervenção do dev: criam conta, entram na fila, o launcher abre o jogo, a partida roda num servidor do pool no VPS, o resultado aparece no histórico.
**Módulos:** `backend`, `launcher`, `game`, `infra`, `shared`. **Prazo PRD:** 3 semanas.
**Critério de pronto:** o cenário acima executado por duas pessoas externas, do zero, só com o pacote de instalação.

## Fatias

| Slice | F / SPEC | Entrega | Fontes |
|---|---|---|---|
| 3.1 | F21 / SPEC-021 | backend: auth, usuários, migrações, OpenAPI | PRD §8.4; `ARCHITECTURE-LAUNCHER.md` §4 |
| 3.2 | F22 / SPEC-022 | fila FIFO, orquestrador (pool, token, heartbeat) | PRD §8.4 |
| 3.3 | F23 / SPEC-023 | game server: validar token, reportar resultado, códigos de saída | `ARCHITECTURE-GAME.md` §6; `ARCHITECTURE-LAUNCHER.md` §5 |
| 3.4 | F24 / SPEC-024 | shell do launcher, Theme completo, galeria, configurações, `settings.cfg` | `FRONTEND-LAUNCHER.md`; `design-system/`; DV tela 8 |
| 3.5 | F25 / SPEC-025 | login, lobby, fila, lançar o Game, treino vs bot | DV tela 1 |
| 3.6 | F26 / SPEC-026 | histórico | DV tela 9 |
| 3.7 | F27 / SPEC-027 | bestiário e forja | DV telas 5, 6 |
| 3.8 | F28 / SPEC-028 | deploy VPS, exports, pacote de instalação | PRD §8.5 |
| 3.9 | F33 / SPEC-033 | tela Arena & Mapa: render da arena real, marcadores, regras das 2 fases (números do GDB) | DV tela 10; SPEC-007; decisão PI 2026-10-09 |
| gate | `[GATE]` | dois amigos jogam pela internet | PRD §9.1 |

## Pendências do PI

R-PEND-02 (perfil de conta), R-PEND-03 (lembrar-me), R-PEND-07 (recuperação de senha). Sem decisão: F25 sem perfil, sem persistência de sessão; F21 sem recuperação.

## Fora deste MVP

Telemetria/KPIs (MVP4), Steam, ranked, economia.
