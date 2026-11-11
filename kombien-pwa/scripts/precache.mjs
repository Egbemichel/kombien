// Writes dist/precache.json: every file of the release with a short hash.
//
//   node kombien-pwa/scripts/precache.mjs kombien-pwa/dist
//
// The service worker (web/sw.js) reads it on install to
//   - download what the app needs to open (the "warm" list) in one go, so
//     every later launch is served from the phone, and
//   - carry over files whose hash did not change from the previous release,
//     so an update downloads only what changed.

import { createHash } from "node:crypto";
import { readdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { join, relative, sep } from "node:path";

const dist = process.argv[2];
if (!dist) {
  console.error("usage: node precache.mjs <dist folder>");
  process.exit(1);
}

const skip = (p) =>
  p === "/sw.js" || p === "/precache.json" || p.endsWith(".symbols") ||
  p.endsWith(".map") || p.endsWith(".DS_Store");

// Not needed to open the app: fetched (and kept) only when first used.
const cold = (p) =>
  p.startsWith("/canvaskit/") || // the browser picks one of several engines
  p.endsWith("/NOTICES") ||
  /^\/icons\/.*(512|maskable)/.test(p) ||
  p.startsWith("/privacy-policy/") || p.startsWith("/terms-of-use/") ||
  p === "/legal.css";

const files = {};
const warm = [];
(function walk(dir) {
  for (const name of readdirSync(dir)) {
    const full = join(dir, name);
    if (statSync(full).isDirectory()) {
      walk(full);
      continue;
    }
    const path = "/" + relative(dist, full).split(sep).join("/");
    if (skip(path)) continue;
    files[path] = createHash("sha1").update(readFileSync(full)).digest("hex")
      .slice(0, 12);
    if (!cold(path)) warm.push(path);
  }
})(dist);

// "/" is the page itself.
files["/"] = files["/index.html"];
warm.unshift("/");

writeFileSync(
  join(dist, "precache.json"),
  JSON.stringify({ files, warm }),
);
const kb = warm.reduce((n, p) => n + (p === "/" ? 0 : statSync(join(dist, p)).size), 0) / 1024;
console.log(
  `precache.json: ${Object.keys(files).length} files, ${warm.length} warm (${kb.toFixed(0)} KB)`,
);
