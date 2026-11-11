#!/usr/bin/env bash
# Puts the page where it is served from: egbemichel.tech/kombien/.
# Every URL in web/ already starts with /kombien/, so the folder layout
# inside dist/ has to match.
set -euo pipefail
cd "$(dirname "$0")/.."
rm -rf dist
mkdir -p dist/kombien
cp -r web/. dist/kombien/
echo "built dist/kombien ($(find dist -type f | wc -l) files)"
