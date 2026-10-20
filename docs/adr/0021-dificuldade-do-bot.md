# ADR-0021 — Dificuldade do bot no treino: argumento `--bot-difficulty`

**Status:** aceito — decisão do PI em 2026-10-19 (pop-up, sem Cowork: o Code abriu a fatia F81 / SPEC-081, issue #239)
**Decisor:** Rodrigo Reis (PI)
**Emenda:** `ARCHITECTURE-LAUNCHER.md` §5.2 (argumentos do contrato Launcher ↔ Game, ADR-0002)
**Relacionados:** F12 (#25) · F19 (#68) · F25 (#81) · F81 (#239)

## Contexto

O treino contra o bot tem um nível só. O PI pediu três (Fácil, Médio, Difícil), escolhidos no Launcher. O Launcher abre o Game com `--offline --bot` (§5.2); os argumentos fazem parte do contrato e mudá-los exige ADR.

## Decisão

1. **Argumento novo:** `--bot-difficulty=easy|medium|hard`, só junto de `--offline --bot`. Ausente ou inválido = `medium`. É aditivo: um Launcher antigo continua abrindo o treino no Médio.
2. **Médio é o bot de hoje.** Fácil reage mais devagar, erra mais a mira, usa menos habilidades e não persegue; Difícil reage rápido, mira quase certa, usa todas as habilidades e foge com pouca vida. Só a inteligência muda: números de herói, itens e regras são os mesmos.
3. **Parâmetros em Resource** (`shared/data/`), não no código: tempo de reação, erro de mira, uso de habilidade, perseguição e fuga por nível.
4. **Escolha no Launcher:** card Treino vs Bot do Lobby (Fácil / Médio / Difícil ao lado de Iniciar); o Launcher lembra a última escolha. ~~O botão de treino do Login usa a mesma escolha.~~ Superado em 2026-10-20 (PI): o Login não tem mais treino; o treino vs bot fica só no Lobby, depois do login, porque o bot vai rodar na nuvem (F89, ADR-0027).

## Emenda (PI, 2026-10-20, F81)

O soak mediu o Fácil bem abaixo do Médio (2 de 20 vitórias contra o Médio). Com limiar e mira o Difícil ficou em empate com o Médio; o PI jogou no Difícil e achou o bot "fugindo" e farmando mal. O Difícil final usa Q e E nos monstros do farm (o R fica para herói e boss, `farm_skills`), briga em nível igual (`level_slack`) e mira antecipada nas habilidades (`lead_seconds`): 27 de 40 contra o Médio (linha-base 23 de 40) e nível 7,17 contra 5,83 aos 5:00. Critério de prova: **Fácil < Médio < Difícil**. Dados em `docs/evidencias/f81/soak-por-nivel.md`.

## Consequências

- `ARCHITECTURE-LAUNCHER.md` §5.2 lista o argumento; `LaunchArgs` do Game o lê.
- O nível não vale para a fila online (não há bot online).
- Prova por medida: soak curto por nível contra o mesmo oponente, com a ordem Difícil > Médio > Fácil.
