# Compact Firefly logo for the fastfetch header, regenerated from the original
# reference (assets\firefly.png) with terminal-cell-aware scaling.
#
#   * Samples the PNG alpha channel with area averaging (no pixel-art re-tracing).
#   * Uses 2x3 sextant blocks (U+1FB00..1FB3B, drawn natively by WezTerm) so each
#     terminal cell carries six sub-pixels (5.5 x 9 px at an 11 x 27 px cell).
#   * Keeps the true aspect ratio of the artwork for the real cell size
#     (WezTerm: 11 x 27 px per cell, i.e. a cell is ~2.45x taller than wide).
#   * Picks the vertical grid alignment that leaves the fewest ambiguous
#     (near-50% coverage) sub-pixels, so edges stay crisp instead of dithering.
#
# Usage:  .\build-firefly-small.ps1 [-Columns 34] [-CellW 11] [-CellH 27]
# Output: assets\firefly-small.txt   (ANSI, same cream as the original logo)

param(
    [int]$Columns = 34,
    [double]$CellW = 11,
    [double]$CellH = 27,
    [string]$Source = 'D:\Tools\terminal\assets\firefly.png',
    [string]$Dest   = 'D:\Tools\terminal\assets\firefly-small.txt'
)

Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap $Source
$w = $bmp.Width; $h = $bmp.Height

# --- summed-area table of alpha (0..1) + ink bounding box -------------------
$W1 = $w + 1
$sat = New-Object 'double[]' (($w + 1) * ($h + 1))
$minx = $w; $maxx = -1; $miny = $h; $maxy = -1
for ($y = 0; $y -lt $h; $y++) {
    $rowSum = 0.0
    for ($x = 0; $x -lt $w; $x++) {
        $a = $bmp.GetPixel($x, $y).A
        $rowSum += $a / 255.0
        $sat[($y + 1) * $W1 + ($x + 1)] = $sat[$y * $W1 + ($x + 1)] + $rowSum
        if ($a -gt 128) {
            if ($x -lt $minx) { $minx = $x }; if ($x -gt $maxx) { $maxx = $x }
            if ($y -lt $miny) { $miny = $y }; if ($y -gt $maxy) { $maxy = $y }
        }
    }
}
$bmp.Dispose()
$bw = $maxx - $minx + 1; $bh = $maxy - $miny + 1

function RectSum([int]$x0, [int]$y0, [int]$x1, [int]$y1) {   # [x0,x1) x [y0,y1) in source px
    $x0 = [math]::Max(0, [math]::Min($w, $x0)); $x1 = [math]::Max(0, [math]::Min($w, $x1))
    $y0 = [math]::Max(0, [math]::Min($h, $y0)); $y1 = [math]::Max(0, [math]::Min($h, $y1))
    if ($x1 -le $x0 -or $y1 -le $y0) { return 0.0 }
    return $sat[$y1 * $W1 + $x1] - $sat[$y0 * $W1 + $x1] - $sat[$y1 * $W1 + $x0] + $sat[$y0 * $W1 + $x0]
}

# --- cell-aware sizing (never stretch): width fills the requested columns ----
$canvasW = $Columns * $CellW
$s = $canvasW / $bw                                   # target px per source px
$contentH = $bh * $s
$rows = [int][math]::Ceiling($contentH / $CellH)
$canvasH = $rows * $CellH
$slack = $canvasH - $contentH                         # vertical room to align the grid
$subW = $CellW / 2; $subH = $CellH / 3                # 2 x 3 sextant sub-pixels
$subCols = $Columns * 2; $subRows = $rows * 3

