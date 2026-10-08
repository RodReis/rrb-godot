# ADR-0003 — `shared/` montado nos dois projetos por junction

**Status:** aceito — 2026-10-08
**Decisor:** Rodrigo Reis (PI)
**Relacionados:** [ADR-0002](0002-dois-modulos-launcher-e-game.md)

## Contexto

`game/` e `launcher/` precisam dos mesmos Resources (`heroes/*.tres`, `items/*.tres`, `monsters/*.tres`, `rules/*.tres`), das mesmas fórmulas (`core/`: dano, CDR, velocidade, bônus de set — o simulador da Forja e o servidor têm de dar o mesmo número), do mesmo Theme e dos mesmos modelos glTF (diorama do lobby, preview de herói). Godot não tem mecanismo de "incluir pasta externa" em `res://`.

## Decisão

- `shared/` é uma pasta na raiz do monorepo, **sem `project.godot`**.
- `tools/link-shared.ps1` cria as junctions `game/shared` → `..\shared` e `launcher/shared` → `..\shared` (NTFS junction, não symlink: não exige privilégio de desenvolvedor no Windows). Na CI Linux, o mesmo papel é feito com `ln -s`.
- `game/shared` e `launcher/shared` estão no `.gitignore`. O que está versionado é `shared/`.
- Dentro de cada projeto, o caminho é `res://shared/...`. Scripts e cenas de `shared/` só referenciam `res://shared/...` — nunca `res://scripts/...` de um projeto específico.
- Cada projeto importa (`.godot/`) e gera `.uid` por conta própria. Arquivos `.uid` e `.import` dentro de `shared/` são versionados uma vez e valem para os dois (o uid é do arquivo, não do projeto).
- Mudança em `shared/` dispara a CI dos dois módulos (`CI-PR.md` §3).

## Alternativas descartadas

| Alternativa | Por que não |
|---|---|
| Git submodule | Overhead de submódulo dentro do próprio monorepo; dois commits para cada mudança. |
| Script que copia `shared/` para cada projeto | Dessincroniza; "qual cópia foi editada?" vira pergunta diária. |
| Addon em `addons/shared` publicado por `.zip` | Versão a mais para gerenciar; o editor trataria como terceiro. |
| Duplicar os `.tres` | Forja e servidor divergem no primeiro ajuste de balanceamento. |

## Consequências

- Clone novo precisa de `tools/link-shared.ps1` antes de abrir o editor (documentado no `README.md` e em `DEVELOPMENT.md`). Sem a junction, o projeto abre com erros de caminho — comportamento esperado, não bug.
- Godot resolve junction como diretório normal; o editor não distingue. **Risco a vigiar:** ferramentas que seguem junction recursivamente (`rg` sem `--no-follow`, backup) — `rg` por padrão não segue symlink, ok.
- Regras puras em `shared/core/` têm testes GUT em `shared/test/` **e** são rodadas pelos dois projetos (`tools/test.ps1 -Module game|launcher` inclui `res://shared/test`).
