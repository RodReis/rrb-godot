# ADR-0005 — Blender no pipeline de assets 3D; só glTF entra nos projetos Godot

**Status:** aceito — 2026-10-09
**Decisor:** Rodrigo Reis (PI)
**Relacionados:** PRD §1.3, D9, §9.3 R6, §11 · ADR-0003 · `FORA-DE-ESCOPO.md` · `GITHUB.md` §10 · `ARCHITECTURE-GAME.md` §2

## Contexto

- O PRD (D9, §11) fixa KayKit (principal) e Quaternius (secundário), CC0 em glTF, e adia arte própria para a fase B (§1.3, R6, `FORA-DE-ESCOPO.md`).
- Em 2026-10-09 o PI decidiu: usar o **Blender sempre que necessário** para criação, acabamento, ajustes e rascunhos de assets 3D; **arte própria liberada**, feita pelo Claude (o PI não modela).
- Ambiente do PI: Blender 5.2.2 LTS + Blender MCP (addon `mcp` do Blender Lab), conectado ao Claude. Pack KayKit Adventurers na versão grátis; a versão Extra (US$ 7,95) é compra futura do PI, sem data.
- O Godot importa `.blend` chamando o Blender instalado para converter em glTF (docs Godot, "Available 3D formats"). Isso tornaria o Blender obrigatório em toda máquina que importa o projeto: CI (GUT headless), build Docker do servidor e qualquer clone. A mesma doc recomenda glTF.
- O Blender MCP executa no Blender código gerado pelo LLM **sem proteção** contra apagar dados ou enviá-los para fora; o Blender Lab recomenda VM. O PI aceitou rodar na máquina de desenvolvimento, sem VM.

## Decisão

1. **Blender é a ferramenta de assets 3D do projeto**, usada sempre que necessário para: criação (arte própria), acabamento, ajustes de assets CC0 (escala, pivô, origem, cor, troca de peças) e rascunho geométrico (blockout de arena e peças). O Claude opera o Blender pelo MCP; a verificação visual é do PI.
2. **Fonte `.blend` fica em `art/`, na raiz do monorepo**, fora de `game/`, `launcher/` e `shared/`. Nenhum projeto Godot importa `.blend`.
3. **Só glTF entra em `shared/assets/`.** Asset CC0 sem alteração fica como vem do pack (KayKit em `.gltf` + `.bin` + textura, como já está desde o F7); asset criado ou alterado no Blender é exportado como `.glb`. O export é passo explícito, feito a cada mudança na fonte.
4. **Importação de `.blend` desligada** nos projetos Godot (Project Settings avançado: *Filesystem > Import > Blender > Enabled* = `false`), como defesa contra `.blend` copiado por engano.
5. **Colisão, navegação e occluder** saem do próprio modelo pelos sufixos de nome do importador do Godot: `-col`, `-convcol`, `-colonly`, `-convcolonly`, `-navmesh`, `-occ`, `-occonly`; `-noimp` remove nó auxiliar; `-loop` marca animação em laço.
6. Asset novo ou modificado continua passando pela **cena de alinhamento** (PRD §11).

## Alternativas descartadas

| Alternativa | Por que não |
|---|---|
| Importar `.blend` direto no Godot | exige Blender no CI, no build Docker e em todo clone; acopla a fonte de trabalho ao jogo |
| Addon *Blender-Godot Pipeline* (Asset Library 2562) | declara Godot 4.2; depende de addon de Blender do mesmo autor; não validado no 4.7.2 |
| Addon *Godot Blender Importer* (Asset Library 1112) | feito para Godot 3.4 (2021); o Godot 4 já importa `.blend` nativamente |
| Rodar o Blender MCP numa VM | recomendação do Blender Lab; o PI optou por não usar VM e aceitou o risco |
| KayKit versão Source (`.blend`, US$ 11,95) | o Blender abre o glTF da versão grátis; não é necessário para editar |

## Consequências

**Positivas**
- Arte própria deixa de ser roadmap: pode entrar em qualquer MVP quando a fatia precisar (PRD §1.3, R6, D9 e §11 atualizados; linha movida em `FORA-DE-ESCOPO.md`).
- CI, Docker e clones não dependem do Blender: o jogo só vê glTF.

**Custos**
- Export manual a cada alteração da fonte; `.blend` e `.glb` versionados aumentam o peso do repo.
- Infra de repositório pendente (card `[INFRA]`, implementação do Code): `.gitattributes` com `*.glb binary` e `*.blend binary` (`*.bin binary` já entrou no F7); `.gitignore` com `*.blend1` (backup do Blender); configuração do item 4 no `project.godot` de `game/` (e de `launcher/` quando existir). LFS continua na regra do `GITHUB.md` §10 (repo acima de 500 MB).

**O que vigiar**
- Coerência visual com o KayKit (cena de alinhamento).
- Qualidade de modelagem e animação geradas por LLM: props e cenário tendem a sair aceitáveis; personagem e animação são o ponto fraco.
- Personagem próprio fora do esqueleto do KayKit não aproveita o pack *KayKit Character Animations*.
- Risco do MCP aceito pelo PI: trabalhar só sobre arquivos versionados no git.
- O modo em segundo plano do MCP (`*_for_cli`) depende da variável `BLENDER_PATH` visível ao app Claude; o modo interativo depende do Blender aberto com o servidor do addon ligado (porta 9876).
