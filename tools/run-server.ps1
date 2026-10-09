<#
.SYNOPSIS
  Sobe o servidor dedicado localmente (sem Docker), em headless.
#>
# -Level: nivel inicial de dev (comeca com o XP do nivel). -Seed: seed dos baus (0 = sorteia).
param([int]$Port = 7000, [int]$Level = 1, [int]$Seed = 0)
$ErrorActionPreference = 'Continue'
$game = Join-Path (Split-Path -Parent $PSScriptRoot) 'game'
$cli = $env:GODOT_PATH -replace '\.exe$', '_console.exe'
if (-not (Test-Path $cli)) { $cli = $env:GODOT_PATH }
& $cli --headless --path $game -- --server "--port=$Port" "--level=$Level" "--seed=$Seed"
