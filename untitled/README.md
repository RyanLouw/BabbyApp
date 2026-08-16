# Babby Care

A feature-first Flutter/Material 3 Android client for fast, shared newborn-care tracking. Firebase Authentication owns sessions; Firestore stores `families/{familyId}/members`, `babies`, and each baby's `events`. Event documents keep a small common envelope and a typed `data` map, making future event types additive.

## Google Play release checklist

The app now uses Google's UMP consent flow before requesting a bottom banner,
and Google's native immediate in-app update flow when Play reports a newer
version. The update integration intentionally does not use the third-party
`in_app_update` Flutter package, so dependency resolution cannot fail on that
package.
Debug builds use Google's official test ad identifiers. Before uploading a
release, complete all of these steps:

1. Create the Android app in AdMob and create a banner unit. In **Privacy &
   messaging**, publish the consent message for the countries where the app is
   available. Never use the checked-in test identifiers for real traffic.
2. Put the AdMob **app ID** (the value containing `~`) in your user-level
   `~/.gradle/gradle.properties` as `ADMOB_APP_ID=ca-app-pub-...~...`. Do not
   put the secret in this repository. Pass the banner **unit ID** (the value containing `/`) to
   the release build:

   ```bash
   flutter build appbundle --release \
     --dart-define=ADMOB_BANNER_ID=ca-app-pub-.../...
   ```

3. Replace the debug signing configuration in `android/app/build.gradle.kts`
   with a private upload-key signing configuration. Back up the upload keystore
   and passwords outside the repository, then enroll in Play App Signing.
4. Increase both parts of `version` in `pubspec.yaml` for every upload (for
   example, `1.0.1+2`). Play requires every bundle to have a unique, increasing
   build number. Publish through an internal testing track first: Play's update
   API cannot report updates for a locally installed APK.
5. Complete Play Console's Data safety, Ads, content rating, target audience,
   app access, and privacy-policy declarations. The privacy policy should
   describe Firebase Authentication/Firestore, AdMob, account deletion, data
   retention, and how caregivers can request support.
6. Test account creation, family permissions, offline/reconnect behavior,
   notification permissions, consent choices, ad loading, update enforcement,
   accessibility, and deletion on a physical device from the Play internal
   testing track. Also configure Crashlytics/performance monitoring before a
   public launch so production failures can be diagnosed.

Immediate updates are deliberately enforced whenever Google Play reports that
an update exists. If staged rollouts or optional updates are wanted later, put a
minimum-supported build number in Firebase Remote Config and only block builds
below that number instead of requiring every available update.

### Dependency resolution reports a socket error

The Play update feature uses the native Android Play library and does not
require the `in_app_update` package. If an old checkout still reports that
package, pull this revision and run `flutter pub get` again. A socket error for
another package means the machine cannot currently reach `https://pub.dev`; it
is not a Dart dependency-version conflict. Check VPN/proxy/firewall settings,
confirm the URL opens in a browser, and then run:

```bat
C:\dev\flutter\bin\flutter.bat pub get
```

Do not disable TLS verification or download unofficial package archives. The
native Play dependency is downloaded by Gradle from Google's Maven repository
the first time Android is built.

### Fix `Could not get unknown property 'all'` in `google_mobile_ads`

That Gradle configuration error comes from `google_mobile_ads` 6.x, which is not
compatible with this project's Gradle 9 / Android Gradle Plugin 9 toolchain.
The project now requires `google_mobile_ads` 9.1 or newer. After pulling the
latest revision, remove the old generated state and resolve packages again:

```bat
cd /d C:\dev\BabbyApp\untitled
C:\dev\flutter\bin\flutter.bat clean
if exist .dart_tool rmdir /s /q .dart_tool
C:\dev\flutter\bin\flutter.bat pub get
C:\dev\flutter\bin\flutter.bat run
```

The Java `System::load` native-access lines are warnings from Gradle and are not
the cause of this failure. Do not edit the cached package under
`AppData\Local\Pub\Cache`; `pub get` selects the compatible package declared by
this repository.

## Windows prerequisite: make `flutter` available

The Flutter and FlutterFire commands are currently unavailable if PowerShell reports *“The term 'flutter' is not recognized”*. The Android Studio Flutter plugin does not make a Flutter SDK executable available to every terminal by itself.

