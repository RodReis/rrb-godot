<#
.SYNOPSIS
  Cruza os logs da sonda de rede (NetProbe, --probe, F20): servidor x clientes.
.DESCRIPTION
  - Remoto parado: % acumulado da ultima linha "[probe] remoto" de cada cliente.
  - Checkpoints: para cada "[probe] check <tick>" do servidor, compara monstros (HP, fora do mapa)
    e baus abertos de cada cliente no mesmo tick; mostra as primeiras diferencas.
    Neblina (F37): monstro "-" no cliente (fora da visao dele) nao conta; os baus abertos do
    cliente sao o ultimo estado visto, entao basta serem um subconjunto dos do servidor.
  - Neblina: ultima linha "[probe] neblina" de cada cliente (estado recebido escondido deve ser 0).
  - Contagens: "Node not found", "Reference tick ... missing", ERROR e WARNING por arquivo.
  Sai com 1 se houver checkpoint diferente, estado recebido escondido ou "Node not found".
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

# Diferencas monstro a monstro de dois digests "vivos=N baus=M a,b,c|baus" (servidor, cliente).
function Compare-Digest([string]$a, [string]$b) {
    $pa = ($a -split ' ', 3)[2] -split '\|'
    $pb = ($b -split ' ', 3)[2] -split '\|'
    $ma = $pa[0] -split ','
    $mb = $pb[0] -split ','
    $out = @()
    for ($i = 0; $i -lt [Math]::Max($ma.Count, $mb.Count); $i++) {
        if ($mb[$i] -eq '-') { continue }  # fora da visao do cliente (F37)
        if ($ma[$i] -ne $mb[$i]) { $out += "monstro #$($i + 1): servidor $($ma[$i]) x cliente $($mb[$i])" }
    }
    $ca = @($pa[1] -split ',' | Where-Object { $_ })
    $extra = @($pb[1] -split ',' | Where-Object { $_ -and $ca -notcontains $_ })
    if ($extra.Count -gt 0) { $out += "baus abertos so no cliente: [$($extra -join ',')]" }
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
    $fog = Select-String -Path $client -Pattern '\[probe\] neblina: (\d+) .*, (\d+) com estado' | Select-Object -Last 1
    if ($fog) {
        Write-Host "${name}: $($fog.Line.Trim())"
        if ([int]$fog.Matches[0].Groups[2].Value -gt 0) { $failed = $true }
    }
    $same = 0; $diff = 0; $missing = 0; $shown = 0
    foreach ($tick in ($serverChecks.Keys | Sort-Object)) {
        if (-not $checks.ContainsKey($tick)) { $missing++; continue }
        $diffs = @(Compare-Digest $serverChecks[$tick] $checks[$tick])
        if ($diffs.Count -eq 0) { $same++; continue }
        $diff++
        if ($shown -lt $ShowDiffs) {
            $shown++
            Write-Host "  tick ${tick}:"
            $diffs | ForEach-Object { Write-Host "    $_" }
        }
    }
    Write-Host "${name}: checkpoints iguais ao servidor $same, diferentes $diff, sem par $missing"
    if ($diff -gt 0) { $failed = $true }
}
if ($failed) { exit 1 }
