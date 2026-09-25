#!/usr/bin/env node
// Validates brand asset file structure and machine-readable token files.
// Does not validate visual quality — that's a human review step.

import { readFileSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, "..");

const REQUIRED_FILES = [
  "brand/README.md",
  "brand/strategy/brand-strategy.md",
  "brand/strategy/audience.md",
  "brand/strategy/positioning.md",
  "brand/strategy/cultural-context.md",
  "brand/strategy/naming.md",
  "brand/voice/voice-and-tone.md",
  "brand/voice/microcopy.md",
  "brand/voice/franglais-guidance.md",
  "brand/voice/do-and-dont.md",
  "brand/logo/README.md",
  "brand/logo/usage-guidelines.md",
  "brand/colors/README.md",
  "brand/colors/palette.md",
  "brand/colors/contrast-checks.md",
  "brand/typography/README.md",
  "brand/typography/font-licensing.md",
  "brand/tokens/README.md",
];

const REQUIRED_JSON = ["brand/tokens/colors.json", "brand/tokens/typography.json"];

const REQUIRED_CSS = ["brand/tokens/colors.css", "brand/tokens/typography.css"];

// Placeholder asset directories that should contain only .gitkeep until
// real, approved exports are added. Flags anything else as a heads-up,
// not necessarily an error — a real asset legitimately landing here is fine.
const PLACEHOLDER_ASSET_DIRS = [
  "brand/logo/source",
  "brand/logo/exports/svg",
  "brand/logo/exports/png",
  "brand/logo/exports/pdf",
];

let failures = 0;
let warnings = 0;

function ok(msg) {
  console.log(`  ✓ ${msg}`);
}

function fail(msg) {
  console.error(`  ✗ ${msg}`);
  failures += 1;
}

function warn(msg) {
  console.warn(`  ! ${msg}`);
  warnings += 1;
}

function checkRequiredFile(relPath) {
  const full = join(ROOT, relPath);
  if (!existsSync(full)) {
    fail(`Missing required file: ${relPath}`);
    return;
  }
  const content = readFileSync(full, "utf8").trim();
  if (content.length === 0) {
    fail(`Required file is empty: ${relPath}`);
    return;
  }
  ok(relPath);
}

function checkJsonFile(relPath) {
  const full = join(ROOT, relPath);
  if (!existsSync(full)) {
    fail(`Missing required token file: ${relPath}`);
    return;
  }
  try {
    JSON.parse(readFileSync(full, "utf8"));
    ok(`${relPath} (valid JSON)`);
  } catch (err) {
    fail(`Invalid JSON in ${relPath}: ${err.message}`);
  }
}

function checkCssFile(relPath) {
  const full = join(ROOT, relPath);
  if (!existsSync(full)) {
    fail(`Missing required token file: ${relPath}`);
    return;
  }
  const content = readFileSync(full, "utf8");
  if (!content.includes(":root")) {
    warn(`${relPath} has no :root block — check it defines custom properties as expected`);
  } else {
    ok(`${relPath} (defines :root)`);
  }
}

function checkPlaceholderDir(relPath) {
  const full = join(ROOT, relPath);
  if (!existsSync(full)) {
    fail(`Missing expected directory: ${relPath}`);
    return;
  }
  ok(`${relPath} exists`);
}

console.log("Checking required brand documentation files...");
for (const f of REQUIRED_FILES) checkRequiredFile(f);

console.log("\nChecking JSON token files...");
for (const f of REQUIRED_JSON) checkJsonFile(f);

console.log("\nChecking CSS token files...");
for (const f of REQUIRED_CSS) checkCssFile(f);

console.log("\nChecking placeholder asset directories...");
for (const d of PLACEHOLDER_ASSET_DIRS) checkPlaceholderDir(d);

console.log(`\n${failures === 0 ? "PASS" : "FAIL"}: ${failures} error(s), ${warnings} warning(s).`);

if (failures > 0) {
  process.exit(1);
}
