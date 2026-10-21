<#
.SYNOPSIS
  Soak (F19): N partidas bot x bot headless no servidor dedicado (--server --bots), em tempo real.
.DESCRIPTION
  Cobre todos os confrontos entre os herois (espelhos incluidos) em rodadas; a cada rodada impar os
  lados trocam. Falha (exit 1) se alguma partida: nao terminar com codigo 0, passar de 10:00 de
  jogo, terminar sem vencedor ou como abandoned (bots nunca desconectam), ou nao imprimir o fim.
  Grava <Out>\match-NN.log, report.csv e report.json (duracao, vencedor, razao do fim, nivel de cada
  heroi aos 5:00) e imprime o resumo.
  O relogio do netfox e o do sistema: uma partida leva ate ~10 min; use -Parallel (cada servidor
  usa ~0,3 nucleo e ~350 MB). Compativel com PowerShell 5.1 e 7.
.PARAMETER Count
  Partidas (padrao 50; com 6 herois sao 21 confrontos).
.PARAMETER Require
  Heroi que entra em todo confronto (soak de heroi novo: -Require engineer); vazio = todos os pares.
.PARAMETER Parallel
  Servidores ao mesmo tempo.
.PARAMETER BotLevels
  Nivel do bot de cada lado, "a,b" (F81, --bot-levels): 1 Facil, 2 Medio, 3 Dificil. Vazio = Medio nos dois.
  Os lados trocam de heroi, nao de nivel: compare com a linha-base "2,2" para descontar o lado.
.PARAMETER Seed
  Seed da partida 0; a partida k usa Seed + k (baus e sorteio do colapso).
.PARAMETER BasePort
  Porta UDP da partida 0; a partida k usa BasePort + k.
.PARAMETER StartTime
  Segundos em que o relogio ja comeca (dev, --time): so para fumaca local; vale > 0 desliga o
  criterio de nivel aos 5:00.
.PARAMETER WallSeconds
  Limite real por partida; estourou, o processo e morto e a partida falha.
#>
param(
    [int]$Count = 50,
    [int]$Parallel = 6,
    [string[]]$Heroes = @('knight', 'ranger', 'barbarian', 'fire_wizard', 'rogue', 'engineer', 'druid', 'berserker', 'occultist', 'paladin', 'carrasco'),
    [string]$Require = '',
    [string]$BotLevels = '',
    [int]$Seed = 1,
    [int]$BasePort = 7100,
    [int]$StartTime = 0,
    [int]$WallSeconds = 900,
    [string]$Out = 'soak-report',
    [switch]$SkipImport
)
$ErrorActionPreference = 'Continue'
$repo = Split-Path -Parent $PSScriptRoot
$game = Join-Path $repo 'game'
if (-not $env:GODOT_PATH) { Write-Host 'GODOT_PATH nao definido. Rode tools\setup-godot-mcp.ps1.' -ForegroundColor Red; exit 1 }
$cli = $env:GODOT_PATH -replace '\.exe$', '_console.exe'
if (-not (Test-Path $cli)) { $cli = $env:GODOT_PATH }
if (-not (Test-Path (Join-Path $game 'shared'))) {
    Write-Host 'game/shared nao existe. Rode tools\link-shared.ps1 (ADR-0003).' -ForegroundColor Red; exit 1
}

# Constantes do jogo espelhadas aqui (main.gd BOT_ID_TEAM_A / BOT_ID; match_pacing.tres).
$PeerTeamA = 3
$PeerTeamB = 2
$MaxDuration = 600.0
$DurationSlack = 0.05
$IsWindowsHost = [Environment]::OSVersion.Platform -eq 'Win32NT'

if (-not [IO.Path]::IsPathRooted($Out)) { $Out = Join-Path (Get-Location) $Out }
$Out = [IO.Path]::GetFullPath($Out)
New-Item -ItemType Directory -Force $Out | Out-Null
Get-ChildItem $Out -Filter 'match-*.log' -ErrorAction SilentlyContinue | Remove-Item -Force

if (-not $SkipImport) { & $cli --headless --path $game --import 2>&1 | Out-Null }

# Confrontos: todos os pares (i <= j) dos herois, na ordem; a partida k pega o par k % n.
$pairs = @()
for ($i = 0; $i -lt $Heroes.Count; $i++) {
    for ($j = $i; $j -lt $Heroes.Count; $j++) {
        if ($Require -and $Heroes[$i] -ne $Require -and $Heroes[$j] -ne $Require) { continue }
        $pairs += , @($Heroes[$i], $Heroes[$j])
    }
}
$plan = @()
for ($k = 0; $k -lt $Count; $k++) {
    $pair = $pairs[$k % $pairs.Count]
    $round = [math]::Floor($k / $pairs.Count)
    $a = $pair[0]; $b = $pair[1]
    if ($round % 2 -eq 1) { $a = $pair[1]; $b = $pair[0] }
    $plan += [pscustomobject]@{ Index = $k; HeroA = $a; HeroB = $b; Seed = $Seed + $k; Port = $BasePort + $k }
}

