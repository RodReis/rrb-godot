<#
.SYNOPSIS
  Bake do LightmapGI da arena (F38, ADR-0006 D-V6): passo de build reprodutivel, nao manual.
  Abre o editor (janela, precisa de GPU; nao roda em CI/headless), aperta o bake do plugin do
  LightmapGI (tools/arena/bake_lightmap.gd) e regera a cena pelo builder, que liga o .lmbake.
  Rode depois de mudar a arena (tools/arena/build_arena.gd ou os .glb do Blender).
  Uso (na raiz): .\tools\bake-lightmap.ps1
  Saida: game/scenes/arena/ilha_arcana.lmbake + textura .exr (versionados) e a cena regerada.
#>
param(
    [string]$Scene = 'res://scenes/arena/ilha_arcana.tscn',
    [int]$TimeoutSec = 300
)
$ErrorActionPreference = 'Continue'   # Godot escreve avisos em stderr (APRENDIZADOS)
$repo = Split-Path -Parent $PSScriptRoot
$project = Join-Path $repo 'game'
if (-not $env:GODOT_PATH) { Write-Host 'GODOT_PATH nao definido. Rode tools\setup-godot-mcp.ps1.' -ForegroundColor Red; exit 1 }
$cli = $env:GODOT_PATH -replace '\.exe$', '_console.exe'
if (-not (Test-Path $cli)) { $cli = $env:GODOT_PATH }

# Cena temporaria dentro do projeto (o editor so abre cena de res://); ignorada no git.
$tmpName = '_lightmap_bake'
$tmp = Join-Path $project $tmpName
New-Item -ItemType Directory -Force $tmp | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'arena\bake_lightmap.gd') (Join-Path $tmp 'bake_lightmap.gd') -Force
@"
[gd_scene format=3]

[ext_resource type="Script" path="res://$tmpName/bake_lightmap.gd" id="1_bake"]

[node name="LightmapBake" type="Node"]
script = ExtResource("1_bake")
"@ | ForEach-Object { [IO.File]::WriteAllText((Join-Path $tmp 'bake_lightmap.tscn'), $_) }

$log = Join-Path $repo 'logs\bake-lightmap.log'
New-Item -ItemType Directory -Force (Split-Path $log) | Out-Null
$ok = $false
try {
    & $cli --headless --path $project --import 2>&1 | Out-Null
    $proc = Start-Process -FilePath $cli -PassThru -NoNewWindow -RedirectStandardOutput $log -RedirectStandardError "$log.err" `
        -ArgumentList @('-e', '--path', "`"$project`"", "res://$tmpName/bake_lightmap.tscn", '--', '--bake-lightmap', "--scene=$Scene")
    if (-not $proc.WaitForExit($TimeoutSec * 1000)) {
        taskkill /T /F /PID $proc.Id | Out-Null; Write-Host "bake passou de $TimeoutSec s; processo encerrado" -ForegroundColor Red
    }
    $out = (Get-Content $log, "$log.err" -ErrorAction SilentlyContinue) -join "`n"
    ($out -split "`n") | Select-String '\[bake\]'
    $ok = $out -match '\[bake\] OK'
} finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
if (-not $ok) { Write-Host "bake falhou; log em $log" -ForegroundColor Red; exit 1 }

# O builder regera a cena e liga o .lmbake (nada salvo pelo editor).
& $cli --headless --path $project -s (Join-Path $repo 'tools\arena\build_arena.gd') 2>&1 | Select-String '\[arena\]'
if ($LASTEXITCODE -ne 0) { Write-Host 'builder falhou' -ForegroundColor Red; exit 1 }
& $cli --headless --path $project --import 2>&1 | Out-Null
Write-Host 'bake OK' -ForegroundColor Green
