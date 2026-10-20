# ADR-0029 — Contrato Launcher ↔ Game: argumento `--tutorial` e arquivo de resultado do treino offline

**Status:** aceito — decisão do PI em 2026-10-19 (pop-up do Cowork, SPEC-085)
**Data:** 2026-10-19
**Decisor:** Rodrigo Reis (PI)
**Emenda:** `ARCHITECTURE-LAUNCHER.md` §5.2 (argumentos) e §5.4 novo (arquivo de resultado offline) · ADR-0002 (o contrato só muda por ADR)
**Relacionados:** ADR-0026 itens 5–6 · ADR-0027 · F81 (#239) · F85 (#251)

## Contexto

O ADR-0026 libera a fila online depois do tutorial **ou** de 1 vitória contra o bot no treino, registrado na conta (backend). Hoje o treino offline roda com servidor embutido e termina com código de saída `0`; o Launcher não sabe quem venceu nem se o tutorial foi concluído.

## Decisão

1. **Argumento novo:** `game.exe -- --offline --tutorial` abre o tutorial roteirizado (SPEC-085). Não combina com `--bot`/`--bot-difficulty`: o próprio tutorial decide quando entra o bot.
2. **Arquivo de resultado:** ao terminar um treino ou o tutorial, o Game grava `user://offline_result.cfg` na pasta de dados comum (`rrb-moba`, a mesma do `settings.cfg`), com seção `[result]`:
   - `kind` = `tutorial` | `bot`
   - `outcome` = `completed` (tutorial concluído) | `win` | `loss` | `quit`
   - `bot_difficulty` = inteiro do ADR-0027 (só em `kind=bot`)
   - `finished_at` = data e hora em ISO 8601
3. **Leitura pelo Launcher:** quando o processo do Game termina, o Launcher lê o arquivo, apaga-o, e, se `tutorial/completed` ou `bot/win`, informa ao backend. O arquivo é aditivo: os códigos de saída (§5.2) não mudam, e Launcher antigo só ignora o arquivo.
4. **Sem conta, sem registro:** treino aberto pela tela de Login (sem sessão) grava o arquivo, mas não há conta para registrar.

## Alternativas descartadas

| Alternativa | Por que não |
|---|---|
| Códigos de saída novos (5, 6) | misturam resultado de jogo com erro; o Launcher já trata códigos como falha |
| Game chamar o backend direto no offline | o Game offline não tem sessão nem fala com o backend (ADR-0002) |

## Consequências

- O resultado vem de um processo que o jogador controla e pode ser forjado (risco já registrado no ADR-0026); aceitável enquanto só libera a fila.
- `shared/core` ganha a regra pura de ler/gravar o arquivo, testada nos dois projetos.
- O backend ganha o registro de fila liberada na conta (detalhe na SPEC-085).
