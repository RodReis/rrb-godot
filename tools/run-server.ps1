<#
.SYNOPSIS
  Sobe o servidor dedicado localmente (sem Docker), em headless.
#>
# -Level: nivel inicial de dev (comeca com o XP do nivel). -Seed: seed dos baus (0 = sorteia).
# -Time: relogio da partida comeca em N segundos (dev; 200 = boss em 10 s). -Probe: sonda de rede (F20).
# -DayNight day|night: forca o inicio da luz (F49); vazio = sentido sorteado pela seed.
# Por padrao sobe com --no-backend (F23): qualquer peer entra e o resultado nao e reportado. -WithBackend
# exige BACKEND_URL e INTERNAL_SECRET no ambiente e so aceita cliente com --token de partida.
param([int]$Port = 7000, [int]$Level = 1, [int]$Seed = 0, [int]$Time = 0, [switch]$Probe, [switch]$WithBackend, [ValidateSet('', 'day', 'night')][string]$DayNight = '')
$ErrorActionPreference = 'Continue'
$game = Join-Path (Split-Path -Parent $PSScriptRoot) 'game'
$cli = $env:GODOT_PATH -replace '\.exe$', '_console.exe'
if (-not (Test-Path $cli)) { $cli = $env:GODOT_PATH }
$extra = @()
if (-not $WithBackend) { $extra += '--no-backend' }
if ($Probe) { $extra += '--probe' }
if ($DayNight) { $extra += "--daynight=$DayNight" }
& $cli --headless --path $game -- --server "--port=$Port" "--level=$Level" "--seed=$Seed" "--time=$Time" @extra
