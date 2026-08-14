# Babby Care

A feature-first Flutter/Material 3 Android client for fast, shared newborn-care tracking. Firebase Authentication owns sessions; Firestore stores `families/{familyId}/members`, `babies`, and each baby's `events`. Event documents keep a small common envelope and a typed `data` map, making future event types additive.

## Windows prerequisite: make `flutter` available

The Flutter and FlutterFire commands are currently unavailable if PowerShell reports *“The term 'flutter' is not recognized”*. The Android Studio Flutter plugin does not make a Flutter SDK executable available to every terminal by itself.

1. Download the stable Flutter SDK using the [official Windows manual installation guide](https://docs.flutter.dev/install/manual) and extract it to a simple writable path such as `C:\src\flutter`. Do not place it under `Program Files`.
2. From this repository, run the included setup check:

   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\tool\configure_windows.ps1 -FlutterSdk C:\src\flutter
   ```

   The script validates `bin\flutter.bat`, adds `C:\src\flutter\bin` to both the current session and the persistent **user PATH**, then runs `flutter --version` and `flutter doctor -v`.
3. Close and reopen PowerShell, then verify:

   ```powershell
   where.exe flutter
   flutter --version
   flutter doctor -v
   ```

4. In Android Studio, open **Settings → Languages & Frameworks → Flutter** and point **Flutter SDK path** to the same folder (`C:\src\flutter`, not its `bin` directory). Install any Android SDK components or accept licenses reported by `flutter doctor`:

   ```powershell
   flutter doctor --android-licenses
   ```

The PSReadLine warning shown by Android Studio is unrelated to Flutter and does not cause the command-not-found error.

## Firebase setup

### Android only (no FlutterFire CLI required)

1. Create a Firebase project and enable **Authentication → Sign-in method → Email/Password** and Cloud Firestore.
2. Register an Android app whose package name is `com.example.untitled`. If you use a different package name, update `applicationId` and `namespace` in `android/app/build.gradle.kts` first.
3. Download `google-services.json` and save it at **`android/app/google-services.json`** (not `Android/app` beside the project). The Google Services Gradle plugin is already configured in this repository.
4. Run:

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
