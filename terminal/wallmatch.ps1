# wallmatch.ps1 - extract dominant colors from the current Windows wallpaper
# and write a WezTerm color scheme (Lua) so the terminal auto-matches the desktop.
#
# Run on wallpaper change (triggered by a scheduled task watching the registry
# key HKCU:\Control Panel\Desktop\Wallpaper) or manually any time.

[CmdletBinding()]
param(
    [string]$WallpaperPath,
    [string]$OutLua = "$env:USERPROFILE\.config\wezterm\colors\wallmatch.toml"
)

Add-Type -AssemblyName System.Drawing

function Get-CurrentWallpaper {
    try {
        $wp = (Get-ItemProperty 'HKCU:\Control Panel\Desktop' -Name Wallpaper).Wallpaper
        if ($wp -and (Test-Path $wp)) { return $wp }
        $transcoded = "$env:APPDATA\Microsoft\Windows\Themes\TranscodedWallpaper"
        if (Test-Path $transcoded) { return $transcoded }
    } catch { }
    return $null
}

function Get-DominantPalette {
    param([string]$Path)
    $bmp = [System.Drawing.Bitmap]::new($Path)
    try {
        $w = 64
        $h = [int]($bmp.Height * ($w / $bmp.Width))
        $thumb = [System.Drawing.Bitmap]::new($w, $h)
        $g = [System.Drawing.Graphics]::FromImage($thumb)
        $g.InterpolationMode = 'HighQualityBilinear'
        $g.DrawImage($bmp, 0, 0, $w, $h)
        $g.Dispose()

        $buckets = @{}
        for ($y = 0; $y -lt $h; $y++) {
            for ($x = 0; $x -lt $w; $x++) {
                $p = $thumb.GetPixel($x, $y)
                $qr = [int]([math]::Floor($p.R / 24.0) * 24)
                $qg = [int]([math]::Floor($p.G / 24.0) * 24)
                $qb = [int]([math]::Floor($p.B / 24.0) * 24)
                $key = "{0}_{1}_{2}" -f $qr, $qg, $qb
                if ($buckets.ContainsKey($key)) {
                    $buckets[$key].Count++
                } else {
                    $buckets[$key] = [pscustomobject]@{
                        R = $qr; G = $qg; B = $qb; Count = 1
                    }
                }
            }
        }
        $thumb.Dispose()
        return $buckets.Values | Sort-Object -Property Count -Descending
    } finally { $bmp.Dispose() }
}

function Get-Luminance { param($c) return (0.2126 * $c.R + 0.7152 * $c.G + 0.0722 * $c.B) / 255.0 }
function Get-Hue {
    param($c)
    $r = $c.R / 255.0; $g = $c.G / 255.0; $b = $c.B / 255.0
    $max = [math]::Max([math]::Max($r, $g), $b)
    $min = [math]::Min([math]::Min($r, $g), $b)
    $d = $max - $min
    if ($d -eq 0) { return 0 }
    $h = 0
    if ($max -eq $r) { $h = (60 * (($g - $b) / $d) + 360) % 360 }
    elseif ($max -eq $g) { $h = 60 * (($b - $r) / $d) + 120 }
    else { $h = 60 * (($r - $g) / $d) + 240 }
    return $h
}
function Hex { param($c) return ("#{0:x2}{1:x2}{2:x2}" -f [int]$c.R, [int]$c.G, [int]$c.B) }

function Adjust-Lightness {
    param($c, [double]$amount)
    $r = [int][math]::Max(0, [math]::Min(255, $c.R + 255 * $amount))
    $g = [int][math]::Max(0, [math]::Min(255, $c.G + 255 * $amount))
    $b = [int][math]::Max(0, [math]::Min(255, $c.B + 255 * $amount))
    return [pscustomobject]@{ R = $r; G = $g; B = $b }
}

