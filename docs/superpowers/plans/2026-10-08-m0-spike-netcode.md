# M0 — Spike de Netcode: Plano de Implementação

> **Para agentes:** SUB-SKILL OBRIGATÓRIA: use superpowers:subagent-driven-development (recomendado) ou superpowers:executing-plans para executar este plano tarefa por tarefa. Passos usam checkbox (`- [ ]`).

**Objetivo:** provar, em 2 semanas, que Godot 4.7 + netfox entrega movimento com predição e um ataque validado no servidor jogáveis a 100 ms de RTT — o gate Godot × Unity do PRD (§9.1, §10.3).

**Arquitetura:** um único projeto Godot em `game/` roda como servidor dedicado headless (`-- --server`) ou cliente (`-- --connect=host:porta`). O servidor é autoritativo: clientes enviam só input (movimento, mira, ataque) pelo `RollbackSynchronizer` do netfox; servidor simula e devolve estado (transform, HP, cooldown). Regras puras (dano, arco de ataque, mira no chão, parsing de argumentos) ficam em `scripts/core/` e são testadas com GUT. O servidor roda em Docker com `tc netem` para simular latência/perda.

**Stack:** Godot 4.7.2 (Forward+), GDScript, netfox (+ netfox.internals, netfox.extras), GUT 9.7.x, Docker Desktop (Windows) com imagem Debian + Godot Linux headless, PowerShell.

**PRD:** `docs/prd/2026-10-08-prd-moba-2-tempos.md`

**Onde rodar:** todos os comandos são PowerShell no Windows, na raiz `C:\Desenv\Projetos\rrb-godot`. Godot e Docker rodam na máquina do Rodrigo (o Claude Code local com godot-mcp consegue executar; a sessão cloud só edita arquivos).

---

## Estrutura de arquivos (fim do M0)

```
game/
  project.godot                  config mínima Forward+, main scene, plugins
  icon.svg                       (movido da raiz)
  addons/netfox/                 terceiro — não editar
  addons/netfox.internals/       terceiro — não editar
  addons/netfox.extras/          terceiro — não editar
  addons/gut/                    terceiro — não editar
  scenes/main.tscn               raiz: arena, spawner, câmera, UI
  scenes/player.tscn             cápsula + Input + HpLabel
  scripts/main.gd                bootstrap: parse args, sobe servidor/cliente, spawna players, HUD de RTT
  scripts/arena.gd               gera chão e obstáculos em código (idêntico em servidor e cliente)
  scripts/follow_camera.gd       câmera segue o player local
  scripts/core/launch_args.gd    parse de --server/--port/--connect/--autopilot (puro)
  scripts/core/combat_rules.gd   dano e arco de ataque corpo a corpo (puro)
  scripts/core/aim_math.gd       projeção do mouse no chão (puro)
  scripts/core/input_actions.gd  registra o input map em código
  scripts/net/player.gd          CharacterBody3D: rollback, movimento, ataque, HP
  scripts/net/player_input.gd    BaseNetInput: coleta WASD/mouse ou autopilot
  test/unit/test_launch_args.gd
  test/unit/test_combat_rules.gd
  test/unit/test_aim_math.gd
  test/unit/test_input_actions.gd
infra/
  docker-compose.yml
  gameserver/Dockerfile
  gameserver/entrypoint.sh
.dockerignore
tools/
  setup-godot-mcp.ps1            (modificado: projeto agora em game/)
  test.ps1                       roda GUT headless
  run-server.ps1                 servidor local sem Docker
  run-clients.ps1                abre N clientes lado a lado
docs/adr/0001-gate-m0.md         protocolo e resultado do gate
README.md                        (reescrito)
```

Removidos: `project.godot`, `icon.svg*`, `scenes/`, `scripts/`, `assets/` da raiz (starter 2D).

---

### Tarefa 0: Pré-requisitos e snapshot do starter

**Arquivos:** nenhum.

- [ ] **Passo 1: Conferir ferramentas**

```powershell
cd C:\Desenv\Projetos\rrb-godot
$env:GODOT_PATH
Test-Path ($env:GODOT_PATH -replace '\.exe$','_console.exe')
docker version --format '{{.Server.Version}}'
git --version
```
Esperado: caminho do `Godot_v4.7.2-stable_win64.exe`, `True`, uma versão do Docker Engine, versão do git. Se `GODOT_PATH` vazio: rode `powershell -ExecutionPolicy Bypass -File tools\setup-godot-mcp.ps1` e abra um terminal novo. Se `docker` falhar: instale/abra o Docker Desktop (backend WSL2).

- [ ] **Passo 2: Commitar o starter atual (hoje está quase todo sem rastreio)**

```powershell
git add -A
git commit -m "chore: snapshot do starter 2D e PRD antes do M0"
```
Esperado: commit criado; `git status` limpo.

---

### Tarefa 1: Reestruturar para `game/`

**Arquivos:**
- Criar: `game/project.godot`
- Mover: `icon.svg` → `game/icon.svg`
- Remover: `project.godot`, `icon.svg.import`, `scenes/`, `scripts/`, `assets/`, `.godot/`
- Modificar: `tools/setup-godot-mcp.ps1`, `README.md`

- [ ] **Passo 1: Remover o starter 2D e mover o ícone**

```powershell
git rm -r --quiet project.godot icon.svg.import scenes scripts assets
New-Item -ItemType Directory game | Out-Null
git mv icon.svg game/icon.svg
Remove-Item -Recurse -Force .godot -ErrorAction SilentlyContinue
```

- [ ] **Passo 2: Criar `game/project.godot`**

```ini
; Engine configuration file.
config_version=5

[application]

config/name="rrb-godot"
run/main_scene="res://scenes/main.tscn"
config/features=PackedStringArray("4.7", "Forward Plus")
config/icon="res://icon.svg"

[display]

window/size/viewport_width=1280
window/size/viewport_height=720

[physics]

common/physics_ticks_per_second=60

[debug]

gdscript/warnings/untyped_declaration=2
gdscript/warnings/unsafe_property_access=1
gdscript/warnings/unsafe_method_access=1
```

`untyped_declaration=2` transforma variável/parâmetro/retorno sem tipo em **erro** (regra do `CLAUDE.md`). Addons de terceiros ficam de fora por padrão (`exclude_addons`).

- [ ] **Passo 3: Ajustar `tools/setup-godot-mcp.ps1` para o projeto em `game/`**

