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
