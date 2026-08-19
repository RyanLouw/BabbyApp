[CmdletBinding()]
param(
    [string]$FlutterSdk,
    [switch]$InstallFlutterFire
)

$ErrorActionPreference = 'Stop'

if ($FlutterSdk -and -not (Test-Path (Join-Path $FlutterSdk 'bin\flutter.bat'))) {
    throw "Flutter SDK is not present at '$FlutterSdk'. Expected '$FlutterSdk\bin\flutter.bat'. Download and extract Flutter before running this script."
}

function Add-UserPathEntry([string]$Entry) {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $entries = @($userPath -split ';' | Where-Object { $_ })
    if ($entries -notcontains $Entry) {
        [Environment]::SetEnvironmentVariable('Path', (($entries + $Entry) -join ';'), 'User')
        Write-Host "Added $Entry to your user PATH." -ForegroundColor Green
    }
    if (($env:Path -split ';') -notcontains $Entry) {
        $env:Path = "$env:Path;$Entry"
    }
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    $candidates = @(
        $FlutterSdk,
        "$env:USERPROFILE\development\flutter",
        'C:\src\flutter',
        'C:\dev\flutter'
    ) | Where-Object { $_ }
    $sdk = $candidates | Where-Object { Test-Path (Join-Path $_ 'bin\flutter.bat') } | Select-Object -First 1
    if (-not $sdk) {
        throw @"
Flutter SDK was not found. Android Studio alone does not install Flutter for PowerShell.

1. Follow https://docs.flutter.dev/install/manual and extract the stable SDK, for example to C:\src\flutter.
2. Run this script again:
   powershell -ExecutionPolicy Bypass -File .\tool\configure_windows.ps1 -FlutterSdk C:\src\flutter
"@
    }
    Add-UserPathEntry (Join-Path $sdk 'bin')
}

Write-Host 'Flutter detected:' -ForegroundColor Green
flutter --version
flutter doctor -v

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Write-Host "`nInstalling packages from $projectRoot..." -ForegroundColor Green
Push-Location $projectRoot
try {
    flutter pub get
} finally {
    Pop-Location
}

if ($InstallFlutterFire) {
    if (-not (Get-Command dart -ErrorAction SilentlyContinue)) {
        throw 'Dart was not found after configuring Flutter. Close PowerShell, open a new terminal, and rerun this script.'
    }
    dart pub global activate flutterfire_cli
    Add-UserPathEntry (Join-Path $env:LOCALAPPDATA 'Pub\Cache\bin')
    flutterfire --version
}

Write-Host "`nSetup complete. Flutter packages are installed and new terminals will use the saved PATH." -ForegroundColor Green
