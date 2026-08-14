@echo off
setlocal

if "%~1"=="" goto :usage
set "FLUTTER_SDK=%~1"

if not exist "%FLUTTER_SDK%\bin\flutter.bat" (
  echo ERROR: Flutter was not found at "%FLUTTER_SDK%".
  echo Expected this file: "%FLUTTER_SDK%\bin\flutter.bat"
  echo.
  echo Download and extract the Flutter SDK first:
  echo https://docs.flutter.dev/install/manual
  exit /b 2
)

if not exist "%~dp0configure_windows.ps1" (
  echo ERROR: Missing "%~dp0configure_windows.ps1".
  echo Update your repository checkout and try again.
  exit /b 3
)

echo Configuring Flutter from "%FLUTTER_SDK%"...
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0configure_windows.ps1" -FlutterSdk "%FLUTTER_SDK%" %2
if errorlevel 1 exit /b %ERRORLEVEL%
echo.
echo IMPORTANT: Close this Command Prompt and open a new one, then run:
echo   where flutter
echo   flutter --version
echo To use Flutter in this terminal immediately, run:
echo   set "PATH=%FLUTTER_SDK%\bin;%%PATH%%"
exit /b 0

:usage
echo Usage from Command Prompt:
echo   tool\configure_windows.cmd C:\src\flutter
echo.
echo The directory must already contain bin\flutter.bat.
exit /b 1
