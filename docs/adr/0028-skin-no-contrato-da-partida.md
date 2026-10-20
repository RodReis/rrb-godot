# ADR-0028 — Skin visível na partida: o backend informa o visual de cada jogador ao servidor

**Status:** aceito — decisão do PI em 2026-10-19 (aprovação do plano do Cowork; detalhes na SPEC do F91)
**Data:** 2026-10-19
**Decisor:** Rodrigo Reis (PI)
**Emenda:** contrato de validação de token entre game server e backend (F23, `ARCHITECTURE-GAME.md` §6) · `ARCHITECTURE-LAUNCHER.md` §5 (o contrato Launcher ↔ Game não ganha argumento de skin)
**Relacionados:** ADR-0002 · ADR-0025 · ADR-0026 · F23 (#79) · F90 · F91 · F92

## Contexto

O ADR-0025 vende skins. Uma skin precisa aparecer para os dois jogadores da partida, não só para quem comprou. Hoje o Launcher abre o Game com `--connect` e `--token`, e o game server valida o token no backend (F23). Se o Launcher dissesse ao Game qual skin usar, um cliente alterado poderia vestir skin que não possui.

## Decisão

1. **A posse decide no backend.** Na validação do token, o backend devolve ao game server, para cada jogador, a skin equipada de cada herói que ele possui (e, pelo ADR-0026, os heróis liberados).
2. **O game server replica a skin** como dado discreto do jogador (fora do estado de rollback); os dois clientes desenham o visual que o servidor mandou.
3. **O Launcher não passa skin por argumento** nem por `settings.cfg`; ele só grava a escolha de skin no backend.

## Em aberto (decidir na SPEC do F91, com o PI)

- Skin no treino offline: sem backend a posse não é verificável pelo servidor embutido.

## Alternativas descartadas

| Alternativa | Por que não |
|---|---|
| Skin por argumento do Launcher (`--skin=`) | cliente alterado veste skin que não possui; muda o contrato §5.2 sem ganho |
| Skin só local (só quem comprou vê) | o adversário não vê; perde o valor da compra |

## Consequências

- O payload de validação do token (F23) cresce: heróis liberados + skin por herói. Mudança coordenada de backend e game server, com teste dos dois lados.
- Cada skin é um asset em `shared/assets/` carregado pelos dois clientes; o tamanho do pacote cresce a cada skin.
