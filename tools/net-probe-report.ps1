<#
.SYNOPSIS
  Cruza os logs da sonda de rede (NetProbe, --probe, F20): servidor x clientes.
.DESCRIPTION
  - Remoto parado: % acumulado da ultima linha "[probe] remoto" de cada cliente.
  - Checkpoints: para cada "[probe] check <tick>" do servidor, compara monstros (HP, fora do mapa)
    e baus abertos de cada cliente no mesmo tick; mostra as primeiras diferencas.
  - Contagens: "Node not found", "Reference tick ... missing", ERROR e WARNING por arquivo.
  Sai com 1 se houver checkpoint diferente ou "Node not found".
.EXAMPLE
  .\tools\net-probe-report.ps1 -Server logs\server.log -Clients logs\client1.log, logs\client2.log
#>
param(
    [Parameter(Mandatory)][string]$Server,
    [Parameter(Mandatory)][string[]]$Clients,
    [int]$ShowDiffs = 5
)
$ErrorActionPreference = 'Stop'

function Read-Checks([string]$path) {
    $checks = @{}
    foreach ($line in Get-Content $path) {
        if ($line -match '\[probe\] check (\d+) (.*)$') { $checks[[int]$Matches[1]] = $Matches[2].Trim() }
    }
    return $checks
}

function Get-Count([string]$path, [string]$pattern) {
    return @(Select-String -Path $path -Pattern $pattern).Count
}

# Diferencas monstro a monstro de dois digests "vivos=N baus=M a,b,c|baus".
function Compare-Digest([string]$a, [string]$b) {
    $pa = ($a -split ' ', 3)[2] -split '\|'
    $pb = ($b -split ' ', 3)[2] -split '\|'
    $ma = $pa[0] -split ','
    $mb = $pb[0] -split ','
    $out = @()
    for ($i = 0; $i -lt [Math]::Max($ma.Count, $mb.Count); $i++) {
        if ($ma[$i] -ne $mb[$i]) { $out += "monstro #$($i + 1): servidor $($ma[$i]) x cliente $($mb[$i])" }
    }
    if ($pa[1] -ne $pb[1]) { $out += "baus: servidor [$($pa[1])] x cliente [$($pb[1])]" }
    return $out
}

$serverChecks = Read-Checks $Server
$failed = $false
Write-Host "Servidor: $Server ($($serverChecks.Count) checkpoints)"
foreach ($file in @($Server) + $Clients) {
    $notFound = Get-Count $file 'Node not found'
    if ($notFound -gt 0) { $failed = $true }
    "{0}: Node not found {1}, Reference tick missing {2}, ERROR {3}, WARNING {4}" -f `
        (Split-Path -Leaf $file), $notFound, (Get-Count $file 'Reference tick \d+ missing'),
        (Get-Count $file '^ERROR|ERROR:'), (Get-Count $file '^WARNING|WARNING:|WRN') | Write-Host
}
foreach ($client in $Clients) {
    $name = Split-Path -Leaf $client
    $last = Select-String -Path $client -Pattern '\[probe\] remoto' | Select-Object -Last 1
    if ($last) { Write-Host "${name}: $($last.Line.Trim())" } else { Write-Host "${name}: sem linha de remoto" }
    $checks = Read-Checks $client
    $same = 0; $diff = 0; $missing = 0; $shown = 0
    foreach ($tick in ($serverChecks.Keys | Sort-Object)) {
        if (-not $checks.ContainsKey($tick)) { $missing++; continue }
        if ($checks[$tick] -eq $serverChecks[$tick]) { $same++; continue }
        $diff++
        if ($shown -lt $ShowDiffs) {
            $shown++
            Write-Host "  tick ${tick}:"
            Compare-Digest $serverChecks[$tick] $checks[$tick] | ForEach-Object { Write-Host "    $_" }
        }
    }
    Write-Host "${name}: checkpoints iguais ao servidor $same, diferentes $diff, sem par $missing"
    if ($diff -gt 0) { $failed = $true }
}
if ($failed) { exit 1 }
