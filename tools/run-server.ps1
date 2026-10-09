<#
.SYNOPSIS
  Sobe o servidor dedicado localmente (sem Docker), em headless.
#>
param([int]$Port = 7000, [int]$Level = 1)  # -Level: argumento de dev ate o F9
$ErrorActionPreference = 'Continue'
$game = Join-Path (Split-Path -Parent $PSScriptRoot) 'game'
$cli = $env:GODOT_PATH -replace '\.exe$', '_console.exe'
if (-not (Test-Path $cli)) { $cli = $env:GODOT_PATH }
& $cli --headless --path $game -- --server "--port=$Port" "--level=$Level"
