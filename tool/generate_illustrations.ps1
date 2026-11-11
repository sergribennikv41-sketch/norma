$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$seedPath = Join-Path $root 'assets\data\seed.json'
$outDir = Join-Path $root 'assets\images\recipes'
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$jsonText = [System.IO.File]::ReadAllText($seedPath, (New-Object System.Text.UTF8Encoding($false)))
$seed = $jsonText | ConvertFrom-Json

function Get-HashBytes([string]$text) {
    $sha = [System.Security.Cryptography.SHA1]::Create()
    try {
        return $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($text))
    } finally {
        $sha.Dispose()
    }
}

function ColorFromHex([string]$hex, [int]$alpha = 255) {
    $r = [Convert]::ToInt32($hex.Substring(0, 2), 16)
    $g = [Convert]::ToInt32($hex.Substring(2, 2), 16)
    $b = [Convert]::ToInt32($hex.Substring(4, 2), 16)
    return [System.Drawing.Color]::FromArgb($alpha, $r, $g, $b)
}

$backgrounds = @{
    breakfast = @('FFF3E0', 'FFE0B2')
    lunch     = @('E8F5E9', 'C8E6C9')
    dinner    = @('E0F2F1', 'B2DFDB')
    snack     = @('EDE7F6', 'D1C4E9')
    default   = @('F5F5F5', 'E0E0E0')
}

$ingredientColors = @{
    'chicken_breast' = 'FFCC80'
    'turkey_fillet'  = 'D7CCC8'
    'beef_chuck'     = 'A1887F'
    'salmon'         = 'FF8A65'
    'cod'            = 'ECEFF1'
    'shrimp'         = 'F8BBD0'
    'tuna_canned'    = 'B0BEC5'
    'egg'            = 'FFE082'
    'lentils'        = 'D4B483'
    'canned_beans'   = 'BCAAA4'
    'cottage_5'      = 'FAFAFA'
    'cottage_2'      = 'FAFAFA'
    'greek_yogurt'   = 'F5F5F5'
    'milk_25'        = 'FFFFFF'
    'feta'           = 'FFF9C4'
    'hard_cheese'    = 'FFE082'
    'buckwheat'      = 'C8A165'
    'brown_rice'     = 'D7C4A1'
    'pasta'          = 'F0D9A0'
    'potato'         = 'D9C48F'
    'sweet_potato'   = 'F2B880'
    'oats'           = 'E8D3A5'
    'bread_rye'      = 'C9A87C'
    'broccoli'       = '66BB6A'
    'bell_pepper'    = 'EF5350'
    'spinach'        = '81C784'
    'cucumber'       = 'A5D6A7'
    'tomato'         = 'E53935'
    'carrot'         = 'FFA726'
    'cabbage'        = 'C5E1A5'
    'onion'          = 'FFF3E0'
    'avocado'        = '9CCC65'
    'olive_oil'      = 'FFD54F'
    'butter'         = 'FFE082'
    'honey'          = 'FFB300'
    'almonds'        = 'D7A86E'
    'walnuts'        = 'A1887F'
    'apple'          = 'EF5350'
    'banana'         = 'FFE082'
    'blueberry'      = '7986CB'
    'orange'         = 'FFB74D'
    'tomato_paste'   = 'D84315'
}

$carbIds = @('buckwheat', 'brown_rice', 'pasta', 'potato', 'sweet_potato', 'oats', 'bread_rye')
$proteinIds = @('chicken_breast', 'turkey_fillet', 'beef_chuck', 'salmon', 'cod', 'shrimp', 'tuna_canned', 'egg', 'lentils', 'canned_beans')
$vegIds = @('broccoli', 'bell_pepper', 'spinach', 'cucumber', 'tomato', 'carrot', 'cabbage', 'avocado', 'onion')
$extraIds = @('apple', 'banana', 'blueberry', 'orange', 'almonds', 'walnuts', 'honey')

