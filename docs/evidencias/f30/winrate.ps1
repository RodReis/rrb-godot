# Taxa de vitoria por heroi no soak cruzado (F30): so partidas fora do espelho e com vencedor.
# Uso: .\winrate.ps1 <pasta-do-soak>   (le report.csv)
param([Parameter(Mandatory)][string]$Dir)
$rows = Import-Csv (Join-Path $Dir 'report.csv') | Where-Object { $_.hero_a -ne $_.hero_b }
$semVencedor = @($rows | Where-Object { $_.winner_team -eq '' }).Count
$rows = @($rows | Where-Object { $_.winner_team -ne '' })
$heroes = @($rows.hero_a + $rows.hero_b | Sort-Object -Unique)
$heroes | ForEach-Object {
    $h = $_
    $jogos = @($rows | Where-Object { $_.hero_a -eq $h -or $_.hero_b -eq $h })
    $vit = @($jogos | Where-Object { $_.winner_hero -eq $h }).Count
    [pscustomobject]@{ heroi = $h; partidas = $jogos.Count; vitorias = $vit; taxa = [math]::Round(100 * $vit / $jogos.Count, 1) }
} | Sort-Object taxa -Descending | Format-Table -AutoSize
"sem vencedor (fora do denominador): $semVencedor"
