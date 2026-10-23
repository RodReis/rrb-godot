# ADR-0033 — Web-admin (`admin/`) e telemetria de partida no backend

**Status:** aceito. Decisão do PI em 2026-10-23, em pop-ups da especificação do F29 (SPEC-029).
**Decisor:** Rodrigo Reis (PI)
**Emenda:** ADR-0002 (módulos independentes): acrescenta o módulo `admin/`, ao lado do `site/` (ADR-0017). Contrato Launcher ↔ Game não muda.
**Relacionados:** F29 (#253) · ADR-0001 (medição de salto) · ADR-0017 · `ARCHITECTURE-LAUNCHER.md` §4

## Contexto

O critério de sucesso do M4 (PRD §9.2) pede medir ping, duração, vantagem do líder de nível e teleportes. O backend já tem as colunas de ping e nível, mas o Game não as envia. O PI quer ver tudo num painel do jogo, não em script.

## Decisão

1. **Módulo novo `admin/`** (React 19 + Vite + TypeScript), servido pelo próprio backend em `/admin-ui`. Sem código compartilhado com Game, Launcher ou `site/`; fala só com a API.
2. **Papel `admin`:** coluna `users.role` (`player` por padrão). Promoção só por seed na subida do backend, com `ADMIN_EMAILS`. Sem endpoint de promoção. O `AdminGuard` confere o papel no banco a cada chamada.
3. **Endpoints `/admin/*`** (KPIs, lista de partidas, CSV) só para `admin`. Nunca expõem e-mail, hash, token ou id de conta.
4. **Fonte dos dados:** servidor autoritativo para ping, duração e nível ao fim da fase 1. O cliente envia apenas `teleportCount`, tratado como dado não confiável.
5. **Teleporte** é salto visual acima de um limite (provisório 1,0 u), medido no cliente e guardado em `.tres` em `shared/data/`.

## Consequências

- Passa a existir uma superfície web autenticada, com administração de acesso fora da interface (por variável de ambiente).
- Pasta nova no monorepo; CI ganha o build e os testes do `admin/`.
- `match_players.teleport_count` e `users.role` entram por migration 0005.
- Não há decisão aqui sobre consentimento ou política de dados de jogador: o PI não as passou.
