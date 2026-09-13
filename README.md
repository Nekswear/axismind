# AxisMind

**Axis of Mindfulness** — a meditation and focus timer app built with Flutter.

AxisMind helps you build a consistent meditation practice with a guided timer,
session journal, statistics, a gamified rank progression, meditation goals, and
optional Google-account sync across devices.

---

## Features

- **Meditation timer** — presets of 5 / 10 / 15 / 20 minutes with start and end gong sounds and keep-screen-on support.
- **Session journal** — log notes, mood rating and tags after every session.
- **Statistics** — daily chart, 30-day heatmap and a 7 / 14 / 30-day period switcher.
- **Meditation goals** — daily and weekly goals with bonus XP rewards.
- **Gamification** — 11 ranks from "Mindfulness Novice" to "Divine", with a visual rank roadmap.
- **Notifications** — daily reminders, motivational quotes, goal reminders and quiet hours (local + FCM push).
- **Google Sign-In + sync** — offline-first sync of sessions via Firestore.
- **Localization** — English and Russian (via ARB files).
- **Premium dark UI** — glassmorphic hero card, gyroscope 3D parallax (mobile), widescreen split layout (desktop/web), and a Samadhi end-of-session phase.

---

## Tech Stack

| Category | Packages |
|---|---|
| Database | `sqflite`, `sqflite_common_ffi`, `sqflite_common_ffi_web`, `path` |
| Charts | `fl_chart` |
| IDs | `uuid` |
| Audio | `audioplayers` |
| Screen / sensors | `wakelock_plus`, `sensors_plus` |
| State management | `flutter_bloc` |
| Firebase | `firebase_core`, `firebase_auth`, `google_sign_in`, `cloud_firestore`, `firebase_messaging` |
| Notifications | `flutter_local_notifications`, `timezone` |
| Localization | `flutter_localizations`, `intl` |

Fonts: **PlayfairDisplay** (headings) and **Manrope** (body).

---

## Requirements

- Flutter (stable channel). The project is developed against Flutter 3.41.x / Dart SDK `^3.11.5`.
- **JDK 17** for Android builds. Gradle 8.14 is **incompatible** with JDK 25/26 — do not use them.
- Android SDK **with `cmdline-tools`** installed.

---

## Getting Started

### 1. Clone and install dependencies

```bash
git clone https://github.com/Nekswear/zenbalance.git
cd zenbalance
flutter pub get
```

### 2. Configure the Android JDK (important)

Set Flutter to use JDK 17 (adjust the path to your JDK):

```bash
flutter config --jdk-dir "C:\Users\<you>\jdk-17"
```

Alternatively, set `JAVA_HOME` to a JDK 17 installation before building.

### 3. Accept Android licenses

```bash
flutter doctor --android-licenses
```

If `sdkmanager` is missing, install the Android SDK **Command-line tools**
component (via Android Studio SDK Manager) first.

### 4. Firebase configuration

AxisMind works without Firebase in local-only mode. To enable Google Sign-In
and cross-device sync:

1. In the [Firebase Console](https://console.firebase.google.com/), add an
   **Android** app with package name `com.axismind.app`.
2. Add your **debug SHA-1** fingerprint (Settings → Your apps → Android → Add fingerprint).
   Get it with:
   ```bash
   keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
   ```
3. Download `google-services.json` and place it at `android/app/google-services.json`.
   > This file is git-ignored — it must be added manually per checkout.
4. Copy `.env.example` to `.env` and fill in your Firebase values.

Firebase values are injected at build time via `--dart-define` (see `build_release_temp.ps1`),
so they are never hardcoded in the source.

---

## Running

```bash
flutter run
```

For a specific device:

```bash
flutter devices              # list available devices
flutter run -d emulator-5554 # Android emulator
flutter run -d chrome        # web
```

---

## Building

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Web
flutter build web

# Windows desktop
flutter build windows
```

> **Note:** the release Android build currently uses the debug signing key.
> Configure a production keystore before publishing.

---

## Testing

```bash
flutter analyze
flutter test
```

---

## Project Structure

```
lib/
├── main.dart                  # entry point, Firebase init, MaterialApp
├── app/                       # app-level configuration
├── core/
│   ├── theme/zen_theme.dart   # ZenStyles design tokens (dark theme)
│   └── widgets/zen_ui.dart    # atomic UI kit (ZenSurface, RankIcon, ...)
├── data/                      # repositories, DB provider, models
├── domain/                    # pure domain logic (progress calculator, events)
├── engine/                    # timer, gong, breath counter
├── l10n/                      # ARB files + generated AppLocalizations
├── screens/                   # feature screens and their widgets
├── services/                  # service locator, auth, notifications
├── utils/                     # helpers
└── widgets/                   # shared widgets (dialogs, states)
```

---

## License

Proprietary. All rights reserved.