function Build-Scheme {
    param($Palette)
    $top32 = $Palette | Select-Object -First 32

    $dark  = $top32 | Where-Object { (Get-Luminance $_) -lt 0.25 } | Sort-Object { Get-Luminance $_ }
    $light = $top32 | Where-Object { (Get-Luminance $_) -gt 0.70 } | Sort-Object { -(Get-Luminance $_) }
    $mids  = $top32 | Where-Object { $l = Get-Luminance $_; $l -ge 0.20 -and $l -le 0.75 }

    if (-not $dark)  { $dark  = @([pscustomobject]@{R=14; G=16; B=22}) }
    if (-not $light) { $light = @([pscustomobject]@{R=232; G=228; B=215}) }

    $bg = $dark[0]
    if ((Get-Luminance $bg) -gt 0.12) { $bg = Adjust-Lightness $bg -0.08 }
    $fg = $light[0]

    $hueTargets = @{ red=0; yellow=60; green=120; cyan=180; blue=220; magenta=300 }
    $accents = @{}
    foreach ($name in $hueTargets.Keys) {
        $target = $hueTargets[$name]
        $best = $mids | Sort-Object {
            $h = Get-Hue $_
            $d = [math]::Abs($h - $target)
            if ($d -gt 180) { $d = 360 - $d }
            $d
        } | Select-Object -First 1
        if (-not $best) {
            $best = switch ($name) {
                'red'     { [pscustomobject]@{R=180; G=80;  B=80} }
                'yellow'  { [pscustomobject]@{R=200; G=180; B=90} }
                'green'   { [pscustomobject]@{R=120; G=160; B=100} }
                'cyan'    { [pscustomobject]@{R=100; G=170; B=180} }
                'blue'    { [pscustomobject]@{R=100; G=130; B=180} }
                'magenta' { [pscustomobject]@{R=170; G=120; B=170} }
            }
        }
        $accents[$name] = $best
    }

    $brightDark = Adjust-Lightness $bg 0.08
    $brightFg   = Adjust-Lightness $fg 0.05

    return [pscustomobject]@{
        background    = Hex $bg
        foreground    = Hex $fg
        cursor_bg     = Hex $fg
        cursor_border = Hex $fg
        cursor_fg     = Hex $bg
        selection_bg  = Hex (Adjust-Lightness $bg 0.18)
        selection_fg  = Hex $fg
        ansi = @(
            (Hex $bg),
            (Hex $accents['red']),
            (Hex $accents['green']),
            (Hex $accents['yellow']),
            (Hex $accents['blue']),
            (Hex $accents['magenta']),
            (Hex $accents['cyan']),
            (Hex $fg)
        )
        brights = @(
            (Hex $brightDark),
            (Hex (Adjust-Lightness $accents['red']     0.15)),
            (Hex (Adjust-Lightness $accents['green']   0.15)),
            (Hex (Adjust-Lightness $accents['yellow']  0.15)),
            (Hex (Adjust-Lightness $accents['blue']    0.15)),
            (Hex (Adjust-Lightness $accents['magenta'] 0.15)),
            (Hex (Adjust-Lightness $accents['cyan']    0.15)),
            (Hex $brightFg)
        )
    }
}

function Write-WezTermToml {
    param($Scheme, [string]$OutPath)
    $dir = Split-Path -Parent $OutPath
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("# Auto-generated by wallmatch.ps1 - do not edit by hand.")
    [void]$sb.AppendLine("[colors]")
    [void]$sb.AppendLine("background    = `"$($Scheme.background)`"")
    [void]$sb.AppendLine("foreground    = `"$($Scheme.foreground)`"")
    [void]$sb.AppendLine("cursor_bg     = `"$($Scheme.cursor_bg)`"")
    [void]$sb.AppendLine("cursor_border = `"$($Scheme.cursor_border)`"")
    [void]$sb.AppendLine("cursor_fg     = `"$($Scheme.cursor_fg)`"")
    [void]$sb.AppendLine("selection_bg  = `"$($Scheme.selection_bg)`"")
    [void]$sb.AppendLine("selection_fg  = `"$($Scheme.selection_fg)`"")
    [void]$sb.Append("ansi = [")
    [void]$sb.Append(($Scheme.ansi | ForEach-Object { "`"$_`"" }) -join ", ")
    [void]$sb.AppendLine("]")
    [void]$sb.Append("brights = [")
    [void]$sb.Append(($Scheme.brights | ForEach-Object { "`"$_`"" }) -join ", ")
    [void]$sb.AppendLine("]")
    Set-Content -Path $OutPath -Value $sb.ToString() -Encoding UTF8 -NoNewline
}

# ---- main ----
if (-not $WallpaperPath) { $WallpaperPath = Get-CurrentWallpaper }
if (-not $WallpaperPath -or -not (Test-Path $WallpaperPath)) {
    Write-Error "No wallpaper found."
    exit 1
}

Write-Host "Reading wallpaper: $WallpaperPath"
$palette = Get-DominantPalette -Path $WallpaperPath
$scheme = Build-Scheme -Palette $palette
Write-WezTermToml -Scheme $scheme -OutPath $OutLua

Write-Host "Scheme written to: $OutLua"
Write-Host "  background: $($scheme.background)"
Write-Host "  foreground: $($scheme.foreground)"
Write-Host "  ansi: $($scheme.ansi -join ' ')"
