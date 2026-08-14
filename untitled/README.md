# Babby Care

A feature-first Flutter/Material 3 Android client for fast, shared newborn-care tracking. Firebase Authentication owns sessions; Firestore stores `families/{familyId}/members`, `babies`, and each baby's `events`. Event documents keep a small common envelope and a typed `data` map, making future event types additive.

## Windows prerequisite: make `flutter` available

The Flutter and FlutterFire commands are currently unavailable if PowerShell reports *“The term 'flutter' is not recognized”*. The Android Studio Flutter plugin does not make a Flutter SDK executable available to every terminal by itself.

1. Download the stable Flutter SDK using the [official Windows manual installation guide](https://docs.flutter.dev/install/manual) and extract it to a simple writable path such as `C:\src\flutter`. Do not place it under `Program Files`.
2. Confirm the SDK was actually extracted. This file must exist before continuing:

   ```text
   C:\src\flutter\bin\flutter.bat
   ```

3. Check the prompt you are using:

   * `PS C:\...>` means **PowerShell**. Run:

   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\tool\configure_windows.ps1 -FlutterSdk C:\src\flutter
   ```

   * `C:\...>` without `PS` means **Command Prompt (`cmd.exe`)**. `Set-ExecutionPolicy` is not a Command Prompt command. Run the included Command Prompt wrapper instead:

   ```bat
   tool\configure_windows.cmd C:\src\flutter
   ```

   Or invoke PowerShell explicitly from Command Prompt:

   ```bat
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tool\configure_windows.ps1" -FlutterSdk "C:\src\flutter"
   ```

   `C:\src\flutter` is an example, not a directory created by these commands. Replace it with the real directory where you extracted Flutter. Do not type placeholders such as `C:\your\actual\flutter` literally.

   The scripts validate `bin\flutter.bat`, add the SDK's `bin` directory to both the current PowerShell process and the persistent **user PATH**, then run `flutter --version` and `flutter doctor -v`.
4. Close and reopen your terminal, then verify:

   ```powershell
   where.exe flutter
   flutter --version
   flutter doctor -v
   ```

5. In Android Studio, open **Settings → Languages & Frameworks → Flutter** and point **Flutter SDK path** to the same folder (`C:\src\flutter`, not its `bin` directory). Install any Android SDK components or accept licenses reported by `flutter doctor`:

   ```powershell
   flutter doctor --android-licenses
   ```

The PSReadLine warning shown by Android Studio is unrelated to Flutter and does not cause the command-not-found error.

## Firebase setup

### Android only (no FlutterFire CLI required)

1. In the [Firebase console](https://console.firebase.google.com/), create a project with the display name **Babby Care**. Firebase also asks for a globally unique project ID; accept its suggestion (for example, `babby-care-12345`). The project ID does not need to match the Android package name. Google Analytics is optional for this app.
2. Add an **Android app** to that Firebase project with these values:

   | Firebase field | Value |
   | --- | --- |
   | Android package name | `com.babbycare.app` |
   | App nickname | `Babby Care Android` (optional) |
   | Debug signing certificate SHA-1 | Leave blank for email/password authentication |

   The package name must match exactly; it is already configured as both `namespace` and `applicationId` in `android/app/build.gradle.kts`.
3. Download Firebase's real `google-services.json`. Put it in the **same folder** as the example, but keep the real filename:

   ```text
   untitled/android/app/google-services.json
   ```

   Do **not** rename it to `google-services.json.example`, and do not overwrite or edit the example file. The real file is intentionally ignored by Git.
4. Enable **Authentication → Sign-in method → Email/Password**, then create a Cloud Firestore database. The Google Services Gradle plugin is already configured in this repository.
5. Run:

   ```powershell
   flutter clean
   flutter pub get
   flutter run
   ```

`Firebase.initializeApp()` discovers the Android configuration generated from that JSON file, so `flutterfire configure` is not necessary when Android is the only target.

### Installing `flutterfire` on Windows (multi-platform configuration)

`flutterfire` is a separate CLI; installing the Flutter SDK does not install it. In PowerShell, run:

```powershell
# The Firebase CLI is a prerequisite. Install Node.js first if npm is unavailable.
npm install -g firebase-tools
firebase login

dart pub global activate flutterfire_cli

# Make globally activated Dart executables visible in this PowerShell session.
$env:Path += ";$env:LOCALAPPDATA\Pub\Cache\bin"
flutterfire --version
flutterfire configure
```

Alternatively, after Flutter is installed, the repository helper can install FlutterFire and persist its PATH entry:

```powershell
.\tool\configure_windows.ps1 -FlutterSdk C:\src\flutter -InstallFlutterFire
```

If your machine still cannot resolve `flutterfire`, the PATH-independent equivalent is:

```powershell
dart pub global run flutterfire_cli:flutterfire configure
```

To make the command available in future terminals, add `%LOCALAPPDATA%\Pub\Cache\bin` to the user `Path` environment variable and then open a new PowerShell window. Do not commit `google-services.json` or generated credentials.

### Deploy Firestore configuration

From the project directory, select the Firebase project and deploy the included rules and index:

```powershell
firebase use --add
firebase deploy --only firestore:rules,firestore:indexes
```

Firestore disk persistence is explicitly enabled with an unlimited cache. Writes therefore complete against the local cache while offline and sync when connectivity returns. Documents store UTC Firestore timestamps and use `updatedAt`/`updatedBy` for deliberately simple last-write-wins conflict handling.

The collection-group history query requires the included `familyId ASC, startDateTime DESC` index. Security rules independently validate family membership and parent baby identity rather than trusting client paths or fields.
