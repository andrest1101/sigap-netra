# tool/generate_branding_icons.ps1
#
# Menghasilkan aset branding build-time untuk SIGAP-NETRA dari satu sumber:
# `assets/images/logo_mark.png`. Dipakai oleh `flutter_launcher_icons` dan
# `flutter_native_splash` (lihat pubspec.yaml) — file di `assets/branding/`
# TIDAK dibundel ke aplikasi, tidak perlu didaftarkan di `pubspec.assets`.
#
# Output:
#   assets/branding/app_icon.png            1024x1024 — iOS + Android legacy
#   assets/branding/app_icon_foreground.png 1024x1024 — adaptive icon Android
#   assets/branding/splash_logo.png         1024x1024 — splash native (cakram)
#
# Jalankan ulang setelah mengubah logo_mark.png:
#   powershell -NoProfile -ExecutionPolicy Bypass -File tool/generate_branding_icons.ps1
#
# Geometri: konten mark (mata + gelombang) menempati 486x342 px di tengah
# gambar sumber 512x512 (margin 13 px kiri/kanan). Skala di skrip ini dipilih
# lewat "lebar konten sebagai persentase kanvas" supaya penempatan presisi:
#   - app_icon     86% — penuh namun bernapas di ikon iOS/legacy
#   - foreground   58% — aman di dalam safe zone adaptive icon (66/108 dp)
#   - splash       cakram 62.5% (±160 dp di layar) — mirror `LogoMark` (ClipOval)

Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $repoRoot 'assets/images/logo_mark.png'
$outDir = Join-Path $repoRoot 'assets/branding'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

if (-not (Test-Path $sourcePath)) {
  throw "Sumber tidak ditemukan: $sourcePath"
}

$source = [System.Drawing.Bitmap]::FromFile($sourcePath)

# Konten mark = 486 px dari 512 px gambar sumber.
$contentFraction = 486.0 / 512.0

# Warna latar kanvas ikon: titik tengah gradasi latar sumber (putih #FFFFFF di
# sudut, hangat #FEFBF6 di tepi samping) supaya batas gambar sumber tidak
# terlihat sebagai garis samar — selisih maks ±5/255, tak kasat mata pada
# ukuran ikon. (Diuji: 2026-10-19, lihat progress.md U1.)
$iconFill = [System.Drawing.Color]::FromArgb(255, 255, 253, 251)

function New-SquareCanvas {
  param([int]$Size, [System.Drawing.Color]$Fill)
  $bitmap = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
  $graphics.Clear($Fill)
  return @($bitmap, $graphics)
}

function Add-ScaledLogo {
  param(
    [System.Drawing.Graphics]$Graphics,
    [int]$CanvasSize,
    [double]$TargetContentWidthFraction
  )
  $drawSize = $CanvasSize * $TargetContentWidthFraction / $contentFraction
  $offset = ($CanvasSize - $drawSize) / 2.0
  $dest = New-Object System.Drawing.RectangleF($offset, $offset, $drawSize, $drawSize)
  $Graphics.DrawImage($source, $dest)
}

function Save-Png {
  param([System.Drawing.Bitmap]$Bitmap, [string]$FileName)
  $path = Join-Path $outDir $FileName
  $Bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  Write-Output ("{0} ({1:N0} byte)" -f $FileName, (Get-Item $path).Length)
}

# 1) Ikon utama (iOS + Android legacy).
$pair = New-SquareCanvas -Size 1024 -Fill $iconFill
Add-ScaledLogo -Graphics $pair[1] -CanvasSize 1024 -TargetContentWidthFraction 0.86
Save-Png -Bitmap $pair[0] -FileName 'app_icon.png'
$pair[0].Dispose(); $pair[1].Dispose()

# 2) Adaptive foreground Android (safe zone 66/108 dp).
$pair = New-SquareCanvas -Size 1024 -Fill $iconFill
Add-ScaledLogo -Graphics $pair[1] -CanvasSize 1024 -TargetContentWidthFraction 0.58
Save-Png -Bitmap $pair[0] -FileName 'app_icon_foreground.png'
$pair[0].Dispose(); $pair[1].Dispose()

# 3) Splash: cakram putih berisi mark, latar transparan (digambar di atas
#    warna splash #F6F6FB oleh flutter_native_splash). Kanvas 1024 px tampil
#    ±256 dp/pt di layar (flutter_native_splash memetakan 4 px = 1 dp), jadi
#    cakram dibuat 62.5% kanvas (= 640 px) supaya tampil ±160 dp —
#    proporsional, tidak mendominasi layar. Tepi cakram dipotong lewat
#    SetClip (deterministik); kontras tepi ≤ 9/255 di atas #F6F6FB sehingga
#    tangga piksel tepi tidak terlihat.
$pair = New-SquareCanvas -Size 1024 -Fill ([System.Drawing.Color]::Transparent)
$graphics = $pair[1]
$discDiameter = 640
$discOffset = (1024 - $discDiameter) / 2
$discPath = New-Object System.Drawing.Drawing2D.GraphicsPath
$discPath.AddEllipse($discOffset, $discOffset, $discDiameter, $discDiameter)
$graphics.SetClip($discPath)
$discRect = New-Object System.Drawing.RectangleF($discOffset, $discOffset, $discDiameter, $discDiameter)
$graphics.DrawImage($source, $discRect)
$graphics.ResetClip()
$discPath.Dispose()
Save-Png -Bitmap $pair[0] -FileName 'splash_logo.png'
$pair[0].Dispose(); $graphics.Dispose()

$source.Dispose()
Write-Output 'Selesai. Lanjut: dart run flutter_launcher_icons && dart run flutter_native_splash:create'
