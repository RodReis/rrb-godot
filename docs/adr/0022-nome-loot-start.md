# ADR-0022 — O jogo passa a se chamar "Loot Start"

**Status:** aceito — decisão do PI em 2026-10-19 (pop-up, sem Cowork: o Code abriu a fatia F82 / SPEC-082), issue #241
**Decisor:** Rodrigo Reis (PI)
**Emenda:** ADR-0017 item 2 ("Loot Start" só no site)
**Relacionados:** F24 (#80, marca ARENA 1V1) · F68 (splash) · F82 · F83

## Contexto

O ADR-0017 deu o nome "Loot Start" só ao site; o jogo, o Launcher e o README seguiam "ARENA 1V1" até o PI decidir. Antes do instalador (F83), o PI decidiu: "O nome do jogo é: Loot Start, vamos trocar em todo o game".

## Decisão

1. **Nome único "Loot Start"** em tudo que o jogador vê: título das janelas (Launcher e Game), marca da barra do Launcher, splash, rodapé, LEIA-ME, README, nome do executável do Launcher (`LootStart.exe`), metadados do `.exe` (nome do produto e descrição), pacote e, no F83, instalador e atalho.
2. **Visual da marca = o do site:** logo do baú com "play" e wordmark em Cinzel dourada (gradiente `GOLD_BRIGHT` → `GOLD`), a mesma do lootstart.cloud. O `splash.png` é regerado com ela.
3. **Fica como está** o que o jogador não vê: nome do repositório, pastas, `class_name`, imagens Docker, `game/game.exe` (caminho do contrato §5.1) e a pasta de dados `custom_user_dir_name="rrb-moba"` — trocar o `config/name` não move configurações nem sessão.

## Consequências

- `CLAUDE.md`, `ADR-0017`, `docs/SITE.md` e `README.md` deixam de dizer "o jogo segue ARENA 1V1".
- `ARCHITECTURE-LAUNCHER.md` §5.1 passa a listar `LootStart.exe` + `LootStart.pck`.
- Aceite visual do PI (marca e splash lado a lado com o site).
