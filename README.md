# Optimyweb

Flutter mobile app (Android, iOS) with Firebase **Firestore**, **Storage**, and optional **Hosting** for the web build.

## Open in VS Code or Cursor

1. **File → Open Folder** → `/Users/ajsmartinho/Optimyweb`
2. Install recommended extensions when prompted (Dart, Flutter, Firebase).
3. Add Flutter to your shell (once):

```bash
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## App structure

Optimyweb tracks **web optimization projects** (sites you improve) with per-project **tasks**.

| Screen | Purpose |
|--------|---------|
| **Home** | List projects, filter by status (Draft / Active / Done) |
| **New / Edit project** | Name, URL, goal, status, priority |
| **Project detail** | View project + checklist tasks (Firestore subcollection) |

Full Firestore field definitions: [docs/firestore-schema.md](docs/firestore-schema.md)

## Firebase setup (use a **new** project)

**Do not** link this app to `obres-publiques-piera` or any project you want left unchanged.

1. In [Firebase Console](https://console.firebase.google.com/), create a **new** project (e.g. `optimyweb`).
2. Enable **Firestore** and **Storage** in that project.
3. In the project folder:

```bash
cd /Users/ajsmartinho/Optimyweb
firebase login
dart pub global activate flutterfire_cli
export PATH="$PATH:$HOME/.pub-cache/bin"
flutterfire configure
```

Choose only your **new** Optimyweb Firebase project when prompted. That generates `lib/firebase_options.dart` and platform config files.

4. Run the app:

```bash
flutter pub get
flutter run
```

## Hosting (web build only)

Hosting publishes the Flutter **web** build, not the iOS/Android store apps:

```bash
flutter build web
firebase use <your-new-optimyweb-project-id>
firebase deploy --only hosting
```

## If apps were registered on the wrong Firebase project

If Android/iOS apps named `com.optimyweb.optimyweb` were added to another project by mistake, you can remove them in that project’s Firebase Console under **Project settings → Your apps**. This repo no longer contains config files for `obres-publiques-piera`.
