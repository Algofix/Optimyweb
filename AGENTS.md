# Optimyweb

Flutter mobile/web app (project + task tracker) backed by Firebase **Firestore** and **Storage**. See `README.md` for the product overview and Firebase setup, and `docs/firestore-schema.md` for the data model.

## Cursor Cloud specific instructions

### Toolchain
- Flutter SDK (stable, Dart >= 3.12) is installed at `$HOME/flutter` and is on `PATH` via `~/.bashrc`. If a non-interactive shell can't find `flutter`, call it directly as `$HOME/flutter/bin/flutter` or `export PATH="$HOME/flutter/bin:$HOME/.pub-cache/bin:$PATH"`.
- This is a headless Linux VM: only the **web** target is runnable (no Android SDK / iOS toolchain). Use `-d web-server` (or `-d chrome`). `flutter build web` works.
- `firebase-tools` is installed globally via the nvm Node (`~/.nvm/versions/node/v22.22.2/bin`). The system `node` on `PATH` (`/exec-daemon/node`) has an unwritable npm prefix (`/`); use the nvm Node for any `npm -g` installs.

### Standard commands (run from repo root)
- Install deps: `flutter pub get`
- Lint: `flutter analyze` — note it exits non-zero because of 2 pre-existing **info**-level `deprecated_member_use` warnings in `lib/screens/project_form_screen.dart`; there are no errors.
- Test: `flutter test`
- Build web: `flutter build web`
- Run web (dev): `flutter run -d web-server --web-port 8090 --web-hostname 0.0.0.0`

### Running the app without real Firebase credentials (non-obvious)
`main.dart` calls `Firebase.initializeApp(...)` at startup, and `lib/firebase_options.dart` ships with `REPLACE_ME` placeholders. To actually run/interact with the app locally without a real Firebase project, use the **Firebase Local Emulator Suite** with a demo project. This requires two *temporary* edits (do NOT commit them):
1. In `lib/firebase_options.dart`, set the `web` `FirebaseOptions` to a demo project, e.g. `projectId: 'demo-optimyweb'`, `apiKey: 'demo-api-key'`, `appId: '1:1234567890:web:demoapp'`, `messagingSenderId: '1234567890'` (demo projects skip credential validation).
2. In `lib/main.dart`, after `initializeApp`, add `FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);` (import `package:cloud_firestore/cloud_firestore.dart`).

Then start the emulator and the app:
```bash
firebase emulators:start --only firestore --project demo-optimyweb   # serves Firestore on 127.0.0.1:8080, UI on :4000
flutter run -d web-server --web-port 8090 --web-hostname 0.0.0.0
```
Open `http://localhost:8090` in Chrome. Revert the two temporary edits before committing. A real deployment instead uses `flutterfire configure` to generate real `firebase_options.dart` (see `README.md`).
