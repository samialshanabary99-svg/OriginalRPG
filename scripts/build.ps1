# scripts/build.ps1
# Builds the standalone Windows Desktop .exe for OriginalRPG.
# Can be run manually or by automated agents after every code update.

$ErrorActionPreference = "Stop"

$ProjectDir = (Resolve-Path "$PSScriptRoot\..").Path
$GodotConsole = "C:\Users\SAMI\Desktop\ProjectZero\Godot_v4.7.2-stable_win64_console.exe"
$BuildDir = "$ProjectDir\build"
$TargetExe = "$BuildDir\OriginalRPG.exe"
$ConvenienceExe = "C:\Users\SAMI\Desktop\ProjectZero\OriginalRPG.exe"
$DesktopShortcut = [System.IO.Path]::Combine([System.Environment]::GetFolderPath('Desktop'), "Play OriginalRPG.lnk")

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Building OriginalRPG Standalone Windows .exe " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Ensure build directory exists
if (-not (Test-Path $BuildDir)) {
    New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null
}

# 2. Run Godot headless export-release
Write-Host "[1/3] Exporting Windows Desktop preset..." -ForegroundColor Yellow
$proc = Start-Process -FilePath $GodotConsole `
    -ArgumentList "--headless", "--path", "`"$ProjectDir`"", "--export-release", "`"Windows Desktop`"", "`"$TargetExe`"" `
    -NoNewWindow -PassThru -Wait

if ($proc.ExitCode -ne 0) {
    Write-Host "[ERROR] Godot export failed with exit code $($proc.ExitCode)" -ForegroundColor Red
    exit $proc.ExitCode
}

if (-not (Test-Path $TargetExe)) {
    Write-Host "[ERROR] Expected binary not found at $TargetExe" -ForegroundColor Red
    exit 1
}

$fileInfo = Get-Item $TargetExe
$sizeMb = [math]::Round($fileInfo.Length / 1MB, 2)
Write-Host "[2/3] Built successfully: $TargetExe ($sizeMb MB)" -ForegroundColor Green

# 3. Copy to ProjectZero folder for immediate convenience
Copy-Item -Path $TargetExe -Destination $ConvenienceExe -Force
Write-Host "      Copied to: $ConvenienceExe" -ForegroundColor Green

# 4. Create / update desktop shortcut
try {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($DesktopShortcut)
    $Shortcut.TargetPath = $ConvenienceExe
    $Shortcut.WorkingDirectory = $BuildDir
    $Shortcut.Description = "Play OriginalRPG"
    $Shortcut.Save()
    Write-Host "[3/3] Desktop shortcut updated: $DesktopShortcut" -ForegroundColor Green
} catch {
    Write-Host "[WARN] Could not create desktop shortcut: $_" -ForegroundColor DarkYellow
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " BUILD COMPLETE AND READY TO PLAY! " -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
