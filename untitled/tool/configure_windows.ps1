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

function Test-WindowsDeveloperMode {
    $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
    try {
        $value = Get-ItemPropertyValue -Path $key -Name 'AllowDevelopmentWithoutDevLicense' -ErrorAction Stop
        return $value -eq 1
    }
    catch {
        return $false
    }
}

if (-not (Test-WindowsDeveloperMode)) {
    Write-Warning @"
Windows Developer Mode is disabled. Flutter plugins (including AdMob) need it
so that pub can create symbolic links.

The Windows settings page will now open. Turn Developer Mode ON, accept the
confirmation, close this terminal, and then rerun this script. This setting is
on the development PC only; it does not change the Android app or emulator.
"@
    Start-Process 'ms-settings:developers'
    throw 'Enable Windows Developer Mode, then rerun the setup script.'
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

if ($InstallFlutterFire) {
    if (-not (Get-Command dart -ErrorAction SilentlyContinue)) {
        throw 'Dart was not found after configuring Flutter. Close PowerShell, open a new terminal, and rerun this script.'
    }
    dart pub global activate flutterfire_cli
    Add-UserPathEntry (Join-Path $env:LOCALAPPDATA 'Pub\Cache\bin')
    flutterfire --version
}

Write-Host "`nSetup check complete. New terminals will use the saved PATH." -ForegroundColor Green
