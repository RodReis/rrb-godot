<#
.SYNOPSIS
  Gera o ZIP portatil do jogo (F28, ARCHITECTURE-LAUNCHER §5.1):
    LootStart.exe + LootStart.pck + game/game.exe + game/game.pck + LEIA-ME.txt
  com a URL publica do backend embutida no Launcher (build_config.cfg dentro do .pck).
.EXAMPLE
  .\tools\build-package.ps1 -ApiUrl https://api.exemplo.com -Version v0.3.0
#>
param(
    [Parameter(Mandatory)][ValidatePattern('^https?://[^\s/]+[^\s]*$')][string]$ApiUrl,
    [ValidatePattern('^[A-Za-z0-9._-]+$')][string]$Version = 'dev'
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
if (-not $env:GODOT_PATH) { throw 'GODOT_PATH nao definido. Rode tools\setup-godot-mcp.ps1.' }
$cli = $env:GODOT_PATH -replace '\.exe$', '_console.exe'
if (-not (Test-Path $cli)) { $cli = $env:GODOT_PATH }
foreach ($module in 'game', 'launcher') {
    if (-not (Test-Path (Join-Path $repo "$module/shared"))) { throw "$module/shared nao existe. Rode tools\link-shared.ps1 (ADR-0003)." }
}

& (Join-Path $PSScriptRoot 'export-presets.ps1') | Out-Null

$build = Join-Path $repo 'build'
$package = Join-Path $build 'package'
$zip = Join-Path $build "LootStart-$Version-win64.zip"
Remove-Item $package, $zip -Recurse -Force -ErrorAction SilentlyContinue
foreach ($dir in 'game', 'launcher') { Remove-Item (Join-Path $build $dir) -Recurse -Force -ErrorAction SilentlyContinue }
Remove-Item (Join-Path $build 'LootStart.*'), (Join-Path $build 'launcher.*') -Force -ErrorAction SilentlyContinue
# O Godot exige que a pasta de destino do export ja exista.
New-Item -ItemType Directory -Force (Join-Path $package 'game'), (Join-Path $build 'game') | Out-Null

$config = Join-Path $repo 'launcher/build_config.cfg'
try {
    Set-Content -Path $config -Encoding utf8 -Value "[backend]`nurl=`"$($ApiUrl.TrimEnd('/'))`"`n"
    $ErrorActionPreference = 'Continue'   # Godot escreve avisos em stderr
    foreach ($module in 'game', 'launcher') {
        & $cli --headless --path (Join-Path $repo $module) --import 2>&1 | Out-Null
        $log = & $cli --headless --path (Join-Path $repo $module) --export-release 'Windows' 2>&1 |
            ForEach-Object { "$_" -replace "$([char]27)\[[0-9;]*m", '' }
        $exit = $LASTEXITCODE
        $log | Select-Object -Last 4
        # Linha de erro do Godot comeca com "ERROR:" (nome de arquivo com "error" nao conta).
        if ($exit -ne 0 -or ($log -cmatch '^ERROR:')) { throw "Export de $module falhou (log acima)." }
    }
    $ErrorActionPreference = 'Stop'
}
finally {
    Remove-Item $config -Force -ErrorAction SilentlyContinue
}

Copy-Item (Join-Path $build 'LootStart.exe'), (Join-Path $build 'LootStart.pck') $package
Copy-Item (Join-Path $build 'game/game.exe'), (Join-Path $build 'game/game.pck') (Join-Path $package 'game')
Copy-Item (Join-Path $PSScriptRoot 'export/LEIA-ME.txt') $package
Compress-Archive -Path (Join-Path $package '*') -DestinationPath $zip -Force
Get-Item $zip | ForEach-Object { Write-Host ("ok: {0} ({1:N1} MB)" -f $_.FullName, ($_.Length / 1MB)) }
