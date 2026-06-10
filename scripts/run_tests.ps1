# Exiled Survivors — headless test runner with live progress
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

function Format-Elapsed {
    param([TimeSpan]$Span)
    if ($Span.TotalHours -ge 1) {
        return $Span.ToString("hh\:mm\:ss")
    }
    return $Span.ToString("mm\:ss\.f")
}

function Process-TestLine {
    param(
        [string]$Line,
        [ref]$PassCount,
        [ref]$FailCount,
        [System.Collections.Generic.List[string]]$LogBuffer
    )
    if ($Line -match '^\[PASS\]') { $PassCount.Value++ }
    elseif ($Line -match '^\[FAIL\]') { $FailCount.Value++ }
    Write-Host $Line
    $LogBuffer.Add($Line) | Out-Null
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

Write-Host "=== Exiled Survivors Test Runner ==="
Write-Host "Using Godot: $godot"
Write-Host "Project: $ProjectRoot"
Write-Host "Note: skipping CLI --headless --import (can hang). Use Godot Editor Project -> Reload if assets changed."
Write-Host ""

$startTime = Get-Date
Write-Host "Started: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Host ""

$logBuffer = [System.Collections.Generic.List[string]]::new()
$passCount = 0
$failCount = 0
$lastHeartbeat = $startTime
$heartbeatSeconds = 5

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $godot
$psi.Arguments = "--path `"$ProjectRoot`" --headless res://tests/test_runner.tscn"
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$psi.WorkingDirectory = $ProjectRoot

$proc = New-Object System.Diagnostics.Process
$proc.StartInfo = $psi
$null = $proc.Start()

while (-not $proc.HasExited) {
    $stdoutLine = $proc.StandardOutput.ReadLine()
    while ($null -ne $stdoutLine) {
        Process-TestLine -Line $stdoutLine -PassCount ([ref]$passCount) -FailCount ([ref]$failCount) -LogBuffer $logBuffer
        $stdoutLine = $proc.StandardOutput.ReadLine()
    }

    $stderrLine = $proc.StandardError.ReadLine()
    while ($null -ne $stderrLine) {
        if ($stderrLine.Trim() -ne "") {
            Process-TestLine -Line $stderrLine -PassCount ([ref]$passCount) -FailCount ([ref]$failCount) -LogBuffer $logBuffer
        }
        $stderrLine = $proc.StandardError.ReadLine()
    }

    $now = Get-Date
    if (($now - $lastHeartbeat).TotalSeconds -ge $heartbeatSeconds) {
        $elapsed = Format-Elapsed -Span ($now - $startTime)
        Write-Host "[..] still running... ${elapsed}  (pass: $passCount, fail: $failCount)"
        $lastHeartbeat = $now
    }

    Start-Sleep -Milliseconds 100
}

while ($true) {
    $stdoutLine = $proc.StandardOutput.ReadLine()
    if ($null -eq $stdoutLine) { break }
    Process-TestLine -Line $stdoutLine -PassCount ([ref]$passCount) -FailCount ([ref]$failCount) -LogBuffer $logBuffer
}

while ($true) {
    $stderrLine = $proc.StandardError.ReadLine()
    if ($null -eq $stderrLine) { break }
    if ($stderrLine.Trim() -ne "") {
        Process-TestLine -Line $stderrLine -PassCount ([ref]$passCount) -FailCount ([ref]$failCount) -LogBuffer $logBuffer
    }
}

$testExit = $proc.ExitCode
$endTime = Get-Date
$totalElapsed = Format-Elapsed -Span ($endTime - $startTime)

$logBuffer | Out-File -FilePath $LogFile -Encoding utf8

Write-Host ""
Write-Host "=== Summary ==="
Write-Host "Elapsed: $totalElapsed"
Write-Host "Passed:  $passCount"
Write-Host "Failed:  $failCount"
Write-Host "Log:     $LogFile"
Write-Host "Exit:    $testExit (0 = all passed)"

exit $testExit
