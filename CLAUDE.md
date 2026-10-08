# CLAUDE.md — rules for every task in this repo

Read this before changing anything. These rules are permanent; a task may
override one only if it says so explicitly.

## Project

Flutter app (Android, iOS, Web) with a Firebase backend for Dar Afdal al-Uloom,
a Quran school of about 50 students. Three roles: `admin`, `teacher`,
`student`. The UI is Arabic only and right-to-left. Firebase project
`afdal-al-uloom`; every Firebase resource (Firestore, Storage, Functions) is in
region `me-west1`. The data model is a contract shared by the whole team:
`docs/PROJECT_PLAN.md` section 3. Do not change it (collections, fields, types)
unless the task says the change was agreed with Shadi.

Toolchain: Flutter 3.47.x stable. `google_fonts` is pinned to 8.2.1 (9.x breaks
on 3.47); the Cairo font is bundled in `assets/google_fonts/`, never fetched.
Docs for the team (`README.md`, `docs/`) are in Arabic; code, comments and this
file are in English.

## Architecture

Four layers. Dependencies point downward only.

1. **presentation** — screens and widgets. Render state, forward user events
   to a controller. No business logic, no Firebase imports, no repository calls.
2. **application** — Riverpod controllers (`Notifier` / `AsyncNotifier`), one
   per screen or flow. Hold UI state, validate input, call repositories and
   services. Pure Dart where possible so they are unit-testable.
3. **domain** — models (immutable, `fromMap` / `toMap`, no Firebase types such
   as `Timestamp` or `DocumentSnapshot`) and repository / service interfaces
   (abstract classes). Models are `const` unless their constructor validates
   (then it throws `ArgumentError`; asserts alone vanish in release builds).
4. **data** — Firebase implementations of those interfaces (Firestore,
   Storage, Functions, Auth). The ONLY place that imports Firebase packages,
   apart from `lib/app/firebase_setup.dart`, `lib/core/providers/` (wiring)
   and `lib/core/errors/firebase_error_mapper.dart`.

Wiring: providers in `lib/core/providers/` bind each interface to its
implementation. Tests override those providers with fakes.

```dart
// core/repositories/recording_repository.dart (domain)
/// Reads and writes recordings. Implementations must never return null lists.
abstract class RecordingRepository {
  Stream<List<Recording>> watchForStudent(String studentId);
}

// core/data/firestore_recording_repository.dart (data)
class FirestoreRecordingRepository implements RecordingRepository { ... }

// core/providers/repository_providers.dart
final recordingRepositoryProvider = Provider<RecordingRepository>(
  (ref) => FirestoreRecordingRepository(FirebaseFirestore.instance),
);
```

Providers are written by hand (no `riverpod_generator`) unless a task adds
code generation.

## Folder structure

```
lib/
  main.dart                     bootstrap only (binding, fonts, Firebase, runApp)
  app/                          app widget, router, theme, firebase_setup
  core/
    constants/                  ALL constants (see below)
    models/                     domain models
    repositories/               repository interfaces
    services/                   service interfaces (auth, audio storage, ...)
    data/                       Firebase implementations
    providers/                  dependency-injection providers
    errors/                     AppException + mapping of Firebase errors
    utils/                      small pure helpers
    widgets/common/             shared widgets (SchoolLogo, buttons,
                                empty / error / loading states)
  features/<feature>/           auth, admin, teacher, student
    presentation/               <name>_screen.dart, widgets/
    application/                <name>_controller.dart
test/                           mirrors lib/ (test/features/auth/..., test/app/...)
integration_test/               emulator-only tests
```

A feature never imports another feature's files. If two features need the
same thing, move it to `core/`. Only `app/router.dart` imports screens from
several features.

## Constants — no magic strings or numbers outside these files

All in `lib/core/constants/`, as `abstract final class` with `static const`:

| File | Class | Holds |
|---|---|---|
| `app_strings.dart` | `AppStrings` | every user-facing text (Arabic) |
| `app_routes.dart` | `AppRoutes` | route paths and route names |
| `app_assets.dart` | `AppAssets` | asset paths |
| `app_sizes.dart` | `AppSizes` | spacing, paddings, radii, icon / logo sizes |
| `app_durations.dart` | `AppDurations` | timeouts, animation durations |
| `firestore_paths.dart` | `FirestorePaths`, `Fields` | collection / subcollection / field names |
| `storage_paths.dart` | `StoragePaths` | Storage path builders |
| `firebase_constants.dart` | `FirebaseConstants` | region, project id, function names, emulator ports and hosts |

Colors and the text theme stay in `lib/app/theme.dart` (`kBrandGreen`,
`kBrandGold`). Never use `kBrandGold` for text on white (contrast too low).

