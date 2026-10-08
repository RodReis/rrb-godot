# APRENDIZADOS.md — Armadilhas já pagas

**Leitura obrigatória do Code no passo 1 de todo card.** Curto por desenho.

## Protocolo

- Fonte: seção **Aprendizado** do comentário de encerramento de cada card (skill `fechar-card`). Só entra com fonte verificável (doc oficial, commit, log, comando).
- Consolidação: o Cowork promove para cá no fecho de cada MVP. Entre fechos, o Code pode propor linha por PR de docs.
- **Teto: 30 linhas na seção "Vigentes".** Passou do teto, a mais antiga ou menos recorrente desce para "Arquivo" — ou vira regra em `CLAUDE.md`/`CONVENTION.md` (promoção) e sai daqui.
- Formato: `- [módulo] frase única com a armadilha e o que fazer — fonte`.

## Vigentes

- [game] O `.exe` principal do Godot não imprime no terminal; use o `*_console.exe` para ver saída e crash — `CLAUDE.md` Comandos.
- [game] PowerShell 5.1 trata stderr de executável nativo como exceção com `$ErrorActionPreference='Stop'`; use `'Continue'` ao chamar o Godot — `CLAUDE.md`.
- [game] godot-mcp perde a saída quando o jogo crasha; rode pelo terminal para ver o erro — `README.md`.
- [game] `rg --type gdscript` é erro; use `--glob "*.gd"` — `docs/engine-reference/godot/current-best-practices.md`.
- [game] Clone novo não tem `.godot/`; rode `--import` headless antes de testes, senão o runner não carrega — engine-reference.
- [game] Lambda em GDScript captura local **por valor**; para sinal que marca flag, use Dictionary/objeto — engine-reference.
- [shared] Sem `tools/link-shared.ps1` o projeto abre com erros de `res://shared` — comportamento esperado, não bug — ADR-0003.
- [docs] Paleta do DV: `BLUE`/`RED`/`PURPLE` não passam contraste como texto pequeno; use fundo/borda — `design-system/TOKENS.md` (medido 2026-10-08).

## Arquivo

(vazio)