Substituir a linha:
```powershell
$ProjectDir = Split-Path -Parent $PSScriptRoot
```
por:
```powershell
$RepoDir = Split-Path -Parent $PSScriptRoot
$ProjectDir = Join-Path $RepoDir 'game'
```
Substituir:
```powershell
$mcpJson = Join-Path $ProjectDir '.mcp.json'
```
por:
```powershell
$mcpJson = Join-Path $RepoDir '.mcp.json'
```
Substituir:
```powershell
Write-Host "  - Claude Code: abra um terminal NOVO, rode 'claude' em $ProjectDir e aprove o servidor 'godot' (.mcp.json)."
```
por:
```powershell
Write-Host "  - Claude Code: abra um terminal NOVO, rode 'claude' em $RepoDir e aprove o servidor 'godot' (.mcp.json)."
```
(As chamadas de import/smoke test e "Abrir o editor" continuam usando `$ProjectDir`, que agora aponta para `game/`.)

- [ ] **Passo 4: Reescrever `README.md`**

```markdown
# rrb-godot

MOBA de 2 tempos em **Godot 4.7.2** (3D, Forward+), multiplayer com servidor autoritativo.
PRD: `docs/prd/2026-10-08-prd-moba-2-tempos.md`. Marco atual: **M0 — spike de netcode**.

## Estrutura

```
game/      projeto Godot (cliente + servidor dedicado)
infra/     Docker do game server (com simulação de latência via netem)
tools/     scripts PowerShell (setup, testes, rodar servidor/clientes)
docs/      PRD, planos, ADRs
```

## Comandos (PowerShell, na raiz)

| O quê | Comando |
|---|---|
| Setup Godot + godot-mcp | `powershell -ExecutionPolicy Bypass -File tools\setup-godot-mcp.ps1` |
| Testes unitários (GUT) | `.\tools\test.ps1` |
| Servidor local (sem Docker) | `.\tools\run-server.ps1` |
| Servidor Docker | `docker compose -f infra/docker-compose.yml up --build` |
| Servidor Docker com 100 ms + 2% perda | `$env:NETEM_DELAY_MS=100; $env:NETEM_LOSS_PCT=2; docker compose -f infra/docker-compose.yml up --build` |
| 2 clientes (2º em autopilot) | `.\tools\run-clients.ps1 -Autopilot` |

Controles: WASD move, mouse mira, botão esquerdo ataca.
Argumentos do jogo (depois de `--`): `--server`, `--port=7000`, `--connect=host:porta`, `--autopilot`.
```

- [ ] **Passo 5: Conferir que o editor abre o projeto vazio**

```powershell
& ($env:GODOT_PATH -replace '\.exe$','_console.exe') --headless --path game --import
```
Esperado: termina sem linhas `ERROR` (vai avisar que `res://scenes/main.tscn` não existe — normal até a Tarefa 7).

- [ ] **Passo 6: Commit**

```powershell
git add -A
git commit -m "refactor: projeto Godot movido para game/, starter 2D removido"
```

---

### Tarefa 2: Instalar netfox e GUT

**Arquivos:**
- Criar: `game/addons/netfox/`, `game/addons/netfox.internals/`, `game/addons/netfox.extras/`, `game/addons/gut/`
- Modificar: `game/project.godot` (pelo editor)

- [ ] **Passo 1: Baixar netfox**

Abra https://github.com/foxssake/netfox/releases, baixe o zip do release mais recente marcado como *Latest* (v1.35.3 quando este plano foi escrito). Do zip, copie **somente** as pastas `addons/netfox`, `addons/netfox.internals` e `addons/netfox.extras` para `game/addons/`. Não copie `netfox.noray` (não usamos).

- [ ] **Passo 2: Baixar GUT**

Abra https://github.com/bitwes/Gut/releases, baixe o release **9.7.x** (o primeiro com "Compatibility changes for Godot 4.7"). Copie `addons/gut` para `game/addons/gut`.

- [ ] **Passo 3: Habilitar plugins no editor**

```powershell
& $env:GODOT_PATH -e --path game
```
No editor: *Project → Project Settings → Plugins* → marque **Enabled** em netfox, netfox.internals (se aparecer), netfox.extras e Gut. Feche os diálogos.

- [ ] **Passo 4: Conferir tickrate do netfox**

*Project Settings* → ative *Advanced Settings* → seção **netfox → Time** → `Tickrate` = **30**. Se estiver diferente, ajuste para 30. Salve e feche o editor.

- [ ] **Passo 5: Conferir que os autoloads entraram**

```powershell
Select-String -Path game/project.godot -Pattern 'NetworkTime|NetworkRollback|editor_plugins'
```
Esperado: linhas `[autoload]` com `NetworkTime`, `NetworkRollback` (e outros do netfox) e `[editor_plugins]` listando os `plugin.cfg`. Se não aparecer, o plugin não foi habilitado — repita o Passo 3.

- [ ] **Passo 6: Commit**

```powershell
git add -A
git commit -m "chore: adiciona netfox e GUT 9.7"
```

---

### Tarefa 3: Runner de testes + `LaunchArgs` (TDD)

**Arquivos:**
- Criar: `tools/test.ps1`
- Criar: `game/test/unit/test_launch_args.gd`
- Criar: `game/scripts/core/launch_args.gd`

- [ ] **Passo 1: Criar `tools/test.ps1`**

```powershell
<#
.SYNOPSIS
  Roda os testes unitarios (GUT) em headless.
#>
$ErrorActionPreference = 'Continue'   # Godot escreve avisos em stderr
$repo = Split-Path -Parent $PSScriptRoot
$game = Join-Path $repo 'game'
if (-not $env:GODOT_PATH) { Write-Host 'GODOT_PATH nao definido. Rode tools\setup-godot-mcp.ps1.' -ForegroundColor Red; exit 1 }
$cli = $env:GODOT_PATH -replace '\.exe$', '_console.exe'
if (-not (Test-Path $cli)) { $cli = $env:GODOT_PATH }

& $cli --headless --path $game --import 2>&1 | Out-Null
& $cli --headless --path $game -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -ginclude_subdirs -gexit 2>&1 | ForEach-Object { "$_" }
exit $LASTEXITCODE
```

- [ ] **Passo 2: Escrever o teste que falha — `game/test/unit/test_launch_args.gd`**