function Stop-Tree([int]$ProcessId) {
    if ($IsWindowsHost) { & taskkill /T /F /PID $ProcessId 2>&1 | Out-Null }
    else { Stop-Process -Id $ProcessId -Force -ErrorAction SilentlyContinue }
}

function Start-Match($m) {
    $log = Join-Path $Out ('match-{0:D2}.log' -f $m.Index)
    $err = "$log.err"
    $argList = @(
        '--headless', '--path', "`"$game`"", '--', '--server', '--no-backend', '--bots',
        "--bot-heroes=$($m.HeroA),$($m.HeroB)", "--port=$($m.Port)", "--seed=$($m.Seed)",
        "--time=$StartTime"
    )
    if ($BotLevels) { $argList += "--bot-levels=$BotLevels" }
    $p = Start-Process -FilePath $cli -ArgumentList $argList -PassThru -NoNewWindow `
        -RedirectStandardOutput $log -RedirectStandardError $err
    # PowerShell 5.1: sem tocar no Handle agora, ExitCode volta $null depois que o processo sai.
    $null = $p.Handle
    [pscustomobject]@{ Match = $m; Process = $p; Log = $log; Err = $err; Started = Get-Date }
}

# Le o log de uma partida pronta e devolve a linha do relatorio com o veredito.
function Read-Match($run) {
    $m = $run.Match
    $row = [ordered]@{
        match = $m.Index; seed = $m.Seed; hero_a = $m.HeroA; hero_b = $m.HeroB
        winner_team = ''; winner_hero = ''; reason = ''; duration_s = ''
        level5_a = ''; level5_b = ''; kills_a = ''; kills_b = ''; final_level_a = ''; final_level_b = ''
        wall_s = [math]::Round(((Get-Date) - $run.Started).TotalSeconds); exit = ''; verdict = 'OK'; why = ''
    }
    $problems = @()
    $lines = @(Get-Content $run.Log -ErrorAction SilentlyContinue)
    if ($run.TimedOut) { $problems += "estourou $WallSeconds s reais" }
    else {
        $row.exit = $run.Process.ExitCode
        if ($run.Process.ExitCode -ne 0) { $problems += "saida $($run.Process.ExitCode)" }
    }
    # O Godot escreve SCRIPT ERROR / ERROR em stderr (e algumas vezes em stdout).
    $errLines = @(Get-Content $run.Err -ErrorAction SilentlyContinue) + $lines
    $scriptErrors = @($errLines | Where-Object { $_ -match '^SCRIPT ERROR' }).Count
    if ($scriptErrors -gt 0) { $problems += "$scriptErrors SCRIPT ERROR" }
    foreach ($line in $lines) {
        if ($line -match '^\[match\] bot (\d+): Nv (\d+), \d+ XP') {
            if ([int]$Matches[1] -eq $PeerTeamA) { $row.level5_a = [int]$Matches[2] } else { $row.level5_b = [int]$Matches[2] }
        }
    }
    $end = $lines | Where-Object { $_ -like '`[soak`] *' } | Select-Object -Last 1
    if (-not $end) { $problems += 'sem a linha [soak] do fim' }
    else {
        $json = ($end -replace '^\[soak\] ', '') | ConvertFrom-Json
        $row.reason = $json.reason
        $row.duration_s = [math]::Round([double]$json.stats.duration, 1)
        if ($json.winner -eq $PeerTeamA) { $row.winner_team = 'A'; $row.winner_hero = $m.HeroA }
        elseif ($json.winner -eq $PeerTeamB) { $row.winner_team = 'B'; $row.winner_hero = $m.HeroB }
        foreach ($pl in $json.stats.players) {
            if ($pl.peer -eq $PeerTeamA) { $row.kills_a = $pl.kills; $row.final_level_a = $pl.level }
            else { $row.kills_b = $pl.kills; $row.final_level_b = $pl.level }
        }
        if ($row.winner_team -eq '') { $problems += 'sem vencedor (I2)' }
        if ($json.reason -eq 'abandoned') { $problems += 'abandoned: bot nao desconecta' }
        if ([double]$json.stats.duration -gt ($MaxDuration + $DurationSlack)) { $problems += "passou de 10:00 ($($json.stats.duration) s) (I1)" }
    }
    if ($problems.Count -gt 0) { $row.verdict = 'FALHA'; $row.why = $problems -join '; ' }
    [pscustomobject]$row
}

Write-Host ("Soak: {0} partidas, {1} em paralelo, herois {2}, seed {3}, saida {4}" -f $Count, $Parallel, ($Heroes -join '/'), $Seed, $Out)
$queue = New-Object System.Collections.Queue
$plan | ForEach-Object { $queue.Enqueue($_) }
$running = New-Object System.Collections.ArrayList
$rows = New-Object System.Collections.ArrayList
$watch = [Diagnostics.Stopwatch]::StartNew()
while ($queue.Count -gt 0 -or $running.Count -gt 0) {
    while ($queue.Count -gt 0 -and $running.Count -lt $Parallel) {
        [void]$running.Add((Start-Match $queue.Dequeue()))
    }
    Start-Sleep -Seconds 2
    foreach ($run in @($running)) {
        $run | Add-Member -NotePropertyName TimedOut -NotePropertyValue $false -Force
        $overdue = ((Get-Date) - $run.Started).TotalSeconds -gt $WallSeconds
        if ($overdue -and -not $run.Process.HasExited) {
            Stop-Tree $run.Process.Id
            $run.TimedOut = $true
            [void]$run.Process.WaitForExit(10000)
        }
        if ($run.Process.HasExited) {
            [void]$running.Remove($run)
            $row = Read-Match $run
            [void]$rows.Add($row)
            $color = if ($row.verdict -eq 'OK') { 'Green' } else { 'Red' }
            Write-Host ("[{0,5:N0}s] #{1:D2} {2} x {3} -> {4} ({5}), {6} s de jogo, Nv5:00 {7}/{8} {9} {10}" -f `
                $watch.Elapsed.TotalSeconds, $row.match, $row.hero_a, $row.hero_b, $row.winner_hero, $row.reason, `
                $row.duration_s, $row.level5_a, $row.level5_b, $row.verdict, $row.why) -ForegroundColor $color
        }
    }
}

$sorted = @($rows | Sort-Object match)
$sorted | Export-Csv -Path (Join-Path $Out 'report.csv') -NoTypeInformation -Encoding UTF8
$sorted | ConvertTo-Json -Depth 3 | Set-Content -Path (Join-Path $Out 'report.json') -Encoding UTF8

$failed = @($sorted | Where-Object { $_.verdict -ne 'OK' })
$finished = @($sorted | Where-Object { $_.reason -ne '' })
$durations = @($finished | ForEach-Object { [double]$_.duration_s })
Write-Host ''
Write-Host ("Terminadas: {0}/{1}; com vencedor: {2}; falhas: {3}" -f $finished.Count, $Count, @($sorted | Where-Object { $_.winner_team -ne '' }).Count, $failed.Count)
if ($durations.Count -gt 0) {
    $measured = $durations | Measure-Object -Average -Maximum -Minimum
    Write-Host ("Duracao de jogo: min {0:N0} s, media {1:N0} s, max {2:N0} s (limite {3:N0} s)" -f $measured.Minimum, $measured.Average, $measured.Maximum, $MaxDuration)
}
Write-Host 'Razao do fim:'
$finished | Group-Object reason | Sort-Object Count -Descending | ForEach-Object { Write-Host ("  {0,-17} {1}" -f $_.Name, $_.Count) }
Write-Host 'Vitorias por lado (A = spawn SO, B = NE):'
$finished | Group-Object winner_team | ForEach-Object { Write-Host ("  {0}: {1}" -f $_.Name, $_.Count) }
if ($StartTime -eq 0) {
    Write-Host 'Nivel aos 5:00 por heroi (media, min-max):'
    foreach ($hero in $Heroes) {
        $levels = @()
        foreach ($r in $sorted) {
            if ($r.hero_a -eq $hero -and $r.level5_a -ne '') { $levels += [int]$r.level5_a }
            if ($r.hero_b -eq $hero -and $r.level5_b -ne '') { $levels += [int]$r.level5_b }
        }
        if ($levels.Count -gt 0) {
            $s = $levels | Measure-Object -Average -Minimum -Maximum
            Write-Host ("  {0,-12} {1:N1}  ({2}-{3}, {4} amostras)" -f $hero, $s.Average, $s.Minimum, $s.Maximum, $levels.Count)
        }
    }
}
Write-Host ("Tempo total: {0:N0} s. Relatorio: {1}" -f $watch.Elapsed.TotalSeconds, $Out)
if ($failed.Count -gt 0 -or $finished.Count -ne $Count) {
    Write-Host 'SOAK FALHOU' -ForegroundColor Red
    exit 1
}
Write-Host ("SOAK OK: {0}/{0} terminadas, todas <= 10:00, todas com vencedor" -f $Count) -ForegroundColor Green
exit 0
