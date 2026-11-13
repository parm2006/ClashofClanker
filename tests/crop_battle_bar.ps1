Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Bitmap]::FromFile('C:\Users\parth\Projects\coc_bot\scratch\test_key_screen.png')
Write-Host "Width: $($img.Width), Height: $($img.Height)"
# Let's crop the bottom 150 pixels (y=650 to 800) to inspect troop bar
$crop = New-Object System.Drawing.Bitmap(1280, 150)
$g = [System.Drawing.Graphics]::FromImage($crop)
$g.DrawImage($img, (New-Object System.Drawing.Rectangle(0, 0, 1280, 150)), (New-Object System.Drawing.Rectangle(0, 650, 1280, 150)), [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()
$crop.Save('C:\Users\parth\Projects\coc_bot\scratch\bottom_battle_bar.png', [System.Drawing.Imaging.ImageFormat]::Png)
$crop.Dispose()
$img.Dispose()
Write-Host "Saved bottom_battle_bar.png"