```gdscript
extends GutTest

func test_sem_argumentos_e_cliente_sem_host_na_porta_padrao() -> void:
	var r := LaunchArgs.parse(PackedStringArray([]))
	assert_eq(r["mode"], "client")
	assert_eq(r["host"], "")
	assert_eq(r["port"], 7000)
	assert_false(r["autopilot"])

func test_server_usa_porta_padrao() -> void:
	var r := LaunchArgs.parse(PackedStringArray(["--server"]))
	assert_eq(r["mode"], "server")
	assert_eq(r["port"], 7000)

func test_server_com_porta() -> void:
	var r := LaunchArgs.parse(PackedStringArray(["--server", "--port=7010"]))
	assert_eq(r["mode"], "server")
	assert_eq(r["port"], 7010)

func test_connect_com_host_e_porta() -> void:
	var r := LaunchArgs.parse(PackedStringArray(["--connect=10.0.0.5:7001"]))
	assert_eq(r["mode"], "client")
	assert_eq(r["host"], "10.0.0.5")
	assert_eq(r["port"], 7001)

func test_connect_sem_porta_usa_padrao() -> void:
	var r := LaunchArgs.parse(PackedStringArray(["--connect=10.0.0.5"]))
	assert_eq(r["host"], "10.0.0.5")
	assert_eq(r["port"], 7000)

func test_porta_invalida_cai_no_padrao() -> void:
	assert_eq(LaunchArgs.parse(PackedStringArray(["--port=abc"]))["port"], 7000)
	assert_eq(LaunchArgs.parse(PackedStringArray(["--port=70000"]))["port"], 7000)
	assert_eq(LaunchArgs.parse(PackedStringArray(["--port=0"]))["port"], 7000)

func test_autopilot() -> void:
	var r := LaunchArgs.parse(PackedStringArray(["--connect=127.0.0.1:7000", "--autopilot"]))
	assert_true(r["autopilot"])
```

- [ ] **Passo 3: Rodar e ver falhar**

```powershell
.\tools\test.ps1
```
Esperado: FALHA — erro de parse `Identifier "LaunchArgs" not declared in the current scope`, exit code ≠ 0.

- [ ] **Passo 4: Implementar `game/scripts/core/launch_args.gd`**

```gdscript
class_name LaunchArgs
extends RefCounted
## Interpreta os argumentos de usuario (depois de `--` na linha de comando do Godot).

const DEFAULT_PORT := 7000

static func parse(args: PackedStringArray) -> Dictionary:
	var result := {"mode": "client", "host": "", "port": DEFAULT_PORT, "autopilot": false}
	for arg: String in args:
		if arg == "--server":
			result["mode"] = "server"
		elif arg == "--autopilot":
			result["autopilot"] = true
		elif arg.begins_with("--port="):
			result["port"] = _port_or_default(arg.trim_prefix("--port="))
		elif arg.begins_with("--connect="):
			var parts := arg.trim_prefix("--connect=").split(":")
			result["host"] = parts[0]
			if parts.size() > 1:
				result["port"] = _port_or_default(parts[1])
	return result

static func _port_or_default(text: String) -> int:
	if text.is_valid_int():
		var port := text.to_int()
		if port > 0 and port < 65536:
			return port
	return DEFAULT_PORT
```

- [ ] **Passo 5: Rodar e ver passar**

```powershell
.\tools\test.ps1
```
Esperado: `7/7 passed`, exit code 0.

- [ ] **Passo 6: Commit**

```powershell
git add tools/test.ps1 game/test game/scripts/core/launch_args.gd
git commit -m "feat(core): LaunchArgs com testes GUT"
```

---

### Tarefa 4: `CombatRules` (TDD)

**Arquivos:**
- Criar: `game/test/unit/test_combat_rules.gd`
- Criar: `game/scripts/core/combat_rules.gd`

Regras do PRD §4.2: dano efetivo = dano × 100 / (100 + Defesa), arredondado; HP nunca negativo. Arco corpo a corpo ignora altura (Y).

- [ ] **Passo 1: Escrever o teste que falha**

```gdscript
extends GutTest

const FWD := Vector3(0, 0, -1)  # -Z e a frente no Godot

func test_dano_com_defesa() -> void:
	# 120 * 100 / 130 = 92.3 -> 92
	assert_eq(CombatRules.apply_damage(600, 120, 30), 508)

func test_dano_sem_defesa_e_integral() -> void:
	assert_eq(CombatRules.apply_damage(600, 120, 0), 480)

func test_defesa_negativa_vale_zero() -> void:
	assert_eq(CombatRules.apply_damage(600, 120, -50), 480)

func test_hp_nao_fica_negativo() -> void:
	assert_eq(CombatRules.apply_damage(50, 120, 0), 0)

func test_alvo_a_frente_no_alcance() -> void:
	assert_true(CombatRules.is_in_melee_arc(Vector3.ZERO, FWD, Vector3(0, 0, -1.5), 2.0, 60.0))

func test_alvo_fora_do_alcance() -> void:
	assert_false(CombatRules.is_in_melee_arc(Vector3.ZERO, FWD, Vector3(0, 0, -3.0), 2.0, 60.0))

func test_alvo_atras() -> void:
	assert_false(CombatRules.is_in_melee_arc(Vector3.ZERO, FWD, Vector3(0, 0, 1.5), 2.0, 60.0))

func test_alvo_dentro_do_angulo() -> void:
	# atan(1.2 / 1.0) = 50 graus
	assert_true(CombatRules.is_in_melee_arc(Vector3.ZERO, FWD, Vector3(1.2, 0, -1.0), 2.0, 60.0))

func test_alvo_fora_do_angulo() -> void:
	# atan(1.5 / 0.5) = 71.6 graus
	assert_false(CombatRules.is_in_melee_arc(Vector3.ZERO, FWD, Vector3(1.5, 0, -0.5), 2.0, 60.0))

func test_altura_e_ignorada() -> void:
	assert_true(CombatRules.is_in_melee_arc(Vector3.ZERO, FWD, Vector3(0, 1.0, -1.5), 2.0, 60.0))

func test_alvo_na_mesma_posicao_e_atingido() -> void:
	assert_true(CombatRules.is_in_melee_arc(Vector3.ZERO, FWD, Vector3.ZERO, 2.0, 60.0))
```

- [ ] **Passo 2: Rodar e ver falhar**

```powershell
.\tools\test.ps1
```
Esperado: FALHA — `Identifier "CombatRules" not declared`.

- [ ] **Passo 3: Implementar `game/scripts/core/combat_rules.gd`**

