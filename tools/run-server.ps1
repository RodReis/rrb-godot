<#
.SYNOPSIS
  Sobe o servidor dedicado localmente (sem Docker), em headless.
#>
# -Level: nivel inicial de dev (comeca com o XP do nivel). -Seed: seed dos baus (0 = sorteia).
# -Time: relogio da partida comeca em N segundos (dev; 200 = boss em 10 s). -Probe: sonda de rede (F20).
# -DayNight day|night: forca o inicio da luz (F49); vazio = sentido sorteado pela seed.
param([int]$Port = 7000, [int]$Level = 1, [int]$Seed = 0, [int]$Time = 0, [switch]$Probe, [ValidateSet('', 'day', 'night')][string]$DayNight = '')
$ErrorActionPreference = 'Continue'
$game = Join-Path (Split-Path -Parent $PSScriptRoot) 'game'
$cli = $env:GODOT_PATH -replace '\.exe$', '_console.exe'
if (-not (Test-Path $cli)) { $cli = $env:GODOT_PATH }
$extra = @()
if ($Probe) { $extra += '--probe' }
if ($DayNight) { $extra += "--daynight=$DayNight" }
& $cli --headless --path $game -- --server "--port=$Port" "--level=$Level" "--seed=$Seed" "--time=$Time" @extra
