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
$output = & $cli --headless --path $game -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -ginclude_subdirs -gexit 2>&1 | ForEach-Object { "$_" }
$code = $LASTEXITCODE
$output
# GUT ignora script de teste que nao compila e sai 0; tratamos como falha.
if ($code -eq 0 -and ($output -match 'SCRIPT ERROR|Ignoring script')) {
    Write-Host 'FALHA: script com erro (acima) foi ignorado pelo GUT.' -ForegroundColor Red
    exit 1
}
exit $code