```gdscript
class_name CombatRules
extends RefCounted
## Regras puras de combate. Sem estado, sem nodes: testavel em isolamento.

static func apply_damage(hp: int, damage: int, defense: int) -> int:
	var effective := roundi(damage * 100.0 / (100.0 + maxi(defense, 0)))
	return maxi(hp - effective, 0)

static func is_in_melee_arc(attacker_pos: Vector3, forward: Vector3, target_pos: Vector3,
		attack_range: float, half_angle_deg: float) -> bool:
	var to_target := target_pos - attacker_pos
	to_target.y = 0.0
	var dist := to_target.length()
	if dist > attack_range:
		return false
	if dist < 0.001:
		return true
	var flat_forward := Vector3(forward.x, 0.0, forward.z).normalized()
	return rad_to_deg(flat_forward.angle_to(to_target / dist)) <= half_angle_deg
```

- [ ] **Passo 4: Rodar e ver passar**

```powershell
.\tools\test.ps1
```
Esperado: `18/18 passed`.

- [ ] **Passo 5: Commit**

```powershell
git add game/test/unit/test_combat_rules.gd game/scripts/core/combat_rules.gd
git commit -m "feat(core): CombatRules (dano e arco corpo a corpo)"
```

---

### Tarefa 5: `AimMath` (TDD)

**Arquivos:**
- Criar: `game/test/unit/test_aim_math.gd`
- Criar: `game/scripts/core/aim_math.gd`

- [ ] **Passo 1: Escrever o teste que falha**

```gdscript
extends GutTest

func test_mira_aponta_do_player_para_o_ponto_no_chao() -> void:
	# raio vertical caindo em (0,0,0); player em (0,0,-2) -> direcao +Z
	var aim := AimMath.aim_on_ground(Vector3(0, 10, 0), Vector3(0, -1, 0), Vector3(0, 0, -2))
	assert_almost_eq(aim, Vector3(0, 0, 1), Vector3(0.001, 0.001, 0.001))

func test_mira_e_horizontal_mesmo_com_player_acima_do_chao() -> void:
	var aim := AimMath.aim_on_ground(Vector3(3, 10, 0), Vector3(0, -1, 0), Vector3(0, 1.5, 0))
	assert_almost_eq(aim, Vector3(1, 0, 0), Vector3(0.001, 0.001, 0.001))

func test_raio_paralelo_ao_chao_retorna_zero() -> void:
	assert_eq(AimMath.aim_on_ground(Vector3(0, 10, 0), Vector3(1, 0, 0), Vector3.ZERO), Vector3.ZERO)

func test_raio_para_cima_retorna_zero() -> void:
	assert_eq(AimMath.aim_on_ground(Vector3(0, 10, 0), Vector3(0, 1, 0), Vector3.ZERO), Vector3.ZERO)

func test_mouse_em_cima_do_player_retorna_zero() -> void:
	assert_eq(AimMath.aim_on_ground(Vector3(0, 10, 0), Vector3(0, -1, 0), Vector3(0.05, 0, 0)), Vector3.ZERO)
```

- [ ] **Passo 2: Rodar e ver falhar**

```powershell
.\tools\test.ps1
```
Esperado: FALHA — `Identifier "AimMath" not declared`.

- [ ] **Passo 3: Implementar `game/scripts/core/aim_math.gd`**

```gdscript
class_name AimMath
extends RefCounted
## Converte o raio do mouse (camera) numa direcao horizontal a partir do player.

const GROUND := Plane(Vector3.UP, 0.0)

static func aim_on_ground(ray_origin: Vector3, ray_dir: Vector3, player_pos: Vector3,
		deadzone: float = 0.1) -> Vector3:
	var hit: Variant = GROUND.intersects_ray(ray_origin, ray_dir)
	if hit == null:
		return Vector3.ZERO
	var flat: Vector3 = hit - player_pos
	flat.y = 0.0
	if flat.length() < deadzone:
		return Vector3.ZERO
	return flat.normalized()
```

- [ ] **Passo 4: Rodar e ver passar**

```powershell
.\tools\test.ps1
```
Esperado: `23/23 passed`.

- [ ] **Passo 5: Commit**

```powershell
git add game/test/unit/test_aim_math.gd game/scripts/core/aim_math.gd
git commit -m "feat(core): AimMath (mira do mouse no chao)"
```

---

### Tarefa 6: `InputActions` (TDD)

**Arquivos:**
- Criar: `game/test/unit/test_input_actions.gd`
- Criar: `game/scripts/core/input_actions.gd`

Input map em código para manter `project.godot` enxuto e versionável.

- [ ] **Passo 1: Escrever o teste que falha**

```gdscript
extends GutTest

const ACTIONS: Array[String] = ["move_left", "move_right", "move_forward", "move_back", "attack"]

func test_registra_todas_as_acoes() -> void:
	InputActions.ensure()
	for action: String in ACTIONS:
		assert_true(InputMap.has_action(action), action)

func test_chamar_duas_vezes_nao_duplica_eventos() -> void:
	InputActions.ensure()
	InputActions.ensure()
	for action: String in ACTIONS:
		assert_eq(InputMap.action_get_events(action).size(), 1, action)

func test_attack_e_botao_esquerdo() -> void:
	InputActions.ensure()
	var ev := InputMap.action_get_events("attack")[0] as InputEventMouseButton
	assert_not_null(ev)
	assert_eq(ev.button_index, MOUSE_BUTTON_LEFT)
```

- [ ] **Passo 2: Rodar e ver falhar**

```powershell
.\tools\test.ps1
```
Esperado: FALHA — `Identifier "InputActions" not declared`.

- [ ] **Passo 3: Implementar `game/scripts/core/input_actions.gd`**

```gdscript
class_name InputActions
extends RefCounted
## Registra as acoes de input em codigo. Idempotente.

const KEYS := {
	"move_left": KEY_A,
	"move_right": KEY_D,
	"move_forward": KEY_W,
	"move_back": KEY_S,
}

static func ensure() -> void:
	for action: String in KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var key := InputEventKey.new()
			key.physical_keycode = KEYS[action]
			InputMap.action_add_event(action, key)
	if not InputMap.has_action("attack"):
		InputMap.add_action("attack")
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("attack", click)
```

- [ ] **Passo 4: Rodar e ver passar**

```powershell
.\tools\test.ps1
```
Esperado: `26/26 passed`.

- [ ] **Passo 5: Commit**

```powershell
git add game/test/unit/test_input_actions.gd game/scripts/core/input_actions.gd
git commit -m "feat(core): InputActions (input map em codigo)"
```

---

