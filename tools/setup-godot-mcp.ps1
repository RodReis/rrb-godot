<#
.SYNOPSIS
  Configura Godot + godot-mcp para o projeto rrb-godot (Windows).

.DESCRIPTION
  1. Localiza o Godot em -GodotDir (usa o .exe principal, nao o _console).
  2. Confere Node.js >= 18 (instala o LTS via winget se faltar e -InstallNode for passado).
  3. Grava GODOT_PATH como variavel de ambiente do usuario.
  4. Pre-baixa @coding-solo/godot-mcp no cache do npm.
  5. Importa o projeto uma vez (gera .godot/) e roda um smoke test headless.
  6. (-ClaudeDesktop) registra o servidor "godot" no claude_desktop_config.json (com backup).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools\setup-godot-mcp.ps1 -ClaudeDesktop
#>
[CmdletBinding()]
param(
    [string]$GodotDir = 'C:\Desenv\engine\godot',
    [string]$McpPackage = '@coding-solo/godot-mcp@0.1.1',
    [switch]$InstallNode,
    [switch]$ClaudeDesktop
)

$ErrorActionPreference = 'Stop'
$ProjectDir = Split-Path -Parent $PSScriptRoot

function Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "    OK  $msg" -ForegroundColor Green }
function Fail($msg) { Write-Host "    ERRO $msg" -ForegroundColor Red; exit 1 }

# No PowerShell 5.1, stderr de executavel nativo + ErrorAction Stop vira excecao.
# Godot escreve avisos em stderr, entao chamadas nativas passam por aqui.
function Invoke-Native([string]$Exe, [string[]]$Arguments) {
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { & $Exe @Arguments 2>&1 | ForEach-Object { "$_" } }
    finally { $ErrorActionPreference = $old }
}

# --- 1. Godot -------------------------------------------------------------
Step "Procurando Godot em $GodotDir"
if (-not (Test-Path $GodotDir)) { Fail "Pasta nao existe: $GodotDir" }

$all = Get-ChildItem -Path $GodotDir -Filter 'Godot*.exe' -File
$gui = $all | Where-Object { $_.Name -notmatch '_console\.exe$' } | Sort-Object Name -Descending | Select-Object -First 1
if (-not $gui) { Fail "Nenhum Godot*.exe encontrado em $GodotDir. Baixe em https://godotengine.org/download/windows/" }
$console = Join-Path $GodotDir ($gui.BaseName + '_console.exe')
if (-not (Test-Path $console)) { $console = $null }

# O executavel principal e o que vai para GODOT_PATH: o godot-mcp mata o processo
# que ele mesmo criou no stop_project; com o wrapper _console, o jogo ficaria orfao.
$godotExe = $gui.FullName
Ok "GODOT_PATH -> $godotExe"

# Para chamadas de linha de comando neste script, o _console espera e mostra a saida.
$cliExe = if ($console) { $console } else { $godotExe }
$version = (Invoke-Native $cliExe @('--version') | Where-Object { $_ -match '^\d+\.\d+' } | Select-Object -Last 1)
if (-not $version) { Fail "Nao consegui executar '$cliExe --version'" }
Ok "Versao: $version"

# --- 2. Node.js -----------------------------------------------------------
Step "Conferindo Node.js (>= 18)"
$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) {
    if ($InstallNode) {
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { Fail "winget indisponivel. Instale o Node.js LTS manualmente: https://nodejs.org" }
        winget install --id OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements
        $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
        $node = Get-Command node -ErrorAction SilentlyContinue
        if (-not $node) { Fail "Node instalado, mas nao esta no PATH desta sessao. Abra outro terminal e rode o script de novo." }
    } else {
        Fail "Node.js nao encontrado. Rode de novo com -InstallNode ou instale o LTS: https://nodejs.org"
    }
}
$nodeVer = ((Invoke-Native 'node' @('--version')) | Select-Object -Last 1).Trim().TrimStart('v')
if ([int]($nodeVer.Split('.')[0]) -lt 18) { Fail "Node $nodeVer e antigo; godot-mcp exige >= 18." }
if (-not (Get-Command npx -ErrorAction SilentlyContinue)) { Fail "npx nao encontrado no PATH." }
Ok "Node $nodeVer"

# --- 3. GODOT_PATH --------------------------------------------------------
Step "Gravando GODOT_PATH (variavel de usuario)"
[Environment]::SetEnvironmentVariable('GODOT_PATH', $godotExe, 'User')
$env:GODOT_PATH = $godotExe
Ok "GODOT_PATH=$godotExe (terminais/apps abertos antes disso precisam ser reabertos)"