function Sample([double]$offY, [ref]$ambig) {
    $cov = New-Object 'double[,]' $subRows, $subCols
    $amb = 0
    for ($r = 0; $r -lt $subRows; $r++) {
        $ty0 = $r * $subH; $ty1 = $ty0 + $subH
        $sy0 = [int][math]::Round($miny + ($ty0 - $offY) / $s); $sy1 = [int][math]::Round($miny + ($ty1 - $offY) / $s)
        for ($c = 0; $c -lt $subCols; $c++) {
            $sx0 = [int][math]::Round($minx + ($c * $subW) / $s); $sx1 = [int][math]::Round($minx + (($c + 1) * $subW) / $s)
            $area = [math]::Max(1.0, ($sx1 - $sx0) * ($sy1 - $sy0))
            $v = (RectSum $sx0 $sy0 $sx1 $sy1) / $area
            $cov[$r, $c] = $v
            if ($v -gt 0.30 -and $v -lt 0.70) { $amb++ }
        }
    }
    $ambig.Value = $amb
    return , $cov
}

$best = $null; $bestAmb = [int]::MaxValue; $bestOff = 0.0
for ($off = 0.0; $off -le $slack + 0.001; $off += 1.0) {
    $a = 0; $cov = Sample $off ([ref]$a)
    if ($a -lt $bestAmb) { $bestAmb = $a; $best = $cov; $bestOff = $off }
}

# sextant pattern -> glyph. Bits: r0c0=1 r0c1=2 r1c0=4 r1c1=8 r2c0=16 r2c1=32
function SextantChar([int]$p) {
    if ($p -eq 0)  { return ' ' }
    if ($p -eq 63) { return [string][char]0x2588 }   # full block
    if ($p -eq 21) { return [string][char]0x258C }   # left half
    if ($p -eq 42) { return [string][char]0x2590 }   # right half
    $idx = $p - 1
    if ($p -gt 21) { $idx-- }
    if ($p -gt 42) { $idx-- }
    return [char]::ConvertFromUtf32(0x1FB00 + $idx)
}

$ESC = [char]27; $fg = '230;226;205'                  # same cream as the original logo
$lines = New-Object System.Collections.Generic.List[string]
$plain = New-Object System.Collections.Generic.List[string]
for ($cy = 0; $cy -lt $rows; $cy++) {
    $line = New-Object System.Text.StringBuilder
    $pl   = New-Object System.Text.StringBuilder
    for ($cx = 0; $cx -lt $Columns; $cx++) {
        $bits = 0
        for ($sr = 0; $sr -lt 3; $sr++) {
            for ($sc = 0; $sc -lt 2; $sc++) {
                if ($best[(3 * $cy + $sr), (2 * $cx + $sc)] -ge 0.5) { $bits += [math]::Pow(2, 2 * $sr + $sc) }
            }
        }
        $ch = SextantChar ([int]$bits)
        [void]$pl.Append($ch)
        if ($bits -eq 0) { [void]$line.Append(' ') } else { [void]$line.Append("$ESC[38;2;${fg}m$ch") }
    }
    [void]$line.Append("$ESC[0m")
    $lines.Add($line.ToString()); $plain.Add($pl.ToString())
}
# drop fully blank rows at the top/bottom
while ($plain.Count -gt 0 -and $plain[0].Trim().Length -eq 0)  { $plain.RemoveAt(0); $lines.RemoveAt(0) }
while ($plain.Count -gt 0 -and $plain[$plain.Count - 1].Trim().Length -eq 0) { $plain.RemoveAt($plain.Count - 1); $lines.RemoveAt($lines.Count - 1) }

$text = ($lines -join "`n")
[System.IO.File]::WriteAllText($Dest, $text, (New-Object System.Text.UTF8Encoding($false)))

"Source ink box : ${bw}x${bh} px (aspect {0:N3})" -f ($bw / $bh)
"Cell           : ${CellW}x${CellH} px -> logo $Columns cols x $($plain.Count) rows = $([int]$canvasW)x$([int]($plain.Count*$CellH)) px (aspect {0:N3})" -f ($canvasW / ($plain.Count * $CellH))
"Scale          : {0:N4} px/px   grid offset {1:N1}px (of {2:N1}px slack), ambiguous sub-pixels: $bestAmb of $($subRows*$subCols)" -f $s, $bestOff, $slack
"Wrote          : $Dest"
[System.IO.File]::WriteAllText("$Dest.preview.txt", ($plain -join "`n"), (New-Object System.Text.UTF8Encoding($false)))
