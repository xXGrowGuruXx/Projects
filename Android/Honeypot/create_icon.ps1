Add-Type -AssemblyName System.Drawing

# Erstelle 512x512 Bild
$size = 512
$bitmap = New-Object System.Drawing.Bitmap($size, $size)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

# Hintergrund (transparent für Adaptive Icon)
$graphics.Clear([System.Drawing.Color]::Transparent)

# Bienen-Körper (Gelb mit schwarzen Streifen)
$yellow = [System.Drawing.Color]::FromArgb(255, 255, 193, 7)
$black = [System.Drawing.Color]::Black

# Körper
$bodyBrush = New-Object System.Drawing.SolidBrush($yellow)
$graphics.FillEllipse($bodyBrush, 156, 200, 200, 250)

# Schwarze Streifen
$stripeBrush = New-Object System.Drawing.SolidBrush($black)
$pen = New-Object System.Drawing.Pen($black, 30)
$graphics.DrawArc($pen, 156, 220, 200, 230, 180, 180)
$graphics.DrawArc($pen, 156, 280, 200, 230, 180, 180)
$graphics.DrawArc($pen, 156, 340, 200, 230, 180, 180)

# Kopf
$graphics.FillEllipse($stripeBrush, 200, 120, 112, 112)

# Augen
$whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$graphics.FillEllipse($whiteBrush, 220, 150, 30, 30)
$graphics.FillEllipse($whiteBrush, 262, 150, 30, 30)

# Pupillen
$graphics.FillEllipse($stripeBrush, 230, 160, 15, 15)
$graphics.FillEllipse($stripeBrush, 272, 160, 15, 15)

# Flügel
$wingBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 200, 220, 255))
$graphics.FillEllipse($wingBrush, 80, 180, 140, 100)
$graphics.FillEllipse($wingBrush, 292, 180, 140, 100)

# Fühler
$graphics.DrawLine($pen, 240, 130, 210, 80)
$graphics.DrawLine($pen, 272, 130, 302, 80)
$graphics.FillEllipse($stripeBrush, 200, 70, 20, 20)
$graphics.FillEllipse($stripeBrush, 292, 70, 20, 20)

# Speichern
$bitmap.Save("assets\icon\bee_icon.png", [System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose()
$bitmap.Dispose()

Write-Host "Bienen-Icon erstellt: assets\icon\bee_icon.png" -ForegroundColor Green