# --- 4. godot-mcp ---------------------------------------------------------
Step "Baixando $McpPackage para o cache do npm"
Invoke-Native 'npm' @('cache', 'add', $McpPackage) | Out-Null
if ($LASTEXITCODE -ne 0) { Fail "npm cache add falhou (rede/proxy?)." }
Ok "$McpPackage em cache"

# --- 5. Import + smoke test ----------------------------------------------
Step "Importando o projeto (gera .godot/)"
Invoke-Native $cliExe @('--headless', '--path', $ProjectDir, '--editor', '--quit') | Out-Null
Ok "Import concluido"

Step "Smoke test: roda a cena principal por 120 frames, sem janela"
$out = Invoke-Native $cliExe @('--headless', '--path', $ProjectDir, '--quit-after', '120') | Out-String
$errors = ($out -split "`r?`n") | Where-Object { $_ -match '^\s*(SCRIPT )?ERROR' }
if ($errors) { Write-Host $out; Fail "O projeto rodou com erros (acima)." }
Ok "Cena principal rodou sem erros"

# --- 6. .mcp.json do Claude Code (escopo de projeto) ----------------------
$mcpJson = Join-Path $ProjectDir '.mcp.json'
if (Test-Path $mcpJson) {
    Ok ".mcp.json ja existe - mantido como esta"
} else {
    Step "Criando .mcp.json (servidor 'godot' para o Claude Code)"
    $mcpContent = @"
{
  "mcpServers": {
    "godot": {
      "type": "stdio",
      "command": "cmd",
      "args": ["/c", "npx", "-y", "$McpPackage"]
    }
  }
}
"@
    [IO.File]::WriteAllText($mcpJson, $mcpContent.Replace("`r`n", "`n") + "`n", (New-Object System.Text.UTF8Encoding $false))
    Ok "Criado $mcpJson (GODOT_PATH vem da variavel de ambiente)"
}

# --- 7. Claude Desktop (opcional) -----------------------------------------
if ($ClaudeDesktop) {
    Step "Registrando 'godot' no Claude Desktop"
    $cfgDir = Join-Path $env:APPDATA 'Claude'
    $cfgFile = Join-Path $cfgDir 'claude_desktop_config.json'
    if (-not (Test-Path $cfgDir)) { New-Item -ItemType Directory -Path $cfgDir | Out-Null }

    if (Test-Path $cfgFile) {
        $raw = [IO.File]::ReadAllText($cfgFile)
        $backup = "$cfgFile.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
        Copy-Item $cfgFile $backup
        Ok "Backup: $backup"
        if ([string]::IsNullOrWhiteSpace($raw)) { $cfg = [pscustomobject]@{} } else { $cfg = $raw | ConvertFrom-Json }
    } else {
        $cfg = [pscustomobject]@{}
    }

    if (-not ($cfg.PSObject.Properties.Name -contains 'mcpServers')) {
        $cfg | Add-Member -NotePropertyName mcpServers -NotePropertyValue ([pscustomobject]@{})
    }
    $entry = [pscustomobject]@{
        command = 'cmd'
        args    = @('/c', 'npx', '-y', $McpPackage)
        env     = [pscustomobject]@{ GODOT_PATH = $godotExe }
    }
    if ($cfg.mcpServers.PSObject.Properties.Name -contains 'godot') {
        $cfg.mcpServers.godot = $entry
    } else {
        $cfg.mcpServers | Add-Member -NotePropertyName godot -NotePropertyValue $entry
    }

    $json = $cfg | ConvertTo-Json -Depth 32
    [IO.File]::WriteAllText($cfgFile, $json, (New-Object System.Text.UTF8Encoding $false))
    Ok "Gravado em $cfgFile - feche o Claude Desktop pela bandeja e abra de novo."
}

Write-Host ""
Write-Host "Pronto. Proximos passos:" -ForegroundColor Yellow
Write-Host "  - Claude Code: abra um terminal NOVO, rode 'claude' em $ProjectDir e aprove o servidor 'godot' (.mcp.json)."
if ($ClaudeDesktop) { Write-Host "  - Claude Desktop: reinicie o app; as ferramentas do godot aparecem como servidor local." }
Write-Host "  - Abrir o editor: & '$godotExe' -e --path '$ProjectDir'"
