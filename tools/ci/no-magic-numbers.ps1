<#
.SYNOPSIS
  Falha se houver literal numerico fora de constante nomeada em scripts de regra pura (I4).
.DESCRIPTION
  Varre *.gd em game/scripts/core e shared/core (ou -Path). Ignora declaracoes `const` e `enum`
  (inclusive multilinha), strings e comentarios. 0 e 1 sao permitidos (indice, limite, unidade).
#>
param([string[]]$Path = @('game/scripts/core', 'shared/core'))

$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$literal = '(?<![\w.])(0x[0-9a-fA-F_]+|0b[01_]+|\d[\d_]*(\.[\d_]*)?([eE][+-]?\d+)?|\.\d[\d_]*([eE][+-]?\d+)?)(?!\w)'
$allowed = @(0.0, 1.0)

function Get-LiteralValue([string]$text) {
    $clean = $text -replace '_', ''
    if ($clean -match '^0x') { return [double][Convert]::ToInt64($clean.Substring(2), 16) }
    if ($clean -match '^0b') { return [double][Convert]::ToInt64($clean.Substring(2), 2) }
    return [double]::Parse($clean, [Globalization.CultureInfo]::InvariantCulture)
}

function Get-Depth([string]$code) {
    return ([regex]::Matches($code, '[\(\[\{]').Count) - ([regex]::Matches($code, '[\)\]\}]').Count)
}

$found = 0
foreach ($dir in $Path) {
    $full = Join-Path $repo $dir
    if (-not (Test-Path $full)) { continue }
    foreach ($file in Get-ChildItem $full -Recurse -Filter *.gd -File) {
        $depth = 0
        $n = 0
        foreach ($raw in Get-Content $file.FullName) {
            $n++
            $code = $raw -replace '"(\\.|[^"\\])*"', '""' -replace "'(\\.|[^'\\])*'", "''"
            $code = ($code -split '#', 2)[0]
            if ($depth -gt 0 -or $code -match '^\s*(const|enum)\b') {
                $depth += Get-Depth $code
                continue
            }
            foreach ($m in [regex]::Matches($code, $literal)) {
                if ($allowed -contains (Get-LiteralValue $m.Value)) { continue }
                $rel = [IO.Path]::GetRelativePath($repo, $file.FullName) -replace '\\', '/'
                Write-Host "${rel}:${n}: literal $($m.Value) fora de constante nomeada (I4)"
                $found++
            }
        }
    }
}
if ($found -gt 0) { Write-Host "FALHA: $found literal(is) em core/." -ForegroundColor Red; exit 1 }
Write-Host 'OK: nenhum literal numerico fora de constante em core/.'
