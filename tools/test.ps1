<#
.SYNOPSIS
  Roda os testes unitarios (GUT) em headless: <modulo>/test/unit e, se ligado, shared/test (ADR-0003).
#>
param([ValidateSet('game', 'launcher')][string]$Module = 'game')
$ErrorActionPreference = 'Continue'   # Godot escreve avisos em stderr
$repo = Split-Path -Parent $PSScriptRoot
$project = Join-Path $repo $Module
if (-not $env:GODOT_PATH) { Write-Host 'GODOT_PATH nao definido. Rode tools\setup-godot-mcp.ps1.' -ForegroundColor Red; exit 1 }
$cli = $env:GODOT_PATH -replace '\.exe$', '_console.exe'
if (-not (Test-Path $cli)) { $cli = $env:GODOT_PATH }
if ((Test-Path (Join-Path $repo 'shared')) -and -not (Test-Path (Join-Path $project 'shared'))) {
    Write-Host "$Module/shared nao existe. Rode tools\link-shared.ps1 (ADR-0003)." -ForegroundColor Red; exit 1
}
$dirs = 'res://test/unit'
if (Test-Path (Join-Path $project 'shared/test')) { $dirs += ',res://shared/test' }

& $cli --headless --path $project --import 2>&1 | Out-Null
$output = & $cli --headless --path $project -s addons/gut/gut_cmdln.gd "-gdir=$dirs" -ginclude_subdirs -gexit 2>&1 | ForEach-Object { "$_" }
$code = $LASTEXITCODE
$output
# GUT ignora script de teste que nao compila e sai 0; tratamos como falha.
if ($code -eq 0 -and ($output -match 'SCRIPT ERROR|Ignoring script')) {
    Write-Host 'FALHA: script com erro (acima) foi ignorado pelo GUT.' -ForegroundColor Red
    exit 1
}
exit $code
