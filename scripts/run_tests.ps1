# Exiled Survivors — headless test runner
# Usage: .\scripts\run_tests.ps1 [-GodotPath "C:\path\to\Godot.exe"]

param(
    [string]$GodotPath = ""
)

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$LogDir = Join-Path $ProjectRoot "tests"
$LogFile = Join-Path $LogDir "last_run.log"

function Find-Godot {
    param([string]$Override)
    if ($Override -and (Test-Path $Override)) { return $Override }

    $candidates = @(
        (Get-Command godot -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source),
        "$env:LOCALAPPDATA\Godot\Godot_v4.3-stable_win64.exe",
        "$env:LOCALAPPDATA\Godot\Godot_v4.4-stable_win64.exe",
        "${env:ProgramFiles}\Godot\Godot_v4.3-stable_win64.exe",
        "${env:ProgramFiles(x86)}\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"
    )

    foreach ($path in $candidates) {
        if ($path -and (Test-Path $path)) { return $path }
    }

    $searchRoots = @(
        "$env:LOCALAPPDATA\Godot",
        "${env:ProgramFiles}\Godot",
        "$env:USERPROFILE\Downloads"
    )
    foreach ($root in $searchRoots) {
        if (-not (Test-Path $root)) { continue }
        $found = Get-ChildItem -Path $root -Recurse -Filter "Godot*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found -and (Test-Path $found.FullName)) { return $found.FullName }
    }
    return $null
}

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

$godot = Find-Godot -Override $GodotPath
if (-not $godot) {
    $msg = @"
[SKIP] Godot executable not found.
Install Godot 4.3+ from https://godotengine.org/download/windows/
Then run: .\scripts\run_tests.ps1 -GodotPath `"C:\path\to\Godot.exe`"
"@
    $msg | Out-File -FilePath $LogFile -Encoding utf8
    Write-Host $msg
    exit 2
}

Write-Host "Using Godot: $godot"
Write-Host "Project: $ProjectRoot"
Write-Host "Note: skipping CLI --headless --import (can hang). Use Godot Editor Project -> Reload if assets changed."

"" | Out-File -FilePath $LogFile -Encoding utf8

& $godot --path $ProjectRoot --headless res://tests/test_runner.tscn 2>&1 | Tee-Object -FilePath $LogFile -Append
$testExit = $LASTEXITCODE

Write-Host ""
Write-Host "Log: $LogFile"
Write-Host "Exit code: $testExit (0 = 