# Focused health HUD tests only (autoloads loaded; no Kenney manifest hang).
param(
    [string]$GodotPath = "C:\Users\jeram\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64.exe"
)

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$godot = $GodotPath
if (-not (Test-Path -LiteralPath $godot)) {
    $dir = Split-Path -Path $godot -Parent
    $inside = Get-ChildItem -LiteralPath $dir -Filter "Godot*console*.exe" -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($inside) { $godot = $inside.FullName }
}

Write-Host "Running focused health test runner..."
& $godot --path $ProjectRoot --headless res://tests/health_test_runner.tscn
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Running production Darkpine Forest health audit..."
& $godot --path $ProjectRoot --headless res://tests/production_health_gameplay_audit.tscn
exit $LASTEXITCODE
