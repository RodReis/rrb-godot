<#
.SYNOPSIS
  Abre N clientes lado a lado conectando no servidor. -Autopilot liga o autopilot do 2o em diante.
  -BotPilot: o 1o cliente e jogado pelo BotInput (--autopilot=bot). -Probe liga a sonda de rede
  (NetProbe, F20). -LogDir grava o log de cada cliente em <LogDir>\client<N>.log. Devolve os
  processos abertos.
#>
param(
    [string]$Address = '127.0.0.1:7000',
    [int]$Count = 2,
    [switch]$Autopilot,
    [switch]$BotPilot,
    [switch]$Probe,
    [string]$LogDir = ''
)
$game = Join-Path (Split-Path -Parent $PSScriptRoot) 'game'
if ($LogDir) { New-Item -ItemType Directory -Force $LogDir | Out-Null }
for ($i = 0; $i -lt $Count; $i++) {
    $x = 40 + $i * 980
    $gameArgs = @('--path', "`"$game`"", '--resolution', '960x540', '--position', "$x,80")
    if ($LogDir) { $gameArgs += @('--log-file', "`"$(Join-Path $LogDir "client$($i + 1).log")`"") }
    $gameArgs += @('--', "--connect=$Address")
    if ($BotPilot -and $i -eq 0) { $gameArgs += '--autopilot=bot' }
    elseif ($Autopilot -and $i -gt 0) { $gameArgs += '--autopilot' }
    if ($Probe) { $gameArgs += '--probe' }
    Start-Process -FilePath $env:GODOT_PATH -ArgumentList $gameArgs -PassThru
}
