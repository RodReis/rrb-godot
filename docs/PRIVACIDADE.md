# PRIVACIDADE.md — Registro não normativo

**Este documento não é citado por SPEC e não produz requisito, aceite, fluxo de consentimento nem texto legal.** É um registro de *achados*: onde o projeto, como está descrito no PRD e na arquitetura, toca dado pessoal ou tema regulatório — com a origem de cada achado — para o PI revisar quando quiser. Nenhum agente cria regra a partir daqui (`CLAUDE.md`).

## Achados

| # | Achado | Origem (documento, seção) | Contexto técnico |
|---|---|---|---|
| A-01 | Conta com e-mail e senha | PRD §8.4 | backend `users` (e-mail, hash). Hash argon2id, senha nunca em log — decisão de engenharia em `ARCHITECTURE-LAUNCHER.md` §4.4. |
| A-02 | Histórico de partidas por conta | PRD §8.4, DV tela 9 | `matches`, `match_players` ligados a `user_id`. |
| A-03 | Ping médio por partida persistido | PRD §8.5, §9.2 | número agregado por partida; não guarda IP do jogador. |
| A-04 | IP do jogador aparece nos logs do game server (ENet) | arquitetura | log de conexão; retenção não definida. |
| A-05 | Público-alvo declarado 10+ anos; monetização com sorteios pagos na fase B | PRD §1.2, §7, R5 | o próprio PRD registra que isso eleva classificação indicativa e exige publicação de probabilidades em lojas. Nada na fatia. |
| A-06 | Playtest com 10+ pessoas externas e questionário | PRD §9.1 (M4) | coleta fora do software (questionário); o software guarda só métricas de partida. |
| A-07 | Design visual mostra nome de jogador ("SirRodrigo") e nome do oponente na tela de fim | DV telas 1, 7 | R-PEND-02 decidida (2026-10-10): nickname público `#nick` (F35); histórico mostra herói e nickname do oponente, nunca e-mail. |
| A-08 | `user://settings.cfg` e, se aprovado R-PEND-03, `user://session.dat` | `ARCHITECTURE-LAUNCHER.md` §3.3, §5.3 | arquivos locais na máquina do jogador. |
| A-09 | Avatar por upload de imagem do jogador | R-PEND-02, F35 | arquivo local em `user://` (PNG/JPG ≤ 1 MB, 256×256); não sai da máquina. |

## O que **não** está aqui, de propósito

Política de privacidade, termos de uso, consentimento, LGPD, retenção, DPO, base legal. Nenhum desses foi passado pelo PI. Quando e se o PI decidir tratar, vira decisão dele (PRD ou ADR), e só então pode gerar requisito.