### Tarefa 7: Arena, cena principal e conexão servidor/cliente

**Arquivos:**
- Criar: `game/scripts/arena.gd`
- Criar: `game/scripts/follow_camera.gd`
- Criar: `game/scripts/main.gd`
- Criar: `game/scenes/main.tscn`
- Criar: `tools/run-server.ps1`, `tools/run-clients.ps1`

Ainda sem player: esta tarefa prova que servidor headless sobe, clientes conectam e o `NetworkTime` do netfox sincroniza.

- [ ] **Passo 1: `game/scripts/arena.gd`**

```gdscript
extends Node3D
## Arena provisoria do M0, gerada em codigo para ser identica em servidor e cliente.

const SIZE := 40.0
const GROUND_COLOR := Color(0.55, 0.75, 0.35)
const WALL_COLOR := Color(0.5, 0.5, 0.55)

func _ready() -> void:
	_add_box(Vector3(SIZE, 1.0, SIZE), Vector3(0, -0.5, 0), GROUND_COLOR)
	_add_box(Vector3(2, 2, 2), Vector3(4, 1, -4), WALL_COLOR)
	_add_box(Vector3(2, 2, 6), Vector3(-5, 1, 4), WALL_COLOR)

func _add_box(size: Vector3, pos: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material = material
	mesh_instance.mesh = mesh
	body.add_child(shape)
	body.add_child(mesh_instance)
	add_child(body)
```

- [ ] **Passo 2: `game/scripts/follow_camera.gd`**

```gdscript
extends Camera3D
## Segue o player local (node com nome = peer id deste cliente).

const OFFSET := Vector3(0, 12, 9)

func _ready() -> void:
	global_position = OFFSET
	look_at(Vector3.ZERO, Vector3.UP)

func _process(_delta: float) -> void:
	if multiplayer.is_server():
		return
	var me := get_node_or_null("../Players/%d" % multiplayer.get_unique_id()) as Node3D
	if me == null:
		return
	global_position = me.global_position + OFFSET
	look_at(me.global_position, Vector3.UP)
```

- [ ] **Passo 3: `game/scripts/main.gd` (versão desta tarefa — sem spawn ainda)**

```gdscript
extends Node3D
## Bootstrap: decide servidor ou cliente pelos argumentos e cuida da conexao.

const MAX_PLAYERS := 2

@onready var players: Node3D = $Players
@onready var connect_panel: Control = $UI/ConnectPanel
@onready var address_edit: LineEdit = $UI/ConnectPanel/Address
@onready var connect_button: Button = $UI/ConnectPanel/ConnectButton
@onready var status_label: Label = $UI/Status

func _ready() -> void:
	InputActions.ensure()
	connect_button.pressed.connect(_on_connect_pressed)

	var args := LaunchArgs.parse(OS.get_cmdline_user_args())
	if args["mode"] == "server" or OS.has_feature("dedicated_server"):
		start_server(args["port"])
	elif args["host"] != "":
		start_client(args["host"], args["port"])

func start_server(port: int) -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		push_error("[server] falha ao abrir porta %d: %s" % [port, error_string(err)])
		get_tree().quit(1)
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	connect_panel.hide()
	status_label.text = "servidor na porta %d" % port
	print("[server] escutando na porta %d" % port)
	NetworkTime.start()

func start_client(host: String, port: int) -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(host, port)
	if err != OK:
		status_label.text = "erro ao conectar: %s" % error_string(err)
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	connect_panel.hide()
	status_label.text = "conectando a %s:%d..." % [host, port]
	await multiplayer.connected_to_server
	print("[client] conectado como peer %d" % multiplayer.get_unique_id())
	await NetworkTime.start()
	print("[client] NetworkTime sincronizado, tick %d" % NetworkTime.tick)

func _on_connect_pressed() -> void:
	var args := LaunchArgs.parse(PackedStringArray(["--connect=" + address_edit.text.strip_edges()]))
	start_client(args["host"], args["port"])

func _on_peer_connected(id: int) -> void:
	print("[server] peer %d conectou" % id)

func _on_peer_disconnected(id: int) -> void:
	print("[server] peer %d saiu" % id)

func _on_server_disconnected() -> void:
	status_label.text = "desconectado do servidor"
	connect_panel.show()
```

- [ ] **Passo 4: `game/scenes/main.tscn`**

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/main.gd" id="1_main"]
[ext_resource type="Script" path="res://scripts/arena.gd" id="2_arena"]
[ext_resource type="Script" path="res://scripts/follow_camera.gd" id="3_cam"]

[node name="Main" type="Node3D"]
script = ExtResource("1_main")

[node name="Arena" type="Node3D" parent="."]
script = ExtResource("2_arena")

[node name="Players" type="Node3D" parent="."]

[node name="MultiplayerSpawner" type="MultiplayerSpawner" parent="."]

[node name="Sun" type="DirectionalLight3D" parent="."]
rotation = Vector3(-1, 0.6, 0)
shadow_enabled = true

[node name="Camera" type="Camera3D" parent="."]
current = true
script = ExtResource("3_cam")

[node name="UI" type="CanvasLayer" parent="."]

[node name="Status" type="Label" parent="UI"]
offset_left = 12.0
offset_top = 8.0
offset_right = 700.0
offset_bottom = 34.0
text = "offline"

[node name="ConnectPanel" type="VBoxContainer" parent="UI"]
offset_left = 12.0
offset_top = 48.0
offset_right = 312.0
offset_bottom = 120.0

[node name="Address" type="LineEdit" parent="UI/ConnectPanel"]
layout_mode = 2
text = "127.0.0.1:7000"

[node name="ConnectButton" type="Button" parent="UI/ConnectPanel"]
layout_mode = 2
text = "Conectar"
```

- [ ] **Passo 5: `tools/run-server.ps1`**

```powershell
<#
.SYNOPSIS
  Sobe o servidor dedicado localmente (sem Docker), em headless.
#>
param([int]$Port = 7000)
$ErrorActionPreference = 'Continue'
$game = Join-Path (Split-Path -Parent $PSScriptRoot) 'game'
$cli = $env:GODOT_PATH -replace '\.exe$', '_console.exe'
if (-not (Test-Path $cli)) { $cli = $env:GODOT_PATH }
& $cli --headless --path $game -- --server "--port=$Port"
```

- [ ] **Passo 6: `tools/run-clients.ps1`**

```powershell
<#
.SYNOPSIS
  Abre N clientes lado a lado conectando no servidor. -Autopilot liga o autopilot do 2o em diante.
