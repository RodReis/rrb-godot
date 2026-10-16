<#
.SYNOPSIS
  Roteiro F23: servidor dedicado + clientes headless contra o backend local, com token de partida.
.DESCRIPTION
  Sobe o servidor com BACKEND_URL/INTERNAL_SECRET/SLOT_PORT, espera, conecta os clientes com --token e
  imprime os codigos de saida (JSON). Os logs ficam em -Out. Precisa do backend no ar e de uma
  partida criada por f23-setup-match.js (-MatchFile). Cliente que ve a tela de fim fica aberto
  esperando o botao "Voltar": "rodando" depois do servidor sair e normal; o que vale e o codigo
  do servidor (0 normal, 3 resultado nao reportado) e, para recusa, o do cliente (2).
#>
param(
    [Parameter(Mandatory)][string]$MatchFile,
    [Parameter(Mandatory)][string]$Out,
    [string]$BackendUrl = 'http://localhost:3000',
    [string]$InternalSecret = $env:INTERNAL_SECRET,
    [int]$Port = 7101,
    # SLOT_PORT: a porta do slot que o backend gravou na partida (f23-setup-match.js usa 7000).
    [int]$SlotPort = 7000,
    # Sobrescreve o token de cada cliente (ex.: 'lixo' ou '' para testar a recusa).
    # '@partida' = o token do JSON da partida; '' = cliente sem token.
    [string]$TokenA = '@partida',
    [string]$TokenB = '@partida',
    [switch]$NoClientB,
    # --time: a partida ja comeca perto do fim (590 s de 600), para fechar em ~40 s.
    [int]$StartTime = 590,
    [int]$ServerWaitSeconds = 150
)
$ErrorActionPreference = 'Continue'
if (-not $InternalSecret) { Write-Host 'Defina INTERNAL_SECRET (o mesmo do backend).' -ForegroundColor Red; exit 1 }
$repo = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$cli = $env:GODOT_PATH -replace '\.exe$', '_console.exe'
if (-not (Test-Path $cli)) { $cli = $env:GODOT_PATH }
$match = Get-Content $MatchFile | ConvertFrom-Json
if ($TokenA -eq '@partida') { $TokenA = $match.tokenA }
if ($TokenB -eq '@partida') { $TokenB = $match.tokenB }
New-Item -ItemType Directory -Force $Out | Out-Null

$savedUrl = $env:BACKEND_URL
$savedSecret = $env:INTERNAL_SECRET
$savedSlot = $env:SLOT_PORT
$env:BACKEND_URL = $BackendUrl
$env:INTERNAL_SECRET = $InternalSecret
$env:SLOT_PORT = "$SlotPort"
$server = Start-Process -FilePath $cli -PassThru -NoNewWindow -ArgumentList @(
    '--headless', '--path', "`"$repo\game`"", '--', '--server', "--port=$Port", '--seed=16', "--time=$StartTime"
) -RedirectStandardOutput "$Out\server.log" -RedirectStandardError "$Out\server.err"
$null = $server.Handle   # PowerShell 5.1: sem isso o ExitCode volta $null
# Os clientes nao recebem o segredo: devolve o ambiente do chamador.
$env:BACKEND_URL = $savedUrl
$env:INTERNAL_SECRET = $savedSecret
$env:SLOT_PORT = $savedSlot
Start-Sleep -Seconds 6

function Start-Client([string]$name, [string]$token) {
    $p = Start-Process -FilePath $cli -PassThru -NoNewWindow -ArgumentList @(
        '--headless', '--path', "`"$repo\game`"", '--', "--connect=127.0.0.1:$Port", "--token=$token", '--autopilot=bot'
    ) -RedirectStandardOutput "$Out\$name.log" -RedirectStandardError "$Out\$name.err"
    $null = $p.Handle
    $p
}
$clientA = Start-Client 'client-a' $TokenA
$clientB = if ($NoClientB) { $null } else { Start-Client 'client-b' $TokenB }

$null = $server.WaitForExit($ServerWaitSeconds * 1000)
Start-Sleep -Seconds 3
$result = [ordered]@{
    server_exited = $server.HasExited
    server_code   = if ($server.HasExited) { $server.ExitCode } else { 'rodando' }
}
foreach ($pair in @(@('client_a', $clientA), @('client_b', $clientB))) {
    $p = $pair[1]
    if ($null -eq $p) { $result[$pair[0]] = 'nao iniciado'; continue }
    if (-not $p.HasExited) { $null = $p.WaitForExit(5000) }
    $result[$pair[0]] = if ($p.HasExited) { $p.ExitCode } else { 'rodando' }
}
foreach ($p in @($server, $clientA, $clientB)) {
    if ($p -and -not $p.HasExited) { & taskkill /T /F /PID $p.Id 2>&1 | Out-Null }
}
$result | ConvertTo-Json
