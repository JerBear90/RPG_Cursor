# Production death-restart audit — real game autoloads, real death pipeline, visible render for screenshots.
# Usage: .\scripts\run_production_death_audit.ps1

param(
    [string]$GodotPath = "C:\Users\jeram\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe",
    [int]$MaxMinutes = 8
)

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

function Resolve-GodotExe {
    param([string]$Path)
    if (-not $Path) { return $null }
    if (Test-Path -LiteralPath $Path -PathType Leaf) { return (Resolve-Path -LiteralPath $Path).Path }
    if (Test-Path -LiteralPath $Path -PathType Container) {
        $inside = Get-ChildItem -LiteralPath $Path -Filter "Godot*.exe" -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notmatch "console" } | Select-Object -First 1
        if ($inside) { return $inside.FullName }
    }
    return $null
}

$godot = Resolve-GodotExe -Path $GodotPath
if (-not $godot) {
    Write-Host "Godot not found. Pass -GodotPath or install Godot 4.x"
    exit 2
}

Write-Host "=== Production Death Restart Audit ==="
Write-Host "Godot: $godot"
Write-Host "Max runtime: $MaxMinutes minutes"

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $godot
$psi.Arguments = "--path `"$ProjectRoot`" -s res://tests/production_death_restart_audit.gd"
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.UseShellExecute = $false
$psi.WorkingDirectory = $ProjectRoot

$proc = [System.Diagnostics.Process]::Start($psi)
$deadline = (Get-Date).AddMinutes($MaxMinutes)
while (-not $proc.HasExited) {
    if ((Get-Date) -gt $deadline) {
        try { $proc.Kill() } catch {}
        Write-Host "[FAIL] Audit exceeded $MaxMinutes minutes - terminated"
        exit 1
    }
    if ($proc.StandardOutput.Peek() -ge 0) {
        Write-Host $proc.StandardOutput.ReadLine()
    }
    Start-Sleep -Milliseconds 50
}
while ($proc.StandardOutput.Peek() -ge 0) {
    Write-Host $proc.StandardOutput.ReadLine()
}
while ($proc.StandardError.Peek() -ge 0) {
    $err = $proc.StandardError.ReadLine()
    if ($err.Trim()) { Write-Host $err }
}

Write-Host "Exit: $($proc.ExitCode)"
Write-Host "Report: tests/production_death_restart_report.txt"
exit $proc.ExitCode
