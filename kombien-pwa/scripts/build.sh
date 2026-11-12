#!/usr/bin/env bash
# Builds the Kombien PWA into kombien-pwa/dist.
#
#   1. Builds the Flutter app (../app) for the web:
#      - our own service worker (web/sw.js) instead of Flutter's;
#      - the Flutter engine served from this site, not Google's CDN, so the
#        app works offline and doesn't depend on another server to start.
#   2. Lays this folder's web/ files over it: page shell, manifest, icons,
#      service worker, headers, and the Privacy Policy / Terms of Use pages.
#   3. Stamps the release (build time, UTC: yymmdd.HHMM) into the service
#      worker, so phones pick up the update, and into the app (Settings).
#
# Optional, for the real backend (without them the app runs on sample data):
#   SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY
# Optional, for Google place suggestions: GOOGLE_PLACES_KEY
set -euo pipefail
# Git Bash on Windows would rewrite "/" into a Windows path.
export MSYS_NO_PATHCONV=1

PWA="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$(cd "$PWA/.." && pwd)"
APP="$ROOT/app"
OUT="$PWA/dist"
FLUTTER="${FLUTTER:-flutter}"

# Every build is a new release, committed or not.
build="$(date -u +%y%m%d.%H%M)"
# Version from pubspec.yaml (0.1.0+1 -> 0.1.0); the Mark is named in
# app/lib/app/release.dart.
version="$(sed -n 's/^version: *\([^+ ]*\).*/\1/p' "$APP/pubspec.yaml")"
defines=(
  "--dart-define=KOMBIEN_BUILD=$build"
  "--dart-define=KOMBIEN_VERSION=$version"
)
if [[ -n "${SUPABASE_URL:-}" && -n "${SUPABASE_PUBLISHABLE_KEY:-}" ]]; then
  defines+=("--dart-define=SUPABASE_URL=$SUPABASE_URL")
  defines+=("--dart-define=SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY")
  echo "Backend: Supabase"
else
  echo "Backend: none (sample data)"
fi
# Optional: Google place suggestions for places Kombien does not have yet (see
# docs/setup/google-places.md). Without a key the app simply never asks Google.
if [[ -n "${GOOGLE_PLACES_KEY:-}" ]]; then
  defines+=("--dart-define=GOOGLE_PLACES_KEY=$GOOGLE_PLACES_KEY")
  echo "Places: Google suggestions on"
else
  echo "Places: Google suggestions off"
fi

cd "$APP"
"$FLUTTER" pub get
"$FLUTTER" build web --release \
  --base-href / \
  --pwa-strategy=none \
  --no-web-resources-cdn \
  ${defines[@]+"${defines[@]}"}

rm -rf "$OUT"
cp -r "$APP/build/web" "$OUT"
# Replaced by this folder's versions.
rm -rf "$OUT/manifest.json" "$OUT/flutter_service_worker.js" "$OUT/icons" "$OUT/favicon.png"
cp -r "$PWA/web/." "$OUT/"
# Debug symbols: useful for crash traces, never downloaded by phones.
find "$OUT" -name "*.symbols" -delete
# The icon artwork itself (1 MB+): the sized icons in icons/ are what ship.
rm -f "$OUT/kombien-new-app-icon-png.png"

# Old icon addresses still work (a saved copy of an older page, or iOS
# looking in its default places, gets the current icon, never a missing one).
for old in apple-touch-icon.png apple-touch-icon-precomposed.png; do
  cp "$OUT/icons/kombien-apple-180.png" "$OUT/$old"
done
cp "$OUT/icons/kombien-apple-180.png" "$OUT/icons/apple-touch-icon.png"
cp "$OUT/icons/kombien-favicon-32.png" "$OUT/icons/favicon-32.png"
for n in 192 512; do
  cp "$OUT/icons/kombien-$n.png" "$OUT/icons/icon-$n.png"
  cp "$OUT/icons/kombien-maskable-$n.png" "$OUT/icons/icon-maskable-$n.png"
done

# The iPhone Home Screen icon, inside a script the page loads on iPhones.
(cd "$PWA" && node scripts/ios-icon.mjs dist)

sed -i.bak "s/__BUILD__/$build/" "$OUT/sw.js" && rm -f "$OUT/sw.js.bak"
# The release's file list, for the service worker (after everything else).
# (relative paths: Git Bash paths such as /c/Users/... mean nothing to Windows node)
(cd "$PWA" && node scripts/precache.mjs dist)

mark="$(sed -n "s/.*static const mark = '\(.*\)';/\1/p" "$APP/lib/app/release.dart")"
echo "Built $OUT ($mark, version $version, build $build)"
