// Writes dist/ios-icon.js: the iPhone Home Screen icon as a data address,
// set on the page's apple-touch-icon link (index.html loads it on iPhones
// only). "Add to Home Screen" then has nothing to download.
//
//   node scripts/ios-icon.mjs dist
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const dist = process.argv[2];
const png = readFileSync(join(dist, "icons", "kombien-home-180.png"));
writeFileSync(
  join(dist, "ios-icon.js"),
  `var l = document.querySelector('link[rel="apple-touch-icon"]');\n` +
    `if (l) l.href = 'data:image/png;base64,${png.toString("base64")}';\n`,
);
console.log(`ios-icon.js: ${(png.length / 1024).toFixed(0)} KB icon embedded`);
