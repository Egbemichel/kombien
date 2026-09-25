# Local Development

## Prerequisites

- **Flutter SDK** (stable channel) — see [Flutter's install docs](https://docs.flutter.dev/get-started/install). This repo was scaffolded against Flutter 3.38.
- **Node.js** (a maintained LTS version) — only needed for the brand asset validation script, not the app itself.
- Run `flutter doctor` and resolve anything it flags for the platform(s) you're targeting (Android/iOS/desktop/web) before running the app.

## Running the app

```bash
cd app
flutter pub get
flutter run
```

See [`../../app/README.md`](../../app/README.md) for the app's structure, how brand tokens map into the Flutter theme, and how to replace a placeholder screen.

## Running checks before a PR

```bash
cd app
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

These three run in CI on any PR touching `app/` — see [`../../.github/workflows/app-ci.yml`](../../.github/workflows/app-ci.yml).

## Brand assets

```bash
node scripts/validate-brand-assets.mjs
```

Dependency-free — checks that expected brand documentation, tokens, and export directories exist and are well-formed. Runs in CI on any PR touching `brand/`, `docs/`, or the script itself — see [`../../.github/workflows/validate-brand-assets.yml`](../../.github/workflows/validate-brand-assets.yml).

## Troubleshooting

Nothing project-specific yet — this section will grow as real issues come up. If `flutter doctor` reports a toolchain problem (e.g. missing Android `cmdline-tools`), that's an environment setup issue independent of this repo; follow the guidance it prints.
