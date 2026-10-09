# Gera docs/roadmap/index.html (roadmap público, página única com imagens embutidas).
# Fontes: docs/roadmap/historia.json, .proplan/STATUS.md, docs/STATUS.md (§2, §3), docs/design-system/TOKENS.md.
# Uso: .\tools\build-roadmap.ps1            (gera docs/roadmap/index.html)
#      .\tools\build-roadmap.ps1 --fragment <arquivo>   (também gera a versão sem <html>/<head> para publicar como artifact)
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host 'Node 18+ não encontrado no PATH (o mesmo do backend: node -v).' -ForegroundColor Red
    exit 1
}
& node (Join-Path $root 'tools/roadmap/build-roadmap.mjs') @args
exit $LASTEXITCODE
