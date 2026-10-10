<#
.SYNOPSIS
  Captura so a janela do jogo (titulo contendo -Title) num PNG, recortando a tela pelo retangulo
  da janela (Win32 GetWindowRect). Serve para a verificacao do Code e para as capturas do roadmap
  (docs/roadmap/README.md: nunca gravar a tela inteira em docs/).
  Uso: .\tools\screenshot.ps1 -Out logs\captura.png [-Title 'rrb-godot']
#>
param(
    [Parameter(Mandatory = $true)][string]$Out,
    # Titulo exato da janela do jogo (o do editor/console e diferente).
    [string]$Title = 'rrb-godot (DEBUG)'
)
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class Win32Window {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int cmd);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
}
'@
# Entre os processos do Godot com esse titulo (o *_console.exe tem dois), fica a maior janela.
$hwnd = [IntPtr]::Zero
$best = 0
$rect = New-Object Win32Window+RECT
foreach ($proc in Get-Process | Where-Object { $_.ProcessName -like 'Godot*' -and $_.MainWindowTitle -like "$Title*" }) {
    # Janela minimizada (jogo aberto por processo em segundo plano): restaura antes de medir.
    if ([Win32Window]::IsIconic($proc.MainWindowHandle)) { [Win32Window]::ShowWindow($proc.MainWindowHandle, 9) | Out-Null; Start-Sleep -Milliseconds 500 }
    $r = New-Object Win32Window+RECT
    [Win32Window]::GetWindowRect($proc.MainWindowHandle, [ref]$r) | Out-Null
    $area = ($r.Right - $r.Left) * ($r.Bottom - $r.Top)
    if ($area -gt $best) { $best = $area; $hwnd = $proc.MainWindowHandle; $rect = $r }
}
if ($hwnd -eq [IntPtr]::Zero) { Write-Host "janela '$Title' nao encontrada" -ForegroundColor Red; exit 1 }
[Win32Window]::SetForegroundWindow($hwnd) | Out-Null
Start-Sleep -Milliseconds 300
[Win32Window]::GetWindowRect($hwnd, [ref]$rect) | Out-Null
$w = $rect.Right - $rect.Left
$h = $rect.Bottom - $rect.Top
$bmp = New-Object System.Drawing.Bitmap $w, $h
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($rect.Left, $rect.Top, 0, 0, (New-Object System.Drawing.Size $w, $h))
$dir = Split-Path -Parent $Out
if ($dir) { New-Item -ItemType Directory -Force $dir | Out-Null }
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Host "captura: $Out ($w x $h)"