```dart
// Wrong
Text('تسجيل الدخول'); const SizedBox(height: 24); context.go('/admin');
// Right
const Text(AppStrings.loginTitle);
const SizedBox(height: AppSizes.spaceL);
context.go(AppRoutes.admin);
```

Tests may use literal values when they assert behavior (e.g. "the region is
`me-west1`"), so a wrong constant is caught.

## Code rules

- One public class per file; file name is the class name in snake_case
  (`LoginScreen` -> `login_screen.dart`).
- Keep files short (aim for < 250 lines). Extract a widget when `build()`
  passes ~60-80 lines. Prefer a `StatelessWidget` class over a helper method
  that returns a widget.
- Prefer `const` constructors and immutable state. No `setState` for business
  state; `setState` is fine for purely visual local state (e.g. a password
  visibility toggle).
- Every async screen handles loading, error and empty states with the shared
  widgets in `core/widgets/common/` — never a blank screen.
- Errors: the data layer catches Firebase exceptions and throws `AppException`
  (an `AppErrorCode` plus the original error for logs). Controllers expose it
  as state; presentation shows `errorMessageFor(code)` (core/utils). Never
  show raw exception text.
- Naming: `XxxScreen`, `XxxController`, `XxxRepository` (interface),
  `FirestoreXxxRepository` (implementation), `xxxProvider`.
- Comments explain WHY, not what. Dartdoc (`///`) on every public interface
  and its members.
- Call Cloud Functions only through `regionalFunctions` (me-west1); never
  `FirebaseFunctions.instance` (that is us-central1).
- Firestore stores the Storage path (`storagePath`), never a download URL.
  Surahs are stored by number (1..114).
- `flutter analyze` must stay at zero issues; do not add `// ignore:` to
  silence a lint without a comment explaining why.

## Testing

- Controllers: unit tests with fake repositories injected via provider
  overrides (`ProviderContainer(overrides: [...])`).
- Screens: widget tests for the main states (loading, data, empty, error) and
  for navigation. Check Arabic text and a 360x640 phone without overflow.
- Repositories: unit tests on `FakeFirebaseFirestore` (fake_cloud_firestore).
- Firestore rules: every change to `firestore.rules` needs tests in
  `rules-tests/` (allowed AND denied) and a green
  `tool/test_rules.ps1` run. Storage rules: same, when they are added.
- Never hit the real Firebase project from a test. Integration tests that
  need Firebase must fail fast unless `USE_EMULATORS=true`.
- `flutter test` runs without network and without Firebase initialized.

## Firebase rules of work

- Develop and test against the Emulator Suite only:
  `powershell -ExecutionPolicy Bypass -File tool/emulators.ps1`, then
  `flutter run --dart-define=USE_EMULATORS=true`.
- Never run `firebase deploy`, never change console settings, never write to
  the real project, unless the task explicitly says so.
- Roles live in the `role` custom claim and are set only by server code.
- Test data: `tool/seed_emulator.ps1` (emulators running). Keep the seed
  valid under `firestore.rules`.
- A data model change (agreed with Shadi) updates, in one PR: PROJECT_PLAN.md
  section 3, the model, `Fields`, `firestore.rules` and its tests,
  `firestore.indexes.json` and the seed. See docs/DATA_LAYER.md.
- Keep `functions/src` region in sync with `FirebaseConstants.functionsRegion`.

## Branding assets

- Sources live in `assets/branding/`; only `logo_600.png` is bundled into the
  app (`AppAssets.logo`).
- App icons: `dart run flutter_launcher_icons` (Android / iOS).
- Web icons: `dart run tool/generate_web_icons.dart` (maskable icons come from
  `app_icon_foreground.png`).
- Splash: `dart run flutter_native_splash:create`.
- Run a generator only after changing its source image or config, and commit
  its output together with that change.

## Git

- `main` is the only long-lived branch. Ignore `develop`.
- Each task: `git checkout main && git pull`, then
  `git checkout -b feature/<name>-<topic>` (e.g. `feature/shadi-login`).
- Open a PR into `main`. Never push to `main`, never merge your own PR unless
  the task says so.
- Small logical commits. Stage files by name; never `git add .` or `git add -A`.
- Commit format: `feat:` `fix:` `refactor:` `test:` `docs:` `chore:` `build:`
  followed by a short English summary.
- Releases are tags on `main`: `v0.1.0`, `v0.2.0`, ...
- Never commit secrets (`serviceAccountKey.json`, `.env`), `.emulator-data/`
  or `.claude/`.

## Definition of done

- `flutter analyze` reports no issues.
- `flutter test` passes.
- `flutter build web` and `flutter build apk --debug` succeed.
- Arabic text and RTL layout are correct on a 360x640 phone.
- Loading, error and empty states are handled.
- The final report lists every decision that the task did not specify.