### Fix “Building with plugins requires symlink support”

This message is a Windows workstation setting, not an AdMob dependency error.
Packages downloaded successfully; Flutter stopped afterward because Windows did
not allow it to create the plugin symlinks used by `google_mobile_ads` and other
Flutter plugins.

1. Press **Windows+R**, enter `ms-settings:developers`, and press **Enter** (or
   run `start ms-settings:developers` from Command Prompt).
2. Turn **Developer Mode** on and accept the confirmation. You do not need to
   enable Device Portal or Device Discovery.
3. Close Android Studio and all terminals, reopen them, and run:

   ```bat
   cd /d C:\dev\BabbyApp\untitled
   C:\dev\flutter\bin\flutter.bat clean
   C:\dev\flutter\bin\flutter.bat pub get
   C:\dev\flutter\bin\flutter.bat run
   ```

The repository setup helper now checks this setting and opens the correct
Windows page when it is disabled:

```bat
tool\configure_windows.cmd C:\dev\flutter
```

If Developer Mode is controlled by an employer or school policy, ask the
administrator to enable symbolic-link development. Moving the project, changing
the emulator, or repeatedly running `pub get` will not bypass that policy.

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

### `C:\dev\flutter` exists but `flutter` is not recognized

Having the SDK directory on disk is not enough: Command Prompt only finds executables in the current directory or in the `PATH` environment variable. First verify the SDK was extracted at the expected depth:

```bat
dir C:\dev\flutter\bin\flutter.bat
```

If that file exists, test Flutter directly and make it available in the current Command Prompt:

```bat
C:\dev\flutter\bin\flutter.bat --version
set "PATH=C:\dev\flutter\bin;%PATH%"
flutter --version
```

Then persist the path for future terminals with the repository helper:

```bat
cd /d C:\dev\BabbyApp\untitled
tool\configure_windows.cmd C:\dev\flutter
```

Close **all** existing Command Prompt/Android Studio terminal tabs and open a new one after the helper finishes. Existing parent terminals do not receive environment changes made by a child PowerShell process. Verify the new terminal with `where flutter`.

If `dir C:\dev\flutter\bin\flutter.bat` reports that the file cannot be found, locate it:

```bat
dir /s /b C:\dev\flutter\flutter.bat
```

For example, if it prints `C:\dev\flutter\flutter\bin\flutter.bat`, the SDK was extracted with an extra nested `flutter` folder; use `C:\dev\flutter\flutter` as the SDK path or move that inner folder up one level.

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
4. Enable Authentication and create Firestore by following the detailed console steps below. The Google Services Gradle plugin is already configured in this repository.
5. Run:

   ```powershell
   flutter clean
   flutter pub get
   flutter run
   ```

`Firebase.initializeApp()` discovers the Android configuration generated from that JSON file, so `flutterfire configure` is not necessary when Android is the only target.

### Enable Email/Password Authentication

