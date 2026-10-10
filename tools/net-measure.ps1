<#
.SYNOPSIS
  Medicao de rede (F20, ADR-0001): servidor em Docker com tc netem + 2 clientes reais com a sonda
  (NetProbe). O 1o cliente e jogado pelo BotInput (farma, abre bau, briga), o 2o anda em circulo;
  cada um mede o outro. Grava server.log, client1.log e client2.log em -OutDir e roda o
  net-probe-report.ps1.
.EXAMPLE
  .\tools\net-measure.ps1 -OutDir logs\b -DelayMs 100 -LossPct 2            # cenario B
  .\tools\net-measure.ps1 -OutDir logs\c -DelayMs 200 -JitterMs 30 -LossPct 5   # cenario C
#>
param(
    [Parameter(Mandatory)][string]$OutDir,
    [int]$DelayMs = 0,
    [int]$JitterMs = 0,
    [int]$LossPct = 0,
    [double]$Minutes = 10,
    [int]$Seed = 20
)
$ErrorActionPreference = 'Continue'
$repo = Split-Path -Parent $PSScriptRoot
$compose = Join-Path $repo 'infra/docker-compose.yml'
New-Item -ItemType Directory -Force $OutDir | Out-Null
$OutDir = (Resolve-Path $OutDir).Path

$env:NETEM_DELAY_MS = if ($DelayMs -gt 0) { "$DelayMs" } else { '' }
$env:NETEM_JITTER_MS = if ($JitterMs -gt 0) { "$JitterMs" } else { '' }
$env:NETEM_LOSS_PCT = if ($LossPct -gt 0) { "$LossPct" } else { '' }
$env:GAME_ARGS = "--probe --seed=$Seed"
$clients = @()
try {
    docker compose -f $compose up --build -d 2>&1 | Select-Object -Last 3
    $deadline = (Get-Date).AddMinutes(2)
    while (-not ((docker compose -f $compose logs gameserver 2>&1) -match 'escutando')) {
        if ((Get-Date) -gt $deadline) { throw 'servidor nao subiu em 2 min' }
        Start-Sleep -Seconds 1
    }
    $clients = & (Join-Path $PSScriptRoot 'run-clients.ps1') -BotPilot -Autopilot -Probe -LogDir $OutDir
    Write-Host "medindo $Minutes min (rtt=$DelayMs jitter=$JitterMs perda=$LossPct%)..."
    Start-Sleep -Seconds ([int]($Minutes * 60))
    docker compose -f $compose logs --no-color gameserver 2>&1 | Out-File -Encoding utf8 (Join-Path $OutDir 'server.log')
    # Banda do servidor na medicao inteira (2 clientes), em kbit/s.
    $bytes = docker compose -f $compose exec -T gameserver cat /sys/class/net/eth0/statistics/tx_bytes /sys/class/net/eth0/statistics/rx_bytes
    $seconds = $Minutes * 60
    "servidor: envio {0:N0} kbit/s, recepcao {1:N0} kbit/s (media de $Minutes min, 2 clientes)" -f `
        ([double]$bytes[0] * 8 / 1000 / $seconds), ([double]$bytes[1] * 8 / 1000 / $seconds) |
        Tee-Object -FilePath (Join-Path $OutDir 'bandwidth.txt')
}
finally {
    $clients | Stop-Process -Force -ErrorAction SilentlyContinue
    docker compose -f $compose down 2>&1 | Select-Object -Last 1
    Remove-Item Env:NETEM_DELAY_MS, Env:NETEM_JITTER_MS, Env:NETEM_LOSS_PCT, Env:GAME_ARGS -ErrorAction SilentlyContinue
}
& (Join-Path $PSScriptRoot 'net-probe-report.ps1') -Server (Join-Path $OutDir 'server.log') `
    -Clients (Join-Path $OutDir 'client1.log'), (Join-Path $OutDir 'client2.log')
