// Does Kombien open with no connection, and on a weak one?
//
//   node scripts/start-check.mjs dist
//
// Serves a build folder itself (so "offline" means the server really is
// gone, for the page and the service worker alike) and drives a real Chrome
// over its remote-control protocol:
//   1. first visit, online                      must open
//   2. offline right after (the server is gone) must open, from the phone
//   3. weak network: requests to the font CDN and Supabase never answer
//                                               must open anyway
// The browser's own HTTP cache is switched off, so only what Kombien itself
// saved (the service worker's cache) can make step 2 work.
//
// Needs Chrome (CHROME env var, or the usual install path) and Node 22+.
// Exits 1 when any step gets stuck on the pulsing wordmark.
import { spawn } from "node:child_process";
import { createServer } from "node:http";
import { mkdtempSync, readFileSync, rmSync, existsSync, statSync } from "node:fs";
import { tmpdir } from "node:os";
import { extname, join, normalize } from "node:path";

const dist = process.argv[2];
const CHROME = process.env.CHROME ||
  (process.platform === "win32" ? "C:/Program Files/Google/Chrome/Application/chrome.exe"
    : process.platform === "darwin" ? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    : "google-chrome");
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// ---------------------------------------------------------------- server
const types = { ".html": "text/html", ".js": "text/javascript", ".mjs": "text/javascript", ".json": "application/json", ".wasm": "application/wasm", ".webmanifest": "application/manifest+json", ".png": "image/png", ".webp": "image/webp", ".jpg": "image/jpeg", ".svg": "image/svg+xml", ".ttf": "font/ttf", ".otf": "font/otf", ".woff2": "font/woff2", ".css": "text/css" };
const sitePort = 8900 + Math.floor(Math.random() * 90);
let server;
function startServer() {
  return new Promise((resolve) => {
    server = createServer((req, res) => {
      let p = decodeURIComponent(new URL(req.url, "http://x").pathname);
      let f = normalize(join(dist, p));
      if (existsSync(f) && statSync(f).isDirectory()) f = join(f, "index.html");
      if (!existsSync(f)) f = join(dist, "index.html"); // single-page fallback
      res.writeHead(200, { "Content-Type": types[extname(f)] || "application/octet-stream", "Cache-Control": "no-cache" });
      res.end(readFileSync(f));
    });
    server.listen(sitePort, "127.0.0.1", resolve);
  });
}
const stopServer = () => new Promise((resolve) => { server.closeAllConnections(); server.close(resolve); });
await startServer();
const url = `http://127.0.0.1:${sitePort}/`;

// ---------------------------------------------------------------- chrome
const port = 9300 + Math.floor(Math.random() * 500);
const profile = mkdtempSync(join(tmpdir(), "kombien-cdp-"));
const chrome = spawn(CHROME, [
  "--headless=new", `--remote-debugging-port=${port}`, `--user-data-dir=${profile}`,
  "--no-first-run", "--no-default-browser-check", "--window-size=390,844",
  "--enable-unsafe-swiftshader", "--use-angle=swiftshader", "--no-sandbox", "about:blank",
], { stdio: "ignore" });
async function connect() {
  for (let i = 0; i < 60; i++) {
    try {
      const list = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
      const page = list.find((t) => t.type === "page");
      if (page) return page.webSocketDebuggerUrl;
    } catch (_) {}
    await sleep(500);
  }
  throw new Error("chrome did not start");
}
const ws = new WebSocket(await connect());
await new Promise((r) => (ws.onopen = r));
let id = 0;
const waiting = new Map();
const hung = [];
ws.onmessage = (m) => {
  const msg = JSON.parse(m.data);
  if (msg.id && waiting.has(msg.id)) { waiting.get(msg.id)(msg); waiting.delete(msg.id); }
  else if (msg.method === "Fetch.requestPaused") hung.push(msg.params.request.url); // never answered: a stalled request
};
const send = (method, params = {}) => new Promise((res) => { const n = ++id; waiting.set(n, res); ws.send(JSON.stringify({ id: n, method, params })); });
const evalJS = async (expression) => {
  const r = await send("Runtime.evaluate", { expression, awaitPromise: true, returnByValue: true });
  return r.result && r.result.result ? r.result.result.value : undefined;
};
await send("Page.enable");
await send("Network.enable");
await send("Runtime.enable");
await send("Network.setCacheDisabled", { cacheDisabled: true }); // only what Kombien itself saved counts

async function launch(label, timeoutMs) {
  hung.length = 0;
  const before = await evalJS("performance.timeOrigin").catch(() => 0);
  const t0 = Date.now();
  await send("Page.navigate", { url });
  let ok = false, last;
  while (Date.now() - t0 < timeoutMs) {
    await sleep(400);
    last = await evalJS("(()=>({origin: performance.timeOrigin, frame: performance.getEntriesByName('kombien-first-frame').length>0, title: document.title, text: document.body ? document.body.innerText.slice(0,80) : ''}))()").catch(() => undefined);
    if (last && last.origin !== before && last.frame) { ok = true; break; }
  }
  const ms = Date.now() - t0;
  console.log(`${label.padEnd(50)} ${ok ? "OPENED in " + ms + " ms" : "STUCK after " + ms + " ms"}`);
  if (!ok && last) console.log(`   page says: ${JSON.stringify(last.text)}`);
  if (hung.length) console.log(`   stalled requests: ${[...new Set(hung)].join(" , ")}`);
  return ok;
}
async function saved() {
  return evalJS(`(async()=>{
    const keys = await caches.keys(); const out = {};
    for (const k of keys) { const c = await caches.open(k); const r = await c.keys(); out[k] = {files: r.length, engine: r.filter(x=>x.url.includes('/canvaskit/')).map(x=>new URL(x.url).pathname.replace('/canvaskit/',''))}; }
    const regs = await navigator.serviceWorker.getRegistrations();
    return JSON.stringify({worker: regs.map(r=>r.active&&r.active.state), caches: out});
  })()`);
}

const results = {};
console.log(`build: ${dist}\n`);
await launch("1. first visit, online", 120000);
// The rider closes the app as soon as the first screen shows: wait only until
// the worker is active (not for it to finish saving).
for (let i = 0; i < 60; i++) {
  const s = JSON.parse((await saved().catch(() => "{}")) || "{}");
  if (s.worker && s.worker[0] === "activated") break;
  await sleep(1000);
}
console.log("   saved at that point:", await saved());
// Give the worker the time a rider's phone would have (it keeps working in
// the background after the app is closed).
await sleep(Number(process.env.SETTLE_MS || 20000));
console.log("   saved after settling:", await saved());

await stopServer();
results.offline = await launch("2. OFFLINE (server gone)", 25000);
await startServer();

await send("Fetch.enable", { patterns: [{ urlPattern: "*fonts.gstatic.com*" }, { urlPattern: "*supabase.co*" }] });
results.stalled = await launch("3. weak network: font CDN + Supabase stall", 25000);
await send("Fetch.disable");

console.log(`\nSUMMARY offline=${results.offline ? "OK" : "STUCK"}  weak-network=${results.stalled ? "OK" : "STUCK"}`);
ws.close(); chrome.kill(); await stopServer().catch(() => {});
await sleep(500);
try { rmSync(profile, { recursive: true, force: true }); } catch (_) {}
process.exit(results.offline && results.stalled ? 0 : 1);
