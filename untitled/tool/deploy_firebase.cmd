@echo off
setlocal
cd /d "%~dp0.."

where npm >nul 2>nul
if errorlevel 1 (
  echo ERROR: Node.js and npm are required.
  echo Install the Node.js LTS release from https://nodejs.org/ then open a new terminal.
  exit /b 2
)

if not exist "firebase.json" (
  echo ERROR: firebase.json was not found in "%CD%".
  exit /b 3
)

if not exist "android\app\google-services.json" (
  echo ERROR: android\app\google-services.json was not found.
  exit /b 4
)

echo This app can authenticate, but Firestore rules must be deployed separately.
echo The Firebase project ID configured by the Android app is:
findstr /C:"project_id" "android\app\google-services.json"
echo.

call npx --yes firebase-tools login
if errorlevel 1 exit /b %ERRORLEVEL%

call npx --yes firebase-tools use --add
if errorlevel 1 exit /b %ERRORLEVEL%

call npx --yes firebase-tools deploy --only firestore:rules,firestore:indexes
if errorlevel 1 exit /b %ERRORLEVEL%

echo.
echo Firestore rules and indexes were deployed successfully.
exit /b 0
