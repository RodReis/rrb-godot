<#
.SYNOPSIS
  Cria as junctions <modulo>/shared -> ..\shared nos projetos Godot existentes (ADR-0003). Idempotente.
#>
$repo = Split-Path -Parent $PSScriptRoot
$shared = Join-Path $repo 'shared'
foreach ($module in 'game', 'launcher') {
    $project = Join-Path $repo $module
    if (-not (Test-Path (Join-Path $project 'project.godot'))) { continue }
    $link = Join-Path $project 'shared'
    $item = Get-Item $link -Force -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType) { Write-Host "ok: $module/shared ja ligado"; continue }
    if ($item) { Write-Host "ERRO: $link existe e nao e junction; apague e rode de novo." -ForegroundColor Red; exit 1 }
    New-Item -ItemType Junction -Path $link -Target $shared | Out-Null
    Write-Host "criado: $module/shared -> ..\shared"
}
