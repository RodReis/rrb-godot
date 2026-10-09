# rrb-godot

Jogo 2D em **Godot 4.7.2** (renderer Compatibility, viewport 1280x720, stretch `canvas_items`, filtro de textura *nearest* para pixel art).

## Estrutura

```
project.godot              configuracao + input map (move_left, move_right, jump)
scenes/main.tscn           cena principal: chao, uma plataforma e o Player
scenes/player.tscn         CharacterBody2D + colisao + Camera2D (visual provisorio: ColorRect)
scripts/player.gd          plataforma: aceleracao/atrito, coyote time, jump buffer, pulo variavel
assets/{sprites,audio,fonts}
tools/setup-godot-mcp.ps1  setup do Godot + godot-mcp no Windows
.mcp.json                  (gerado pelo setup) servidor MCP "godot" para o Claude Code
```

Controles: `A`/`D` ou setas andam; `Espaco`, `W` ou seta para cima pulam; gamepad (analogico/D-pad + botao A).

## Setup (Windows)

Requisitos: Godot 4.7.2 em `C:\Desenv\engine\godot` e Node.js >= 18.

```powershell
cd C:\Desenv\Projetos\rrb-godot
powershell -ExecutionPolicy Bypass -File tools\setup-godot-mcp.ps1 -ClaudeDesktop
```

Opcoes: `-GodotDir <pasta>` (outro local do Godot), `-InstallNode` (instala Node LTS via winget se faltar),
`-ClaudeDesktop` (registra tambem no Claude Desktop, com backup do config).

O script:
1. acha o `Godot*.exe` principal em `C:\Desenv\engine\godot` e grava a variavel de usuario `GODOT_PATH`;
2. confere Node.js >= 18 e poe `@coding-solo/godot-mcp@0.1.1` no cache do npm;
3. importa o projeto e roda a cena principal 120 frames em headless, falhando se aparecer `ERROR`;
4. cria o `.mcp.json` do projeto (se nao existir);
5. com `-ClaudeDesktop`, adiciona `mcpServers.godot` em `%APPDATA%\Claude\claude_desktop_config.json`.

Depois: **abra um terminal novo** (para herdar `GODOT_PATH`), rode `claude` na raiz e aprove o servidor `godot`.
No Claude Desktop, feche pela bandeja e abra de novo.

Por que o `.exe` principal e nao o `_console.exe` no `GODOT_PATH`: o `stop_project` do godot-mcp mata
o processo que ele criou; o `_console.exe` e um wrapper que dispara o `.exe` principal como filho, entao
o jogo ficaria aberto orfao.

## Ferramentas do MCP (godot-mcp 0.1.1)

`launch_editor`, `run_project`, `get_debug_output`, `stop_project`, `get_godot_version`, `list_projects`,
`get_project_info`, `create_scene`, `add_node`, `load_sprite`, `export_mesh_library`, `save_scene`,
`get_uid`, `update_project_uids`.

Limitacao conhecida: se o jogo **crashar**, o godot-mcp descarta o processo e o `get_debug_output`
responde "No active Godot process" - a saida do crash se perde. Nesse caso rode pelo terminal:
`& "$env:GODOT_PATH" --path . ` (ou o `_console.exe`) para ver o erro.

Referencias: [docs Godot](https://docs.godotengine.org/en/stable/) - [godot-mcp](https://github.com/Coding-Solo/godot-mcp) - [engine](https://github.com/godotengine/godot)
