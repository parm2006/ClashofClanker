Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Bitmap]::FromFile('C:\Users\parth\Projects\coc_bot\scratch\test_key_screen.png')
$small = New-Object System.Drawing.Bitmap(640, 400)
$g = [System.Drawing.Graphics]::FromImage($small)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBilinear
$g.DrawImage($img, 0, 0, 640, 400)
$g.Dispose()
$small.Save('C:\Users\parth\.gemini\antigravity\brain\f32000b2-c4ac-4e57-94c7-7562fbd9b8db\live_screen.png', [System.Drawing.Imaging.ImageFormat]::Png)
$small.Dispose()
$img.Dispose()
Write-Host "Saved live_screen.png"
