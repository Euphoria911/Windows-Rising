# wallwatch.ps1 — long-running wallpaper watcher.
# Started by a scheduled task at logon. Watches Windows's transcoded wallpaper
# file for writes and re-runs wallmatch.ps1 on change (debounced).
#
# Idle cost: ~10 MB RAM, essentially 0% CPU (event-driven, no polling).

$ErrorActionPreference = 'Continue'

$transcoded = Join-Path $env:APPDATA 'Microsoft\Windows\Themes\TranscodedWallpaper'
$matchScript = Join-Path $PSScriptRoot 'wallmatch.ps1'

# Fire once at startup so the scheme is correct from the first prompt
try { & $matchScript } catch { Write-Warning $_ }

$folder = Split-Path -Parent $transcoded
$file = Split-Path -Leaf $transcoded

if (-not (Test-Path $folder)) {
    Write-Warning "Themes folder does not exist: $folder"
    exit 1
}

$fsw = New-Object System.IO.FileSystemWatcher($folder, $file)
$fsw.NotifyFilter = [System.IO.NotifyFilters]::LastWrite -bor [System.IO.NotifyFilters]::FileName -bor [System.IO.NotifyFilters]::CreationTime
$fsw.EnableRaisingEvents = $true

$lastRun = [DateTime]::MinValue
while ($true) {
    $result = $fsw.WaitForChanged([System.IO.WatcherChangeTypes]::All, 300000)  # 5 min heartbeat
    if ($result.TimedOut) { continue }

    # Debounce — Windows writes several times for one wallpaper change
    $now = Get-Date
    if (($now - $lastRun).TotalSeconds -lt 3) { continue }

    Start-Sleep -Milliseconds 600  # let Windows finish writing
    try {
        & $matchScript
        $lastRun = $now
    } catch {
        Write-Warning "wallmatch failed: $_"
    }
}