#>
param(
    [string]$Address = '127.0.0.1:7000',
    [int]$Count = 2,
    [switch]$Autopilot
)
$game = Join-Path (Split-Path -Parent $PSScriptRoot) 'game'
for ($i = 0; $i -lt $Count; $i++) {
    $x = 40 + $i * 980
    $gameArgs = @('--path', "`"$game`"", '--resolution', '960x540', '--position', "$x,80", '--', "--connect=$Address")
    if ($Autopilot -and $i -gt 0) { $gameArgs += '--autopilot' }
    Start-Process -FilePath $env:GODOT_PATH -ArgumentList $gameArgs
}
```

- [ ] **Passo 7: Rodar testes (nada pode ter quebrado)**

```powershell
.\tools\test.ps1
```
Esperado: `26/26 passed`.

- [ ] **Passo 8: Verificação manual — conexão**

Terminal 1:
```powershell
.\tools\run-server.ps1
```
Terminal 2:
```powershell
.\tools\run-clients.ps1
```
Esperado no terminal 1: `[server] escutando na porta 7000`, depois `[server] peer <id> conectou` duas vezes, sem `ERROR`. Duas janelas com a arena verde e os dois blocos cinza; label `conectando...` (vai continuar assim — o status de RTT entra na Tarefa 10). Feche uma janela → servidor imprime `peer <id> saiu`. Abra 3 clientes (`-Count 3`) → o terceiro não conecta (limite de 2).

- [ ] **Passo 9: Commit**

```powershell
git add game/scripts game/scenes tools/run-server.ps1 tools/run-clients.ps1
git commit -m "feat(net): arena, bootstrap servidor/cliente e scripts de execucao"
```

---

### Tarefa 8: Player com movimento por rollback

**Arquivos:**
- Criar: `game/scripts/net/player_input.gd`
- Criar: `game/scripts/net/player.gd`
- Criar: `game/scenes/player.tscn`
- Modificar: `game/scripts/main.gd`

- [ ] **Passo 1: `game/scripts/net/player_input.gd`**

```gdscript
class_name PlayerInput
extends BaseNetInput
## Coleta input do jogador local. O netfox chama _gather so no peer dono deste node.

static var autopilot := false

var movement: Vector3 = Vector3.ZERO
var aim: Vector3 = Vector3.ZERO
var attack: bool = false

func _gather() -> void:
	if autopilot:
		_gather_autopilot()
		return
	var v := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	movement = Vector3(v.x, 0.0, v.y)
	attack = Input.is_action_pressed("attack")
	aim = _mouse_aim()

func _mouse_aim() -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Vector3.ZERO
	var mouse := get_viewport().get_mouse_position()
	var player := get_parent() as Node3D
	return AimMath.aim_on_ground(camera.project_ray_origin(mouse), camera.project_ray_normal(mouse), player.global_position)

func _gather_autopilot() -> void:
	var t := NetworkTime.tick * 0.05
	movement = Vector3(cos(t), 0.0, sin(t))
	aim = movement
	attack = NetworkTime.tick % 45 == 0
```

- [ ] **Passo 2: `game/scripts/net/player.gd` (versão desta tarefa — só movimento)**

```gdscript
class_name Player
extends CharacterBody3D
## Player autoritativo no servidor. O node se chama str(peer_id).

const MAX_HP := 600
const SPEED := 5.0

var hp: int = MAX_HP
var attack_cooldown: int = 0
var peer_id: int = 0

@onready var input: PlayerInput = $Input
@onready var hp_label: Label3D = $HpLabel

var _rollback: RollbackSynchronizer

func _ready() -> void:
	peer_id = name.to_int()
	add_to_group("players")
	set_multiplayer_authority(1)
	input.set_multiplayer_authority(peer_id)

	_rollback = RollbackSynchronizer.new()
	_rollback.name = "RollbackSynchronizer"
	_rollback.root = self
	_rollback.state_properties = [":transform", ":velocity", ":hp", ":attack_cooldown"]
	_rollback.input_properties = ["Input:movement", "Input:aim", "Input:attack"]
	_rollback.enable_input_broadcast = false
	add_child(_rollback)

	var interpolator := TickInterpolator.new()
	interpolator.name = "TickInterpolator"
	interpolator.root = self
	interpolator.properties = [":transform"]
	add_child(interpolator)

	_rollback.process_settings()

func _rollback_tick(_delta: float, _tick: int, _is_fresh: bool) -> void:
	if input.aim != Vector3.ZERO:
		look_at(global_position + input.aim, Vector3.UP)
	velocity = input.movement.normalized() * SPEED
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor

func _process(_delta: float) -> void:
	hp_label.text = "%d / %d" % [hp, MAX_HP]
```

Nota: os nomes de propriedade `root`, `state_properties`, `input_properties`, `enable_input_broadcast` (RollbackSynchronizer) e `root`, `properties` (TickInterpolator) são os da versão do netfox deste plano. Se o Godot acusar `Invalid assignment of property`, abra a ajuda do node no editor (F1 → nome da classe) e use o nome exibido no inspetor.

- [ ] **Passo 3: `game/scenes/player.tscn`**

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/net/player.gd" id="1_player"]
[ext_resource type="Script" path="res://scripts/net/player_input.gd" id="2_input"]

[sub_resource type="CapsuleShape3D" id="CapsuleShape3D_p"]
radius = 0.4
height = 1.8

[sub_resource type="CapsuleMesh" id="CapsuleMesh_p"]
radius = 0.4
height = 1.8

[sub_resource type="BoxMesh" id="BoxMesh_nose"]
size = Vector3(0.2, 0.2, 0.5)

[node name="Player" type="CharacterBody3D"]
script = ExtResource("1_player")

[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
position = Vector3(0, 0.9, 0)
shape = SubResource("CapsuleShape3D_p")

[node name="Body" type="MeshInstance3D" parent="."]
position = Vector3(0, 0.9, 0)
mesh = SubResource("CapsuleMesh_p")

[node name="Nose" type="MeshInstance3D" parent="."]
position = Vector3(0, 1.3, -0.5)
mesh = SubResource("BoxMesh_nose")

[node name="HpLabel" type="Label3D" parent="."]
position = Vector3(0, 2.3, 0)
billboard = 1
text = "600 / 600"

[node name="Input" type="Node" parent="."]
script = ExtResource("2_input")
```

- [ ] **Passo 4: Spawn no `game/scripts/main.gd`**

Adicionar as constantes logo abaixo de `const MAX_PLAYERS := 2`:
```gdscript
const PLAYER_SCENE := "res://scenes/player.tscn"
const SPAWN_POINTS: Array[Vector3] = [Vector3(-8, 0, 0), Vector3(8, 0, 0)]

var _player_scene: PackedScene = preload(PLAYER_SCENE)
```
Adicionar abaixo de `@onready var players: Node3D = $Players`:
```gdscript
@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner
```
Em `_ready()`, logo depois de `InputActions.ensure()`:
```gdscript
	spawner.spawn_path = spawner.get_path_to(players)
	spawner.add_spawnable_scene(PLAYER_SCENE)
```
Substituir `_on_peer_connected` e `_on_peer_disconnected` por:
```gdscript
func _on_peer_connected(id: int) -> void:
	print("[server] peer %d conectou" % id)
	var player := _player_scene.instantiate() as Node3D
	player.name = str(id)
	player.position = SPAWN_POINTS[players.get_child_count() % SPAWN_POINTS.size()]
	players.add_child(player, true)

func _on_peer_disconnected(id: int) -> void:
	print("[server] peer %d saiu" % id)
	var player := players.get_node_or_null(str(id))
	if player:
		player.queue_free()
```

- [ ] **Passo 5: Rodar testes**

```powershell
.\tools\test.ps1
```
Esperado: `26/26 passed`.

- [ ] **Passo 6: Verificação manual — movimento**

```powershell
.\tools\run-server.ps1          # terminal 1
.\tools\run-clients.ps1         # terminal 2
```
Esperado: cada janela mostra duas cápsulas com "600 / 600"; a câmera segue a sua cápsula. Com foco na janela 1, WASD move a cápsula 1 sem atraso perceptível e o "nariz" aponta para o mouse; na janela 2 a cápsula 1 se move suave (interpolada). Obstáculos cinza bloqueiam. Sem `ERROR` no servidor.

- [ ] **Passo 7: Commit**

```powershell
git add game/scripts game/scenes
git commit -m "feat(net): player com movimento por rollback (netfox) e spawn"
```

---

### Tarefa 9: Ataque corpo a corpo validado no servidor

**Arquivos:**
- Modificar: `game/scripts/net/player.gd`

O ataque roda dentro do `_rollback_tick`: o servidor resimula a partir do tick do input, então o acerto usa as posições daquele tick (compensação de lag pelo próprio rollback). O cliente prevê o dano; o estado do servidor corrige.

- [ ] **Passo 1: Constantes de combate**

Abaixo de `const SPEED := 5.0`, adicionar:
```gdscript
const DEFENSE := 30
const ATTACK_DAMAGE := 120
const ATTACK_RANGE := 2.0
const ATTACK_HALF_ANGLE_DEG := 60.0
const ATTACK_COOLDOWN_TICKS := 15  # 0,5 s a 30 Hz
```

- [ ] **Passo 2: Ataque no `_rollback_tick`**

No fim de `_rollback_tick`, depois de `velocity /= NetworkTime.physics_factor`, adicionar:
```gdscript
	if attack_cooldown > 0:
		attack_cooldown -= 1
	elif input.attack:
		attack_cooldown = ATTACK_COOLDOWN_TICKS
		_melee()
```
E adicionar a função:
```gdscript
func _melee() -> void:
	var forward := -global_transform.basis.z
	for node: Node in get_tree().get_nodes_in_group("players"):
		var other := node as Player
		if other == self:
			continue
		if CombatRules.is_in_melee_arc(global_position, forward, other.global_position, ATTACK_RANGE, ATTACK_HALF_ANGLE_DEG):
			other.hp = CombatRules.apply_damage(other.hp, ATTACK_DAMAGE, DEFENSE)
			if other.hp == 0:
				other.hp = MAX_HP  # M0: sem morte, so reinicia o HP
			NetworkRollback.mutate(other)
```

- [ ] **Passo 3: Rodar testes**

```powershell
.\tools\test.ps1
```
Esperado: `26/26 passed`.

- [ ] **Passo 4: Verificação manual — dano**

Servidor + 2 clientes como na Tarefa 8. Leve a cápsula 1 até encostar na 2, mire nela e clique.
Esperado: HP da cápsula 2 cai para **508** nas duas janelas (92 de dano, PRD §4.2); cliques seguidos respeitam ~0,5 s de recarga; de costas ou a mais de 2 u, sem dano; após 7 acertos (600 → 0) volta a 600. Os números são iguais nas duas janelas.

- [ ] **Passo 5: Commit**

```powershell
git add game/scripts/net/player.gd
git commit -m "feat(net): ataque corpo a corpo validado no servidor via rollback"
```

---

### Tarefa 10: HUD de rede e autopilot

**Arquivos:**
- Modificar: `game/scripts/main.gd`

- [ ] **Passo 1: Ligar o autopilot pelos argumentos**

Em `_ready()`, logo depois de `var args := LaunchArgs.parse(OS.get_cmdline_user_args())`:
```gdscript
	PlayerInput.autopilot = args["autopilot"]
```

- [ ] **Passo 2: HUD de RTT e tick**

Adicionar a função em `main.gd`:
```gdscript
func _process(_delta: float) -> void:
	if multiplayer.is_server():
		return
	var peer := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	var rtt := peer.get_peer(1).get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME)
	status_label.text = "peer %d | RTT %d ms | tick %d%s" % [
		multiplayer.get_unique_id(), rtt, NetworkTime.tick, " | AUTOPILOT" if PlayerInput.autopilot else ""]
```

- [ ] **Passo 3: Rodar testes**

```powershell
.\tools\test.ps1
```
Esperado: `26/26 passed`.

- [ ] **Passo 4: Verificação manual — teste solo**

```powershell
.\tools\run-server.ps1                 # terminal 1
.\tools\run-clients.ps1 -Autopilot     # terminal 2
```
Esperado: janela 2 mostra `AUTOPILOT` e sua cápsula anda em círculo atacando a cada 1,5 s; janela 1 mostra `RTT ~0-2 ms | tick` subindo. Você controla a janela 1 e vê a cápsula do autopilot se mover suave.

- [ ] **Passo 5: Commit**

```powershell
git add game/scripts/main.gd
git commit -m "feat(net): HUD de RTT/tick e modo autopilot para teste solo"
```

---

### Tarefa 11: Servidor em Docker com latência simulada

**Arquivos:**
- Criar: `infra/gameserver/Dockerfile`
- Criar: `infra/gameserver/entrypoint.sh`
- Criar: `infra/docker-compose.yml`
- Criar: `.dockerignore`

O servidor roda o binário Linux do Godot direto sobre o projeto (sem export — não precisamos de export templates no M0). `tc netem` atrasa a saída do container: `NETEM_DELAY_MS=100` ≈ +100 ms de RTT.

- [ ] **Passo 1: `.dockerignore` (raiz)**

```
.git
.godot
game/.godot
docs
tools
build
```

- [ ] **Passo 2: `infra/gameserver/Dockerfile`**

```dockerfile
FROM debian:bookworm-slim

ARG GODOT_VERSION=4.7.2

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl unzip iproute2 \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/godot.zip \
      "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" \
 && unzip /tmp/godot.zip -d /tmp/godot \
 && mv "/tmp/godot/Godot_v${GODOT_VERSION}-stable_linux.x86_64" /usr/local/bin/godot \
 && chmod +x /usr/local/bin/godot \
 && rm -rf /tmp/godot /tmp/godot.zip

WORKDIR /game
COPY game/ /game/
RUN godot --headless --path /game --import

COPY infra/gameserver/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 7000/udp
ENTRYPOINT ["/entrypoint.sh"]
```

- [ ] **Passo 3: `infra/gameserver/entrypoint.sh`**

```sh
#!/bin/sh
set -e

if [ -n "$NETEM_DELAY_MS" ]; then
  tc qdisc add dev eth0 root netem \
    delay "${NETEM_DELAY_MS}ms" "${NETEM_JITTER_MS:-0}ms" \
    loss "${NETEM_LOSS_PCT:-0}%"
  echo "[netem] delay=${NETEM_DELAY_MS}ms jitter=${NETEM_JITTER_MS:-0}ms loss=${NETEM_LOSS_PCT:-0}%"
fi

exec godot --headless --path /game -- --server "--port=${PORT:-7000}"
```

- [ ] **Passo 4: `infra/docker-compose.yml`**

```yaml
services:
  gameserver:
    build:
      context: ..
      dockerfile: infra/gameserver/Dockerfile
    ports:
      - "7000:7000/udp"
    cap_add:
      - NET_ADMIN
    environment:
      PORT: "7000"
      NETEM_DELAY_MS: "${NETEM_DELAY_MS:-}"
      NETEM_JITTER_MS: "${NETEM_JITTER_MS:-}"
      NETEM_LOSS_PCT: "${NETEM_LOSS_PCT:-}"
```

- [ ] **Passo 5: Build e subida sem latência**

```powershell
docker compose -f infra/docker-compose.yml up --build
```
Esperado: build termina; log `[server] escutando na porta 7000`. Em outro terminal: `.\tools\run-clients.ps1 -Autopilot` → logs `peer <id> conectou`; HUD com RTT ~1–5 ms. `Ctrl+C` para parar.

- [ ] **Passo 6: Subida com 100 ms e 2% de perda**

```powershell
$env:NETEM_DELAY_MS = 100; $env:NETEM_LOSS_PCT = 2
docker compose -f infra/docker-compose.yml up --build
```
Esperado: log `[netem] delay=100ms jitter=0ms loss=2%`; clientes mostram `RTT ~100 ms`. Depois: `Remove-Item Env:NETEM_DELAY_MS, Env:NETEM_LOSS_PCT`.

- [ ] **Passo 7: Commit**

```powershell
git add .dockerignore infra
git commit -m "feat(infra): game server em Docker com simulacao de latencia (netem)"
```

---

### Tarefa 12: Protocolo do gate e ADR

**Arquivos:**
- Criar: `docs/adr/0001-gate-m0.md`

- [ ] **Passo 1: Criar `docs/adr/0001-gate-m0.md`**

```markdown
# ADR 0001 — Gate do M0: Godot 4 + netfox para ação em rede

**Status:** em teste
**Data do teste:** (preencher)
**Contexto:** PRD §9.1 e §10.3 — seguir com Godot só se movimento com predição e ataque validado no servidor forem jogáveis a 100 ms de RTT.

## Protocolo

Servidor em Docker; 2 clientes via `tools\run-clients.ps1 -Autopilot`; você controla o cliente 1.
Cada cenário roda 10 minutos.

| Cenário | Comando de ambiente |
|---|---|
| A — base | sem variáveis NETEM |
| B — alvo do gate | `$env:NETEM_DELAY_MS=100; $env:NETEM_LOSS_PCT=2` |
| C — estresse | `$env:NETEM_DELAY_MS=200; $env:NETEM_JITTER_MS=30; $env:NETEM_LOSS_PCT=5` |

## Checklist (marcar por cenário: OK / Falhou + observação)

| # | Critério | A | B | C |
|---|---|---|---|---|
| 1 | Movimento próprio responde sem atraso perceptível | | | |
| 2 | Player remoto se move suave, sem teleporte | | | |
| 3 | Sem "borracha" (correção visível da própria posição) ao andar contra obstáculos | | | |
| 4 | Acerto em alcance reduz 92 HP nas duas janelas | | | |
| 5 | Ataque fora do arco/alcance não causa dano | | | |
| 6 | HP idêntico nas duas janelas após 10 min | | | |
| 7 | Servidor sem `ERROR` nos logs | | | |

**Regra de decisão:** B com todos os itens OK → **segue Godot**. Falha em 1, 2, 3 ou 6 no cenário B que não se resolva em até 2 dias de ajuste (tickrate, interpolação, configuração do netfox) → **migrar para Unity** (Fish-Net ou Photon Fusion) antes do M1. C é informativo, não bloqueia.

## Resultado

(preencher: decisão, data, observações)
```

- [ ] **Passo 2: Commit**

```powershell
git add docs/adr/0001-gate-m0.md
git commit -m "docs: protocolo do gate do M0 (ADR 0001)"
```

- [ ] **Passo 3: Executar o protocolo e registrar o resultado**

Rode os cenários A, B e C conforme o ADR, preencha a tabela e a seção *Resultado*, mude o status para `aceito` (segue Godot) ou `rejeitado` (migrar), e:
```powershell
git add docs/adr/0001-gate-m0.md
git commit -m "docs: resultado do gate do M0"
```

---

## Fora do escopo do M0

Modelos KayKit, monstros, XP, itens, zona, backend (contas/matchmaking), deploy no VPS, gravidade/pulo, morte e respawn real. Entram a partir do M1 conforme o PRD.
