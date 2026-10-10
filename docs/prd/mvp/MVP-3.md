# MVP3 — Meta + deploy (= marco M3)

**Objetivo:** dois amigos jogam pela internet sem intervenção do dev: criam conta, entram na fila, o launcher abre o jogo, a partida roda num servidor do pool no VPS, o resultado aparece no histórico.
**Módulos:** `backend`, `launcher`, `game`, `infra`, `shared`. **Prazo PRD:** 3 semanas. O bloco visual (F38–F43) saiu daqui para o **MVP2.5** (`MVP-2.5.md`), que vem antes.
**Critério de pronto:** o cenário acima executado por duas pessoas externas, do zero, só com o pacote de instalação.

## Fatias

| Slice | F / SPEC | Entrega | Fontes |
|---|---|---|---|
| 3.1 | F21 / SPEC-021 | backend: auth (senha: mín. 8, letra e número), usuários, migrações, OpenAPI | PRD §8.4; `ARCHITECTURE-LAUNCHER.md` §4 |
| 3.2 | F22 / SPEC-022 | fila FIFO, orquestrador (pool, token, heartbeat) | PRD §8.4 |
| 3.3 | F23 / SPEC-023 | game server: validar token, reportar resultado, códigos de saída | `ARCHITECTURE-GAME.md` §6; `ARCHITECTURE-LAUNCHER.md` §5 |
| 3.4 | F24 / SPEC-024 | shell do launcher, Theme completo, galeria, configurações com aba **Créditos** (CC-BY do Golem), `settings.cfg` | `FRONTEND-LAUNCHER.md`; `design-system/`; DV tela 8 |
| 3.5 | F25 / SPEC-025 | login e cadastro, lobby, fila, lançar o Game, treino vs bot | DV tela 1 |
| 3.6 | F26 / SPEC-026 | histórico; "VS INIMIGO" = herói do oponente (F35 acrescenta o `#nickname`) | DV tela 9; decisão PI 2026-10-10 |
| 3.7 | F27 / SPEC-027 | bestiário e forja | DV telas 5, 6 |
| 3.8 | F28 / SPEC-028 | deploy VPS, exports, pacote ZIP portátil em GitHub Release | PRD §8.5; decisão PI 2026-10-10 |
| 3.9 | F33 / SPEC-033 | tela Arena & Mapa: render da arena real, marcadores, regras das 2 fases (números do GDB) | DV tela 10; SPEC-007; decisão PI 2026-10-09 |
| 3.10 | F35 / SPEC-035 | perfil de conta (`launcher`, `backend`): nickname obrigatório no 1º login, 3–16 `A–Z a–z 0–9 _`, único sem diferenciar maiúsculas, prefixo `#` só de exibição; avatar predefinido ou upload PNG/JPG ≤ 1 MB recortado 256×256, só local; sem XP de conta, sem data de nascimento | R-PEND-02 (`RASTREABILIDADE.md` §5) |
| gate | `[GATE]` | dois amigos jogam pela internet | PRD §9.1 |

## Ordem e issues

Issue-pai **#76**. Ordem: F21 #77 → F22 #78 → F23 #79 → F24 #80 → F25 #81 → **F28 #82** → F26 #83 → F27 #84 → F33 #85 → F35 #86 → [GATE] #87. O deploy vem logo depois do fluxo mínimo (conta + fila + jogo) para expor cedo o risco de UDP no VPS; as telas secundárias vêm depois.

**Herança do MVP2.5 (ADR-0006, revisão de 2026-10-10):** o MVP3 começa com o bloco visual já entregue. O F24 nasce no design system v2 (fontes e molduras do F43) e consome as chaves gráficas do `settings.cfg` definidas no F38; o F33 renderiza a ilha pronta (F40). Se o MVP2.5 não estiver fechado, F24 e F33 ficam bloqueados nesses pontos.

## Decisões do PI em 2026-10-10

- **Senha:** mínimo 8 caracteres, com pelo menos uma letra e um número.
- **Histórico:** "VS INIMIGO" mostra o herói do oponente; o F35 acrescenta o `#nickname`. E-mail de outra conta nunca aparece.
- **Nickname (F35):** obrigatório no 1º login, antes do lobby; 3–16 caracteres `A–Z a–z 0–9 _`; único sem diferenciar maiúsculas; prefixo `#` só de exibição. F35 vira `launcher, backend` e **entra no gate**.
- **Avatar (F35):** predefinido ou upload PNG/JPG ≤ 1 MB, recortado 256×256, só local.
- **Pacote (F28):** ZIP portátil publicado em GitHub Release (repo público).
- **Créditos CC-BY:** aba Créditos em Configurações (F24).

## Pendências do PI

Decididas em 2026-10-09: R-PEND-03 não (sem persistência de sessão); R-PEND-07 roadmap (F21 sem recuperação nem verificação de e-mail). R-PEND-02: sem XP de conta; perfil com nickname único e avatar vira a fatia F35 (fora do F25). Sem data de nascimento. Fechada em 2026-10-10 (regras acima). R-PEND-14 (fontes do design system v2, ADR-0006) — trava o F43 (MVP2.5); o F24 herda.

## Fora deste MVP

Telemetria/KPIs (MVP4), Steam, ranked, economia.
