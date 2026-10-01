# scripts/validate_assets.ps1
# Runs the automated asset pipeline validator headlessly.

$ErrorActionPreference = "Stop"

$ProjectDir = (Resolve-Path "$PSScriptRoot\..").Path
$GodotConsole = "C:\Users\SAMI\Desktop\ProjectZero\Godot_v4.7.2-stable_win64_console.exe"

& $GodotConsole --headless --path "$ProjectDir" -s "$ProjectDir\scripts\validate_assets.gd"
exit $LASTEXITCODE
