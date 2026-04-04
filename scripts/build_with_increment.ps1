param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FlutterArgs
)

$ErrorActionPreference = 'Stop'

if (-not $FlutterArgs -or $FlutterArgs.Count -eq 0) {
    $FlutterArgs = @('build', 'apk')
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$pubspecPath = Join-Path $repoRoot 'pubspec.yaml'

if (-not (Test-Path $pubspecPath)) {
    throw "pubspec.yaml not found at $pubspecPath"
}

$content = Get-Content $pubspecPath -Raw
$pattern = 'version:\s*(\d+\.\d+\.\d+)\+(\d+)'
$match = [regex]::Match($content, $pattern)

if (-not $match.Success) {
    throw 'Could not parse version from pubspec.yaml'
}

$versionName = $match.Groups[1].Value
$currentBuild = [int]$match.Groups[2].Value
$newBuild = $currentBuild + 1
$newVersionLine = "version: $versionName+$newBuild"

$updated = [regex]::Replace($content, $pattern, $newVersionLine, 1)
Set-Content -Path $pubspecPath -Value $updated

$hasBuildNumberArg = $false
foreach ($arg in $FlutterArgs) {
    if ($arg -eq '--build-number' -or $arg.StartsWith('--build-number=')) {
        $hasBuildNumberArg = $true
        break
    }
}

Write-Host "Updated pubspec version to $versionName+$newBuild"

$cmdArgs = @()
$cmdArgs += $FlutterArgs
if (-not $hasBuildNumberArg) {
    $cmdArgs += @('--build-number', "$newBuild")
}

Write-Host "Running: flutter $($cmdArgs -join ' ')"
& flutter @cmdArgs
