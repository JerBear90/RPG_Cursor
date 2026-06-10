# Capture main-menu preview screenshot
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$godot = "$env:LOCALAPPDATA\Godot\Godot_v4.3-stable_win64.exe"
if (-not (Test-Path $godot)) {
    Write-Host "Godot not found at $godot"
    exit 1
}
& $godot --path $ProjectRoot --resolution 1280x800 res://tests/capture_preview.tscn
$out = Join-Path $ProjectRoot "docs\screenshots\preview.png"
if (Test-Path $out) { Write-Host "Preview: $out" } else { Write-Host "Screenshot not created" }
