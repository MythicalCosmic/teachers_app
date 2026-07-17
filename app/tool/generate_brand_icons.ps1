param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

function New-StarForgeIcon {
    param(
        [Parameter(Mandatory = $true)][int]$Size,
        [Parameter(Mandatory = $true)][string]$OutputPath
    )

    $bitmap = [System.Drawing.Bitmap]::new($Size, $Size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

    try {
        $bounds = [System.Drawing.Rectangle]::new(0, 0, $Size, $Size)
        $background = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
            $bounds,
            [System.Drawing.Color]::FromArgb(255, 38, 59, 34),
            [System.Drawing.Color]::FromArgb(255, 79, 106, 58),
            45.0
        )
        $graphics.FillRectangle($background, $bounds)
        $background.Dispose()

        # Quiet geometric orbit lines retain the product's editorial motif.
        $orbitPen = [System.Drawing.Pen]::new(
            [System.Drawing.Color]::FromArgb(28, 250, 248, 239),
            [Math]::Max(1.0, $Size * 0.012)
        )
        $orbitPen.Alignment = [System.Drawing.Drawing2D.PenAlignment]::Inset
        $graphics.DrawEllipse(
            $orbitPen,
            [single](-$Size * 0.18),
            [single]($Size * 0.03),
            [single]($Size * 0.83),
            [single]($Size * 0.83)
        )
        $graphics.DrawEllipse(
            $orbitPen,
            [single]($Size * 0.45),
            [single]($Size * 0.39),
            [single]($Size * 0.75),
            [single]($Size * 0.75)
        )
        $orbitPen.Dispose()

        $starPoints = @(
            @(50, 0), @(61, 35), @(98, 35), @(68, 57), @(79, 91),
            @(50, 70), @(21, 91), @(32, 57), @(2, 35), @(39, 35)
        )
        $starSize = $Size * 0.57
        $left = ($Size - $starSize) / 2
        $top = ($Size - $starSize) / 2

        $points = [System.Drawing.PointF[]]::new($starPoints.Count)
        for ($index = 0; $index -lt $starPoints.Count; $index++) {
            $points[$index] = [System.Drawing.PointF]::new(
                [single]($left + ($starPoints[$index][0] / 100.0) * $starSize),
                [single]($top + ($starPoints[$index][1] / 100.0) * $starSize)
            )
        }

        $shadowPoints = [System.Drawing.PointF[]]::new($points.Length)
        for ($index = 0; $index -lt $points.Length; $index++) {
            $shadowPoints[$index] = [System.Drawing.PointF]::new(
                [single]($points[$index].X + $Size * 0.018),
                [single]($points[$index].Y + $Size * 0.026)
            )
        }
        $shadowBrush = [System.Drawing.SolidBrush]::new(
            [System.Drawing.Color]::FromArgb(54, 18, 29, 16)
        )
        $graphics.FillPolygon($shadowBrush, $shadowPoints)
        $shadowBrush.Dispose()

        $starBrush = [System.Drawing.SolidBrush]::new(
            [System.Drawing.Color]::FromArgb(255, 250, 248, 239)
        )
        $graphics.FillPolygon($starBrush, $points)
        $starBrush.Dispose()

        $dotSize = [Math]::Max(2.0, $Size * 0.085)
        $dotBrush = [System.Drawing.SolidBrush]::new(
            [System.Drawing.Color]::FromArgb(255, 186, 140, 44)
        )
        $graphics.FillEllipse(
            $dotBrush,
            [single](($Size - $dotSize) / 2),
            [single](($Size - $dotSize) / 2),
            [single]$dotSize,
            [single]$dotSize
        )
        $dotBrush.Dispose()

        $directory = Split-Path -Parent $OutputPath
        if (-not (Test-Path -LiteralPath $directory)) {
            New-Item -ItemType Directory -Path $directory | Out-Null
        }
        $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

function New-StarForgeLaunchMark {
    param(
        [Parameter(Mandatory = $true)][int]$Width,
        [Parameter(Mandatory = $true)][int]$Height,
        [Parameter(Mandatory = $true)][string]$OutputPath
    )

    $bitmap = [System.Drawing.Bitmap]::new($Width, $Height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.Clear([System.Drawing.Color]::Transparent)

    try {
        $starPoints = @(
            @(50, 0), @(61, 35), @(98, 35), @(68, 57), @(79, 91),
            @(50, 70), @(21, 91), @(32, 57), @(2, 35), @(39, 35)
        )
        $starSize = [Math]::Min($Width, $Height) * 0.62
        $left = ($Width - $starSize) / 2
        $top = ($Height - $starSize) / 2
        $points = [System.Drawing.PointF[]]::new($starPoints.Count)
        for ($index = 0; $index -lt $starPoints.Count; $index++) {
            $points[$index] = [System.Drawing.PointF]::new(
                [single]($left + ($starPoints[$index][0] / 100.0) * $starSize),
                [single]($top + ($starPoints[$index][1] / 100.0) * $starSize)
            )
        }

        $starBrush = [System.Drawing.SolidBrush]::new(
            [System.Drawing.Color]::FromArgb(255, 250, 248, 239)
        )
        $graphics.FillPolygon($starBrush, $points)
        $starBrush.Dispose()

        $dotSize = [Math]::Max(2.0, $starSize * 0.15)
        $dotBrush = [System.Drawing.SolidBrush]::new(
            [System.Drawing.Color]::FromArgb(255, 186, 140, 44)
        )
        $graphics.FillEllipse(
            $dotBrush,
            [single](($Width - $dotSize) / 2),
            [single](($Height - $dotSize) / 2),
            [single]$dotSize,
            [single]$dotSize
        )
        $dotBrush.Dispose()

        $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

$iosDirectory = Join-Path $ProjectRoot 'ios\Runner\Assets.xcassets\AppIcon.appiconset'
$iosIcons = @{
    'Icon-App-20x20@1x.png' = 20
    'Icon-App-20x20@2x.png' = 40
    'Icon-App-20x20@3x.png' = 60
    'Icon-App-29x29@1x.png' = 29
    'Icon-App-29x29@2x.png' = 58
    'Icon-App-29x29@3x.png' = 87
    'Icon-App-40x40@1x.png' = 40
    'Icon-App-40x40@2x.png' = 80
    'Icon-App-40x40@3x.png' = 120
    'Icon-App-60x60@2x.png' = 120
    'Icon-App-60x60@3x.png' = 180
    'Icon-App-76x76@1x.png' = 76
    'Icon-App-76x76@2x.png' = 152
    'Icon-App-83.5x83.5@2x.png' = 167
    'Icon-App-1024x1024@1x.png' = 1024
}
foreach ($icon in $iosIcons.GetEnumerator()) {
    New-StarForgeIcon -Size $icon.Value -OutputPath (Join-Path $iosDirectory $icon.Key)
}

$androidIcons = @{
    'mipmap-mdpi\ic_launcher.png' = 48
    'mipmap-hdpi\ic_launcher.png' = 72
    'mipmap-xhdpi\ic_launcher.png' = 96
    'mipmap-xxhdpi\ic_launcher.png' = 144
    'mipmap-xxxhdpi\ic_launcher.png' = 192
}
$androidResources = Join-Path $ProjectRoot 'android\app\src\main\res'
foreach ($icon in $androidIcons.GetEnumerator()) {
    New-StarForgeIcon -Size $icon.Value -OutputPath (Join-Path $androidResources $icon.Key)
}

$launchDirectory = Join-Path $ProjectRoot 'ios\Runner\Assets.xcassets\LaunchImage.imageset'
New-StarForgeLaunchMark -Width 168 -Height 185 -OutputPath (Join-Path $launchDirectory 'LaunchImage.png')
New-StarForgeLaunchMark -Width 336 -Height 370 -OutputPath (Join-Path $launchDirectory 'LaunchImage@2x.png')
New-StarForgeLaunchMark -Width 504 -Height 555 -OutputPath (Join-Path $launchDirectory 'LaunchImage@3x.png')

Write-Host "Generated StarForge Staff launcher and splash assets."
