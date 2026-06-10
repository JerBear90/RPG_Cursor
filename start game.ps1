# Exiled Survivors — quick launch (runs main menu directly, no editor)
# Usage: .\start` game.ps1
#        .\start` game.ps1 -Editor    # open Godot editor instead
#        .\start` game.ps1 -Test      # run .\scripts\run_tests.ps1 first, then launch

param(
    [string]$GodotPath = "",
    [switch]$Editor,
    [switch]$Test
)

$ProjectRoot = $PSScriptRoot
$MainScene = "res://scenes/main_menu/main_menu.tscn"

function Find-Godot {
    param([string]$Override, [switch]$PreferConsole)
    if ($Override -and (Test-Path $Override)) { return $Override }

    $cmd = Get-Command godot -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $candidates = @(
        "$env:LOCALAPPDATA\Godot\Godot_v4.3-stable_win64.exe",
        "$env:LOCALAPPDATA\Godot\Godot_v4.4-stable_win64.exe",
        "$env:LOCALAPPDATA\Godot\Godot_v4.3-stable_win64_console.exe"
    )
    foreach ($path in $candidates) {
        if (Test-Path $path) { return $path }
    }

    $roots = @("$env:LOCALAPPDATA\Godot", "${env:ProgramFiles}\Godot", "$env:USERPROFILE\Downloads")
    foreach ($root in $roots) {
        if (-not (Test-Path $root)) { continue }
        $filter = if ($PreferConsole) { "Godot*_console.exe" } else { "Godot*.exe" }
        $found = Get-ChildItem -Path $root -Recurse -Filter $filter -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notmatch "console" } |
            Select-Object -First 1
        if ($found) { return $found.FullName }
    }
    return $null
}

# Close stray Godot processes (stale editor/F5 sessions block imports and hide script changes).
$stale = Get-Process -Name "Godot*" -ErrorAction SilentlyContinue
if ($stale) {
    Write-Host "Closing $($stale.Count) existing Godot process(es)..."
    $stale | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
}

if ($Test) {
    Write-Host "Running tests via .\scripts\run_tests.ps1 ..."
    $testScript = Join-Path $ProjectRoot "scripts\run_tests.ps1"
    $testArgs = @()
    if ($GodotPath) { $testArgs += "-GodotPath"; $testArgs += $GodotPath }
    & $testScript @testArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Tests failed (exit $LASTEXITCODE). Fix before playing, or launch without -Test."
        exit $LASTEXITCODE
    }
    Write-Host ""
}

$godot = Find-Godot -Override $GodotPath
if (-not $godot) {
    Write-Host "Godot not found."
    Write-Host "Install Godot 4.3+ from https://godotengine.org/download/windows/"
    Write-Host "Or run: .\start` game.ps1 -GodotPath `"C:\path\to\Godot_v4.3-stable_win64.exe`""
    exit 1
}

if ($Editor) {
    Write-Host "Opening Exiled Survivors in Godot editor..."
    Start-Process -FilePath $godot -ArgumentList @("--path", $ProjectRoot, "--editor")
} else {
    Write-Host "Starting Exiled Survivors..."
    Start-Process -FilePath $godot -ArgumentList @("--path", $ProjectRoot, $MainScene)
}

exit 0
