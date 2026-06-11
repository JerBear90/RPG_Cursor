# Exiled Survivors — quick launch (runs main menu directly, no editor)
# Usage: .\start` game.ps1
#        .\start` game.ps1 -Editor    # open Godot editor instead
#        .\start` game.ps1 -Test      # run .\scripts\run_tests.ps1 first, then launch

param(
    [string]$GodotPath = "C:\Users\jeram\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64.exe",
    [switch]$Editor,
    [switch]$Test
)

$ProjectRoot = $PSScriptRoot
$MainScene = "res://scenes/main_menu/main_menu.tscn"

function Resolve-GodotExe {
    param([string]$Path)
    if (-not $Path) { return $null }

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        return (Resolve-Path -LiteralPath $Path).Path
    }

    # Extracted Godot zips often create a folder named like the .exe file.
    if (Test-Path -LiteralPath $Path -PathType Container) {
        $inside = Get-ChildItem -LiteralPath $Path -Filter "Godot*.exe" -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notmatch "console" } |
            Select-Object -First 1
        if ($inside) { return $inside.FullName }
    }

    return $null
}

function Find-Godot {
    param([string]$Override)
    $resolved = Resolve-GodotExe -Path $Override
    if ($resolved) { return $resolved }

    $cmd = Get-Command godot -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $candidates = @(
        "$env:USERPROFILE\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64.exe",
        "$env:LOCALAPPDATA\Godot\Godot_v4.3-stable_win64.exe",
        "$env:LOCALAPPDATA\Godot\Godot_v4.4-stable_win64.exe",
        "$env:LOCALAPPDATA\Godot\Godot_v4.3-stable_win64_console.exe"
    )
    foreach ($path in $candidates) {
        $resolved = Resolve-GodotExe -Path $path
        if ($resolved) { return $resolved }
    }

    $roots = @("$env:LOCALAPPDATA\Godot", "${env:ProgramFiles}\Godot", "$env:USERPROFILE\Downloads")
    foreach ($root in $roots) {
        if (-not (Test-Path $root)) { continue }
        $found = Get-ChildItem -Path $root -Recurse -Filter "Godot*.exe" -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notmatch "console" } |
            Select-Object -First 1
        if ($found) { return $found.FullName }
    }
    return $null
}

function Resolve-GodotConsole {
    param([string]$GodotExe)
    $dir = Split-Path -Path $GodotExe -Parent
    $name = [System.IO.Path]::GetFileNameWithoutExtension($GodotExe)
    if ($name -notmatch "console$") {
        $console = Join-Path $dir ($name + "_console.exe")
        if (Test-Path -LiteralPath $console) { return $console }
    }
    return $GodotExe
}

function Test-AssetsImported {
    param([string]$GodotExe, [string]$Root)
    $probe = Join-Path $Root "tests\_import_probe.gd"
    @'
extends SceneTree
func _init() -> void:
	var ok := MeshLoader.load_scene("res://art/characters/player1/exiled_survivor_matt.gltf") != null
	if ok:
		ok = MeshLoader.load_scene("res://art/kenney/nature_kit/Models/GLTF format/ground_grass.glb") != null
	quit(0 if ok else 1)
'@ | Set-Content -LiteralPath $probe -Encoding UTF8 -NoNewline
    $console = Resolve-GodotConsole -GodotExe $GodotExe
    & $console --path $Root --headless -s res://tests/_import_probe.gd | Out-Null
    Remove-Item -LiteralPath $probe -ErrorAction SilentlyContinue
    return ($LASTEXITCODE -eq 0)
}

function Ensure-ProjectImported {
    param([string]$GodotExe, [string]$Root)
    if (Test-AssetsImported -GodotExe $GodotExe -Root $Root) { return $true }

    Write-Host "Importing project assets (first launch can take a few minutes)..."
    $console = Resolve-GodotConsole -GodotExe $GodotExe
    & $console --path $Root --import --headless
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Import failed (exit $LASTEXITCODE)."
        return $false
    }
    if (Test-AssetsImported -GodotExe $GodotExe -Root $Root) {
        Write-Host "Import complete."
        return $true
    }
    Write-Host "Note: Editor import did not finish, but runtime mesh loading is available."
    return $true
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
    Write-Host "Godot executable not found."
    Write-Host "Expected file, not folder. Example:"
    Write-Host "  C:\Users\jeram\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64.exe"
    Write-Host "Install Godot 4.3+ from https://godotengine.org/download/windows/"
    Write-Host "Or run: .\start` game.ps1 -GodotPath `"C:\path\to\Godot_v4.6.3-stable_win64.exe`""
    exit 1
}

Write-Host "Using Godot: $godot"
Write-Host "Project root: $((Resolve-Path -LiteralPath $ProjectRoot).Path)"
Write-Host "Project file: $((Resolve-Path -LiteralPath (Join-Path $ProjectRoot 'project.godot')).Path)"
Write-Host "Main scene: $MainScene"
Write-Host "Launch mode: editor project (not exported build)"

if (-not (Ensure-ProjectImported -GodotExe $godot -Root $ProjectRoot)) {
    exit 1
}

if ($Editor) {
    Write-Host "Opening Exiled Survivors in Godot editor..."
    Start-Process -FilePath $godot -WorkingDirectory $ProjectRoot -ArgumentList @("--path", $ProjectRoot, "--editor")
} else {
    Write-Host "Starting Exiled Survivors..."
    Start-Process -FilePath $godot -WorkingDirectory $ProjectRoot -ArgumentList @("--path", $ProjectRoot, $MainScene)
}

exit 0
