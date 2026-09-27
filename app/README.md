# Kombien — App

The Flutter mobile app. Frontend only for now — no backend exists yet, so search results and fare submissions are placeholder/local behavior (see [Status](#status)).

## Status

**Placeholder screens.** The navigation shell, theme, and core flow (search a route → see reported fares; report a fare you paid) are wired up, but every screen shown is a stand-in. Real screens are being designed one at a time in Figma and will replace these — see [../brand/logo/README.md](../brand/logo/README.md) for how design assets flow into this repo generally.

## Structure

```text
lib/
├── main.dart              — app entry point, MaterialApp, theme wiring
├── theme/
│   ├── kombien_colors.dart          — mirrors brand/tokens/colors.json
│   ├── kombien_typography.dart      — mirrors brand/tokens/typography.json
│   ├── kombien_theme_extension.dart — mono text styles + status colors not covered by ThemeData
│   └── kombien_theme.dart           — light/dark ThemeData built from the above
├── screens/
│   ├── root_shell.dart        — bottom-nav shell (Search / Report tabs)
│   ├── home_screen.dart        — search a route (placeholder)
│   ├── fare_results_screen.dart — reported fares for a route (placeholder)
│   └── report_fare_screen.dart — report what you paid (placeholder)
└── widgets/                    — shared components go here as they emerge
```

## Brand tokens

Colors and typography are ported by hand from [`../brand/tokens/`](../brand/tokens/) into `lib/theme/`. If you change a brand token, update both — there's no codegen linking them yet. Fonts (Space Grotesk, JetBrains Mono) are fetched at runtime via the [`google_fonts`](https://pub.dev/packages/google_fonts) package rather than bundled as asset files, consistent with [`../brand/typography/font-licensing.md`](../brand/typography/font-licensing.md) (link to the official source instead of redistributing binaries).

## Running locally

Requires the Flutter SDK (stable channel) — see [Flutter's install docs](https://docs.flutter.dev/get-started/install) if you don't have it.

```bash
flutter pub get
flutter run
```

## Checks before opening a PR

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

All three run in CI on any PR touching `app/` — see [`../.github/workflows/app-ci.yml`](../.github/workflows/app-ci.yml).

## Replacing a placeholder screen

1. Get the screenshot/Figma frame for the screen being replaced.
2. Rebuild that screen's widget in `lib/screens/`, using the existing theme (`Theme.of(context)`, `KombienThemeExtension`) rather than hard-coded colors/fonts.
3. Keep the navigation wiring in `root_shell.dart` (or add a route) unless the design changes the flow itself — that's a product/navigation decision, call it out separately if so.
4. Update or add widget tests for the new screen's key content.