foreach ($recipe in $seed.recipes) {
    $id = [string]$recipe.id
    $hash = Get-HashBytes $id
    $mealTypes = @($recipe.mealTypes)
    $meal = if ($mealTypes.Count -gt 0) { [string]$mealTypes[0] } else { 'default' }
    $palette = if ($backgrounds.ContainsKey($meal)) { $backgrounds[$meal] } else { $backgrounds['default'] }

    $bitmap = New-Object System.Drawing.Bitmap -ArgumentList 512, 512
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $rect = New-Object System.Drawing.Rectangle -ArgumentList 0, 0, 512, 512
        $gradient = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
            $rect,
            (ColorFromHex $palette[0]),
            (ColorFromHex $palette[1]),
            [System.Drawing.Drawing2D.LinearGradientMode]::ForwardDiagonal
        )
        $graphics.FillRectangle($gradient, $rect)
        $gradient.Dispose()

        $plateBrush = New-Object System.Drawing.SolidBrush -ArgumentList ([System.Drawing.Color]::FromArgb(235, 255, 255, 255))
        $graphics.FillEllipse($plateBrush, 56, 56, 400, 400)
        $plateBrush.Dispose()
        $rimPen = New-Object System.Drawing.Pen -ArgumentList ([System.Drawing.Color]::FromArgb(90, 255, 255, 255)), 6
        $graphics.DrawEllipse($rimPen, 56, 56, 400, 400)
        $rimPen.Dispose()

        $ingredients = @($recipe.ingredients | ForEach-Object { [string]$_.ingredientId })

        $carb = $ingredients | Where-Object { $carbIds -contains $_ } | Select-Object -First 1
        if ($carb) {
            $color = if ($ingredientColors.ContainsKey($carb)) { ColorFromHex $ingredientColors[$carb] } else { ColorFromHex 'E0C9A6' }
            $brush = New-Object System.Drawing.SolidBrush -ArgumentList $color
            $graphics.FillEllipse($brush, 140, 220, 230, 170)
            $brush.Dispose()
        }

        $protein = $ingredients | Where-Object { $proteinIds -contains $_ } | Select-Object -First 1
        if ($protein) {
            $color = if ($ingredientColors.ContainsKey($protein)) { ColorFromHex $ingredientColors[$protein] } else { ColorFromHex 'D7CCC8' }
            $brush = New-Object System.Drawing.SolidBrush -ArgumentList $color
            $graphics.FillEllipse($brush, 200, 150, 120, 90)
            $brush.Dispose()
        }

        $veg = @($ingredients | Where-Object { $vegIds -contains $_ })
        for ($i = 0; $i -lt [Math]::Min($veg.Count, 4); $i++) {
            $color = if ($ingredientColors.ContainsKey($veg[$i])) { ColorFromHex $ingredientColors[$veg[$i]] } else { ColorFromHex '81C784' }
            $brush = New-Object System.Drawing.SolidBrush -ArgumentList $color
            $x = 130 + ([int]$hash[$i % 20] % 180)
            $y = 190 + ([int]$hash[($i + 3) % 20] % 160)
            $size = 50 + ([int]$hash[($i + 7) % 20] % 40)
            $graphics.FillEllipse($brush, $x, $y, $size, $size)
            $brush.Dispose()
        }

        $extras = @($ingredients | Where-Object { $extraIds -contains $_ })
        for ($i = 0; $i -lt [Math]::Min($extras.Count, 3); $i++) {
            $color = if ($ingredientColors.ContainsKey($extras[$i])) { ColorFromHex $ingredientColors[$extras[$i]] } else { ColorFromHex 'FFB74D' }
            $brush = New-Object System.Drawing.SolidBrush -ArgumentList $color
            $x = 160 + ([int]$hash[($i + 11) % 20] % 170)
            $y = 140 + ([int]$hash[($i + 5) % 20] % 120)
            $graphics.FillEllipse($brush, $x, $y, 36, 36)
            $brush.Dispose()
        }

        if ($ingredients -contains 'olive_oil' -or $ingredients -contains 'honey') {
            $pen = New-Object System.Drawing.Pen -ArgumentList ([System.Drawing.Color]::FromArgb(180, 255, 193, 7)), 8
            $graphics.DrawArc($pen, 150, 150, 220, 220, 20, 140)
            $pen.Dispose()
        }

        $outPath = Join-Path $outDir "$id.png"
        $bitmap.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

Write-Output "generated $($seed.recipes.Count) images in $outDir"
