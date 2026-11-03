# ─── Lo's shell profile ────────────────────────────────────────────────────
# Shared between Windows PowerShell 5.1 and PowerShell 7.
# Loaded from $PROFILE on terminal open.

# Put our tools on PATH
$ourPaths = @(
    'D:\Tools\WezTerm'
    'D:\cargo\bin'
) | Where-Object { Test-Path $_ }
foreach ($p in $ourPaths) {
    if (-not ($env:PATH -split ';' | Where-Object { $_ -ieq $p })) {
        $env:PATH = "$p;$env:PATH"
    }
}

# Only run eye-candy in an interactive terminal (skip in VS Code tasks, CI, etc)
$interactive = $Host.Name -eq 'ConsoleHost' -or $env:WT_SESSION -or $env:TERM_PROGRAM -eq 'WezTerm'

if ($interactive) {
    # Firefly logo + system info
    if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
        # Responsive layout (widths measured for the compact logo + longest info line):
        #   >= 106 cols  logo left, info right      (worst case needs 104)
        #   >=  66 cols  logo on top, info below    (worst-case info line is 63)
        #   otherwise    info only, no logo
        $ffCols = try { $Host.UI.RawUI.WindowSize.Width } catch { 0 }
        if ($ffCols -le 0 -or $ffCols -ge 106) {
            fastfetch --config D:\Tools\terminal\fastfetch.jsonc
        } elseif ($ffCols -ge 66) {
            fastfetch --config D:\Tools\terminal\fastfetch.jsonc --logo-position top
        } else {
            fastfetch --config D:\Tools\terminal\fastfetch.jsonc --logo none
        }
    }
}

# Prompt
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $shellTag = if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh' } else { 'powershell' }
    & oh-my-posh init $shellTag --config 'D:\Tools\terminal\prompt.omp.json' | Invoke-Expression
}

# Quality of life aliases
Set-Alias ll Get-ChildItem -Scope Global -Force
Set-Alias touch New-Item -Scope Global -Force
function which { param($name) (Get-Command $name -ErrorAction SilentlyContinue).Source }
function reload-colors { & 'D:\Tools\terminal\wallmatch.ps1' }
