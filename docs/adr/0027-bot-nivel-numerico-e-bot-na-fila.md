# ADR-0027 — Nível do bot numérico e bot completando a fila online

**Status:** aceito — decisão do PI em 2026-10-19 (pop-up do Cowork)
**Data:** 2026-10-19
**Decisor:** Rodrigo Reis (PI)
**Supera:** ADR-0021 item 1 (formato `easy|medium|hard`) e a consequência "o nível não vale para a fila online (não há bot online)"
**Emenda:** `ARCHITECTURE-LAUNCHER.md` §5.2 (argumentos do contrato Launcher ↔ Game)
**Relacionados:** ADR-0021 · F81 (#239) · F22 (#78, fila e orquestrador) · ADR-0026 · F89

## Contexto

O ADR-0021 fixou `--bot-difficulty=easy|medium|hard`. O PI quer uma escada de bots de dificuldade crescente nas primeiras partidas; com nomes, cada degrau novo mudaria o contrato e exigiria ADR. A #239 ainda está `todo`, então mudar o formato agora não custa código. Num PvP 1x1 com pouca gente, a fila vazia é o maior risco do Early Access (ADR-0024).

## Decisão

1. **Formato numérico:** `--bot-difficulty=<n>`, inteiro de 1 a N, onde N é o número de níveis definidos no Resource de `shared/data/`. Hoje N = 3: **1 = Fácil, 2 = Médio (= bot atual), 3 = Difícil**. Ausente ou fora de 1..N = 2, como o "ausente ou inválido = medium" do ADR-0021. Degrau novo = linha nova no Resource, sem ADR.
2. Os itens 2 a 4 do ADR-0021 (Médio = bot de hoje, parâmetros em Resource, escolha no card Treino vs Bot) continuam valendo.
3. **Bot na fila online:** se a fila não encontrar adversário humano em **30 s**, a partida começa contra um bot no servidor do VPS, e o jogador **é avisado** de que o adversário é bot.

## Em aberto (decidir na SPEC do F89, com o PI)

- Nível do bot na fila (fixo, pela Patente, ou escolhido).
- Se a partida contra bot entra no histórico, no V–D e no progresso de Patente.
- Como o aviso aparece (na fila, no pick, na HUD).

## Alternativas descartadas

| Alternativa | Por que não |
|---|---|
| Manter `easy|medium|hard` | cada degrau novo da escada exigiria ADR |
| Bot na fila sem aviso | o PI escolheu avisar; esconder bot quebra confiança se descoberto |
| Oferecer "jogar contra bot enquanto espera" | o PI escolheu entrar automático após 30 s |
| Fila só com humanos | com pouca população, a fila fica vazia |

## Consequências

- A #239 muda só o parse do argumento e o que o Launcher envia; o resto da entrega fica igual. Issue e `MVP-3.md` §3.13 atualizados.
- O orquestrador (F22) passa a subir partida com 1 humano + bot; o servidor da partida já roda `BotInput`, mas hoje só no modo offline.
- Custo de VPS: partida contra bot ocupa um container como uma partida normal (R7).
- Vigiar: fração de partidas contra bot no EA; se passar da maioria, o problema é população, não fila.
