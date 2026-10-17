<#
.SYNOPSIS
  Abre N clientes lado a lado conectando no servidor. -Autopilot liga o autopilot do 2o em diante.
  -BotPilot: o 1o cliente e jogado pelo BotInput (--autopilot=bot). -Probe liga a sonda de rede
  (NetProbe, F20). -BotPilotAll: todos os clientes sao jogados pelo BotInput (os dois se encontram no
  centro, entao um enxerga o outro sob a neblina; gate do MVP2). -LogDir grava o log de cada cliente em <LogDir>\client<N>.log. -Heroes
  escolhe o heroi de cada cliente jogado pelo BotInput (--bot-hero, na ordem). -IntroReadyDelay
  atrasa o ready da cinematica de abertura de cada cliente, em segundos, na ordem (F69: com um
  valor que passe de 8 s o servidor corta a INTRO). Devolve os processos abertos.
#>
param(
    [string]$Address = '127.0.0.1:7000',
    [int]$Count = 2,
    [switch]$Autopilot,
    [switch]$BotPilot,
    [switch]$BotPilotAll,
    [switch]$Probe,
    [string]$LogDir = '',
    [string[]]$Heroes = @(),
    [double[]]$IntroReadyDelay = @()
)
$game = Join-Path (Split-Path -Parent $PSScriptRoot) 'game'
if ($LogDir) { New-Item -ItemType Directory -Force $LogDir | Out-Null }
for ($i = 0; $i -lt $Count; $i++) {
    $x = 40 + $i * 980
    $gameArgs = @('--path', "`"$game`"", '--resolution', '960x540', '--position', "$x,80")
    if ($LogDir) { $gameArgs += @('--log-file', "`"$(Join-Path $LogDir "client$($i + 1).log")`"") }
    $gameArgs += @('--', "--connect=$Address")
    if ($BotPilotAll -or ($BotPilot -and $i -eq 0)) {
        $gameArgs += '--autopilot=bot'
        if ($i -lt $Heroes.Count) { $gameArgs += "--bot-hero=$($Heroes[$i])" }
    }
    elseif ($Autopilot -and $i -gt 0) { $gameArgs += '--autopilot' }
    if ($Probe) { $gameArgs += '--probe' }
    if ($i -lt $IntroReadyDelay.Count -and $IntroReadyDelay[$i] -gt 0) { $gameArgs += "--intro-ready-delay=$($IntroReadyDelay[$i])" }
    Start-Process -FilePath $env:GODOT_PATH -ArgumentList $gameArgs -PassThru
}
