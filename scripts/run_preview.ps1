# Exiled Survivors — launch game window for visual preview
# Usage: .\scripts\run_preview.ps1 [-GodotPath "C:\path\to\Godot.exe"] [-Scene "res://scenes/main_menu/main_menu.tscn"]

param(
    [string]$GodotPath = "",
    [string]$Scene = ""
)

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

function Find-Godot {
    param([string]$Override)
    if ($Override -and (Test-Path $Override)) { return $Override }
    $cmd = Get-Command godot -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $roots = @("$env:LOCALAPPDATA\Godot", "${env:ProgramFiles}\Godot", "$env:USERPROFILE\Downloads")
    foreach ($root in $roots) {
        if (Test-Path $root) {
            $found = Get-ChildItem -Path $root -Recurse -Filter "Godot*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($found) { return $found.FullName }
        }
    }
    return $null
}

$godot = Find-Godot -Override $GodotPath
if (-not $godot) {
    Write-Host "Godot not found. Install from https://godotengine.org/download/windows/"
    Write-Host "Then: .\scripts\run_preview.ps1 -GodotPath `"C:\path\to\Godot_v4.3-stable_win64.exe`""
    exit 1
}

Write-Host "Launching Exiled Survivors..."
Write-Host "Godot: $godot"
Write-Host "Tip: Press F5 in the editor, or use Solo/Co-op on the main menu."

$args = @("--path", $ProjectRoot)
if ($Scene) {
    $args += $Scene
}

Start-Process -FilePath $godot -ArgumentList $args
exit 0
