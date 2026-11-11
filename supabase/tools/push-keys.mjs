// Creates Kombien's push notification keys (VAPID) and puts them in place.
//
//   node supabase/tools/push-keys.mjs
//
// - The private key goes straight to Supabase's secret store (supabase
//   secrets set), through a temporary file that is deleted at once. It is
//   never printed or saved in the repo.
// - The public key (meant to be public: browsers need it) is written to
//   kombien-pwa/web/push-config.js, which the app reads.
//
// Run it once. Running it again makes new keys: every phone that turned
// notifications on would have to turn them on again.

import { execSync } from "node:child_process";
import { generateKeyPairSync } from "node:crypto";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const project = "nvcoapyzidyvtmlbiwsl";

const { publicKey, privateKey } = generateKeyPairSync("ec", {
  namedCurve: "prime256v1",
});
const pub = publicKey.export({ format: "jwk" });
const priv = privateKey.export({ format: "jwk" });
const b = (s) => Buffer.from(s, "base64url");
const publicRaw = Buffer.concat([Buffer.from([4]), b(pub.x), b(pub.y)])
  .toString("base64url");

const dir = mkdtempSync(join(tmpdir(), "kombien-push-"));
const env = join(dir, "vapid.env");
try {
  writeFileSync(
    env,
    `VAPID_PUBLIC_KEY=${publicRaw}\nVAPID_PRIVATE_KEY=${priv.d}\n`,
    { mode: 0o600 },
  );
  execSync(
    `npx --yes supabase secrets set --env-file "${env}" --project-ref ${project}`,
    { stdio: "inherit", cwd: root },
  );
} finally {
  rmSync(dir, { recursive: true, force: true });
}

writeFileSync(
  join(root, "kombien-pwa", "web", "push-config.js"),
  `// Kombien's public push key (VAPID), made by supabase/tools/push-keys.mjs.
// Public by design: browsers need it to subscribe. The private half is a
// Supabase secret.
window.kombienPushKey = '${publicRaw}';
`,
);
console.log("\nDone. Public key written to kombien-pwa/web/push-config.js");
