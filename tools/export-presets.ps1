<#
.SYNOPSIS
  Gera game/export_presets.cfg e launcher/export_presets.cfg a partir dos modelos de tools/export/.
  Os .cfg ficam fora do git (GITHUB.md §10); rode uma vez por clone, ou de novo se o modelo mudar.
#>
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
foreach ($module in 'game', 'launcher') {
    $source = Join-Path $repo "tools/export/$module.export_presets.cfg"
    $target = Join-Path $repo "$module/export_presets.cfg"
    Copy-Item $source $target -Force
    Write-Host "ok: $module/export_presets.cfg"
}
