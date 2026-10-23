# ADR-0034 — Patente até 11: os 10 heróis KayKit na 1–10, os demais na 11; treino offline só com heróis liberados

**Status:** aceito — decisão do PI em 2026-10-23 (pop-ups do Cowork na especificação do F87)
**Data:** 2026-10-23
**Decisor:** Rodrigo Reis (PI)
**Emenda:** ADR-0026 itens 1 a 3 (Patente 1–10, "Patente 10 = os 10 heróis", herói inicial e item 6 só para o online) · `ARCHITECTURE-LAUNCHER.md` §5.2 (argumento novo `--heroes`, só com `--offline`) · ADR-0028 item 1 (o payload de validação também leva emblema e moldura equipados)
**Relacionados:** ADR-0025 · ADR-0026 · ADR-0027 · ADR-0032 (Carrasco) · F87 · F88 · F89 · F90 · F92

## Contexto

O ADR-0026 fixou Patente 1–10 com "Patente 10 = os 10 heróis". O Carrasco (ADR-0032) virou o 11º herói, e com 1 herói inicial + 1 por Patente da 2 à 10 a conta chega a 10 heróis e falta um. O ADR-0026 também deixou em aberto como se ganha Patente, o herói inicial, as contas que já existem e a separação da fila.

## Decisão

1. **Patente vai de 1 a 11.** A Patente 1 a 10 libera os **10 heróis KayKit** (Cavaleiro, Arqueiro, Bárbaro, Bruxo de Fogo, Ladina, Engenheiro, Protetor da Selva, Berserker, Paladino Radiante e Ocultista). A **Patente 11 libera todos os demais heróis do jogo** (hoje, o Carrasco; os heróis novos que não forem KayKit entram nessa regra).
2. **Herói inicial:** Cavaleiro, fixo (é o herói do tutorial, SPEC-085).
3. **Da Patente 2 à 10**, o jogador escolhe livremente 1 herói KayKit bloqueado a cada Patente (ADR-0026 item 3).
4. **Ganho:** só partida online (humano ou bot da fila, F89). Vitória 2 pontos, derrota 1, derrota por abandono (`left`, ADR-0020) 0. **3 pontos por Patente**, fixo: Patente = mínimo entre 11 e 1 + ⌊pontos ÷ 3⌋ (≈ 18 partidas até a Patente 10 com 50 % de vitória).
5. **Contas que já existem:** a Patente é calculada pelo histórico de partidas online com a regra do item 4, e a conta **mantém todos os heróis liberados**.
6. **Fila:** segue FIFO, sem separar por Patente.
7. **Treino offline contra bot:** só os heróis liberados da conta. O Launcher passa a lista ao Game em `--heroes=<id>,<id>,…`, aceito só junto de `--offline` (o tutorial segue com o Cavaleiro fixo). A partida online continua decidida só pelo backend (ADR-0026 item 6, ADR-0028).
8. **Payload de validação do token:** além dos heróis liberados e da skin equipada (ADR-0028), leva o emblema e a moldura equipados de cada jogador, que aparecem no pick, no carregamento e no fim de partida (SPEC-088).

## Alternativas descartadas

| Alternativa | Por que não |
|---|---|
| 2 heróis na Patente 10 | o PI preferiu separar os 10 KayKit dos demais |
| Conta nova com 2 heróis | idem |
| Vender o acesso ao Carrasco (ou dá-lo no Pacote de Fundador) | vende poder de combate (ADR-0025 item 1) |
| Escolha livre do herói inicial | o tutorial já ensina o Cavaleiro |
| Treino offline com todos os 11 | decisão do PI: mesma trava do online |
| Separar a fila por Patente | com pouca gente, esvazia a fila |

## Consequências

- Cada `.tres` de herói marca se é dos 10 KayKit (liberado da 1 à 10) ou da Patente 11 (SPEC-087).
- O contrato Launcher ↔ Game ganha `--heroes` (só offline). Um cliente alterado pode jogar offline com herói bloqueado; o treino não dá Patente nem nada pago, então o risco é aceito, como no ADR-0026.
- A skin do Fundador fica no Carrasco (SPEC-092): quem compra antes da Patente 11 tem a skin guardada até liberar o herói, e a Loja avisa antes do pagamento (SPEC-090).
- Vigiar: tempo real até a Patente 11 no Early Access; se a maioria desistir antes da 10, a curva volta à mesa.