1. Open the [Firebase console](https://console.firebase.google.com/) and select the **Babby Care** project.
2. In the left menu, select **Build → Authentication**.
3. Select **Get started** if this is the first authentication provider.
4. Open the **Sign-in method** tab, select **Email/Password** under *Native providers*, and turn on the first **Email/Password** switch.
5. Leave **Email link (passwordless sign-in)** disabled for V1, then select **Save**.

No user needs to be created manually: the app's registration screen calls Firebase Authentication to create accounts. For a quick console-only test, use **Authentication → Users → Add user**.

Official reference: [Firebase email/password authentication for Flutter](https://firebase.google.com/docs/auth/flutter/password-auth).

If Android logs `The email address is badly formatted`, Firebase was reached but rejected the submitted value. Enter a complete email such as `ryan@example.com` in **Email address**; enter `Ryan` in the separate **Your name** field. A Firebase connection or provider-configuration failure uses a different error code, such as `network-request-failed` or `operation-not-allowed`. The app validates these fields before submitting and shows a user-friendly message instead of exposing the Firebase log.

### Create the Cloud Firestore database

1. In the same Firebase project, select **Build → Firestore Database**.
2. Select **Create database**. If Firebase asks for an edition, choose **Standard edition**.
3. Choose **Start in production mode**. Do not leave the database in test mode; test mode permits overly broad access for a limited period.
4. Choose a database location near the caregivers who will use the app. Treat this choice as permanent, then select **Enable**.
5. Do not manually create `users` or `families` collections. Firestore creates collections when the app writes its first documents.
6. From the `untitled` project directory, deploy this repository's membership-based rules and event index:

   ```powershell
   npm install -g firebase-tools
   firebase login
   firebase use --add
   firebase deploy --only firestore:rules,firestore:indexes
   ```

   When `firebase use --add` asks which project to use, select **Babby Care** and choose an alias such as `default`.

7. In the Firebase console, open **Firestore Database → Rules** and confirm the deployed rules begin with `rules_version = '2';`. Open **Indexes** and wait until the events index reports **Enabled** before relying on cross-baby history queries.

Official reference: [Get started with Cloud Firestore](https://firebase.google.com/docs/firestore/quickstart).

### Fix `PERMISSION_DENIED: Missing or insufficient permissions`

Successful Firebase Authentication followed by a denied `users/{uid}` listen means the app connected and signed in, but the Firestore database is still using rules that do not allow the request—usually the default production-mode rules. It does **not** mean the user document must be manually created.

From the directory containing `firebase.json`, deploy the repository rules to the same Firebase project used by `android/app/google-services.json`:

```bat
cd /d C:\dev\BabbyApp\untitled
firebase login
firebase use
firebase deploy --only firestore:rules,firestore:indexes
```

If `firebase use` does not show the correct Firebase project ID, run `firebase use --add`, select the project referenced by the `project_id` field in `android/app/google-services.json`, and deploy again. In **Firebase Console → Firestore Database → Rules**, confirm the published rules include `match /users/{uid}` and then fully restart the app.

Authentication succeeding proves that `google-services.json` points to a real Firebase project. It does not deploy or change that project's Firestore security rules: Authentication and Firestore are separate Firebase services. Therefore, a valid login and a Firestore `PERMISSION_DENIED` can occur together.

If PowerShell reports that `firebase` is not recognized, Firebase CLI is not installed or is not on `PATH`. If Node.js is installed, use `npx` without a global installation:

```powershell
node --version
npm --version
npx --yes firebase-tools login
npx --yes firebase-tools use --add
npx --yes firebase-tools deploy --only firestore:rules,firestore:indexes
```

When selecting a project, match the `project_id` shown by:

```powershell
Select-String -Path .\android\app\google-services.json -Pattern 'project_id'
```

The repository also provides a Command Prompt/PowerShell-compatible wrapper that checks the required files and runs those `npx` commands:

```powershell
.\deploy-firebase.cmd
```

If PowerShell says the script itself is not recognized, verify whether the file is present in your checkout:

```powershell
Test-Path .\deploy-firebase.cmd
Test-Path .\tool\deploy_firebase.cmd
Get-ChildItem .\tool
```

`False` means the local checkout does not contain the helper; a command cannot run a file that is absent. Update/copy the latest repository changes, or skip the helper and run the `npx --yes firebase-tools ...` commands above directly. Since `npm -v` works, `npx` should already be available; verify it with `npx --version`.

If `node` or `npm` is also not recognized, install the current Node.js LTS release from [nodejs.org](https://nodejs.org/), close and reopen the terminal, and run the wrapper again.

### Sign-in persistence

Firebase Authentication persists the Android user session automatically. The app router listens to `authStateChanges()`: it opens **Home** for an existing session, redirects signed-out users to **Login**, and only forgets the session after the user selects **Logout**. There is no separate “Remember me” checkbox because remembering the authenticated user is the safe default on Android.

### Android `WindowOnBackDispatcher` messages

Messages such as `W/WindowOnBackDispatcher: sendCancelIfRunning` are Android diagnostic warnings emitted when an in-progress or potential back gesture is cancelled. They are not a Firebase, Firestore, login, or application crash error and require no user action when navigation continues to work. The Android manifest explicitly enables the modern back-invoked callback used by current Flutter versions. Investigate further only if the UI actually fails to go back; in that case capture the first `E/` line or Dart exception around the failure rather than repeated dispatcher warnings.

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

History intentionally listens to each known baby's `events` subcollection and merges the results on-device. It does not use a cross-family collection-group query. This aligns the query path with the membership rules, works from Firestore's local cache, and prevents a valid family member from receiving `PERMISSION_DENIED` when opening History. New writes appear through the same snapshot streams without manually refreshing the page.
