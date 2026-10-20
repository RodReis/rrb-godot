# ADR-0026 — Patente (progressão de conta 1–10), liberação de heróis, recompensas de login e tutorial obrigatório

**Status:** aceito — decisão do PI em 2026-10-19 (pop-up do Cowork)
**Data:** 2026-10-19
**Decisor:** Rodrigo Reis (PI)
**Supera:** R-PEND-02 na parte "sem nível/XP de conta" (`RASTREABILIDADE.md` §5) e a linha "Nível/XP de conta" do `FORA-DE-ESCOPO.md`
**Relacionados:** F35 (#86, perfil) · F81 (#239, níveis do bot) · ADR-0025 · ADR-0027 · F85 · F87 · F88

## Contexto

Hoje a conta não tem progressão: o perfil mostra só V–D (R-PEND-02) e os 10 heróis estão liberados desde o início. O PI pediu primeiras partidas contra bot com dificuldade crescente, heróis liberados por nível até o 10, recompensas de login e um tutorial. O herói já vai do nível 1 ao 10 dentro da partida (`CONVENTION.md` §4.2), então o nome "nível" para a conta colide.

## Decisão

1. **Nome:** a progressão de conta se chama **Patente** (Patente 1 a 10). "Nível" fica só para o herói dentro da partida.
2. **Patente 1–10 é grátis e sem trava paga.** Depois da Patente 10, a conta segue recebendo só recompensas cosméticas.
3. **Heróis:** conta nova começa com **1 herói**; a cada Patente o jogador **escolhe livremente** qual herói bloqueado liberar. Patente 10 = os 10 heróis.
4. **Recompensas de login** diário, semanal e mensal, e recompensas de Patente, são **emblemas e molduras de perfil** (grátis, ADR-0025). Sem moeda virtual.
5. **Tutorial guiado** offline: abre obrigatoriamente na primeira vez, **pode ser pulado**; a fila online só libera depois de concluir o tutorial **ou** de 1 vitória contra o bot no treino.
6. **Posse e Patente moram no backend.** Na partida online, o pick só oferece heróis liberados, e o servidor da partida valida isso (nunca o cliente sozinho).

## Em aberto (decidir na SPEC, com o PI)

- Como se ganha progresso de Patente (por partida, por vitória, contra bot conta?) e quanto por Patente.
- Qual é o herói inicial (fixo, escolha livre entre todos, ou entre um grupo).
- Quais emblemas e molduras, em quais Patentes, e o calendário do login (o que conta como "dia", o que acontece com dia perdido).
- O que acontece com contas que já existem hoje (todos os heróis liberados ou recomeçam).
- Roteiro final do tutorial (proposta da análise: mover/câmera → alvo e auto-ataque → Q/E/R → monstro e XP → baú `F` e ficha `B` → fase 2 e vitória).

## Alternativas descartadas

| Alternativa | Por que não |
|---|---|
| Obrigar um herói diferente a cada nível | tira a escolha de quem chegou querendo um herói específico |
| Ordem fixa de liberação | o PI preferiu escolha livre |
| 3 heróis iniciais + 1 por Patente / todos liberados | decisão do PI pelo 1 inicial |
| Trava paga no 10 | pay-to-win e muro no fim do onboarding (ADR-0025) |
| Tutorial sem pular / opcional | o PI escolheu obrigatório na 1ª vez, pulável |

## Consequências

- O tutorial e a vitória no treino rodam com servidor embutido no cliente: o resultado pode ser forjado. Risco baixo enquanto liberam só a fila online; se algo pago passar a depender disso, essa partida tem de rodar no servidor do VPS.
- Matchmaking: conta Patente 1 com 1 herói pode cair contra Patente 10 na fila FIFO. A separação por Patente não foi decidida; o bot na fila (ADR-0027) mitiga a espera, não o desnível.
- `CONVENTION.md` ganha entidades novas (Patente, posse de herói, emblema/moldura) quando as SPECs forem escritas.
- Backend ganha posse de heróis e Patente por usuário; o contrato de validação de token da partida passa a carregar os heróis liberados (detalhe na SPEC do F87).
