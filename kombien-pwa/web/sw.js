// Kombien offline support.
//
// Goal: after the first visit, Kombien opens from the phone, at phone
// speed, with or without a connection, and a new release downloads only
// what changed.
//
// - precache.json (made by scripts/precache.mjs at build time) lists every
//   file of the release with a short hash, and which ones the app needs to
//   open ("warm").
// - install: download the warm files into this release's cache. Files whose
//   hash is unchanged since the previous release are copied from its cache
//   instead of downloaded again.
// - Fetching: a file in the cache is served from it, with no network at
//   all (release files never change; a new release is a new cache). Not in
//   the cache: fetched, then kept (the browser's engine files, for one).
// - The page itself is served from the cache too: a new release arrives in
//   the background and shows after the app is restarted ("Update ready").
// - Other sites (the Supabase API) are never touched here.
//
// BUILD is replaced at build time: every release starts a fresh cache and
// drops the old one once it has taken what it can reuse.
const BUILD = '__BUILD__';
const CACHE = `kombien-${BUILD}`;
const LIST = '/precache.json';

// Without these the app cannot open: if one fails, the install fails and
// the previous release keeps running.
const CRITICAL = ['/', '/flutter_bootstrap.js', '/main.dart.js'];

const mine = (key) => key.startsWith('kombien-') && key !== CACHE;

async function readList(cache) {
  try {
    const res = await cache.match(LIST);
    return res ? await res.json() : null;
  } catch (_) {
    return null;
  }
}

async function install() {
  const cache = await caches.open(CACHE);
  const res = await fetch(LIST, { cache: 'no-store' });
  if (!res.ok) throw new Error('no file list');
  const list = await res.clone().json();

  // Earlier releases: what they hold, by hash, for reuse.
  const olds = [];
  for (const key of (await caches.keys()).filter(mine)) {
    const old = await caches.open(key);
    const oldList = await readList(old);
    if (oldList) olds.push({ old, files: oldList.files });
  }
  async function reuse(path) {
    for (const { old, files } of olds) {
      if (files[path] && files[path] === list.files[path]) {
        const hit = await old.match(path);
        if (hit) return hit;
      }
    }
    return null;
  }

  // Everything that is not warm but already held (the engine) is carried
  // over when unchanged; the warm files are carried or downloaded.
  const wanted = new Set(list.warm);
  for (const { files } of olds) {
    for (const path of Object.keys(files)) {
      if (list.files[path] && files[path] === list.files[path]) wanted.add(path);
    }
  }

  const queue = [...wanted];
  let failed = [];
  async function worker() {
    while (queue.length) {
      const path = queue.shift();
      try {
        let hit = await reuse(path);
        if (!hit && !list.warm.includes(path)) continue; // cold: when used
        if (!hit) {
          const r = await fetch(path, { cache: 'reload' });
          if (!r.ok) throw new Error(`${path} ${r.status}`);
          hit = r;
        }
        await cache.put(path, hit);
      } catch (_) {
        failed.push(path);
      }
    }
  }
  await Promise.all(Array.from({ length: 6 }, worker));
  if (CRITICAL.some((p) => failed.includes(p))) {
    await caches.delete(CACHE);
    throw new Error('could not save the app');
  }
  await cache.put(LIST, new Response(JSON.stringify(list), {
    headers: { 'Content-Type': 'application/json' },
  }));
}

self.addEventListener('install', (event) => {
  event.waitUntil(install().then(() => self.skipWaiting()));
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter(mine).map((k) => caches.delete(k))))
      .then(() => self.clients.claim()),
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;
  if (url.pathname === '/sw.js' || url.pathname === LIST ||
      url.pathname.startsWith('/cdn-cgi/')) return;

  event.respondWith(answer(req, url));
});

async function answer(req, url) {
  const navigate = req.mode === 'navigate';
  // The app opens at "/" (with or without ?page=, ?onboarding...).
  const app = navigate && (url.pathname === '/' || url.pathname === '/index.html');
  try {
    const cache = await caches.open(CACHE);
    const hit = app ? await cache.match('/') : await cache.match(req);
    if (hit) return hit;
  } catch (_) {
    // Fall through to the network.
  }
  let res;
  try {
    res = await fetch(req);
  } catch (e) {
    // Offline on a page that was never saved (the legal pages): the app.
    if (navigate) {
      const shell = await caches.match('/');
      if (shell) return shell;
    }
    throw e;
  }
  // Keep what the app used and the release did not list (the engine).
  if (res.ok && res.status === 200 && req.mode !== 'navigate') {
    try {
      const cache = await caches.open(CACHE);
      await cache.put(req, res.clone());
    } catch (_) {}
  }
  return res;
}

// Push notifications ("Your report unlocked fares..."), sent by the
// notify-unlocked function. A tap opens Kombien (or brings it forward).
self.addEventListener('push', (event) => {
  let data = {};
  try {
    data = event.data ? event.data.json() : {};
  } catch (_) {}
  event.waitUntil(
    self.registration.showNotification(data.title || 'Kombien', {
      body: data.body || '',
      icon: '/icons/kombien-192.png',
      badge: '/icons/kombien-badge-96.png',
      tag: data.tag,
      data: { url: data.url || '/' },
    }),
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const url = new URL(
    (event.notification.data && event.notification.data.url) || '/',
    self.location.origin,
  ).href;
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then((windows) => {
        for (const w of windows) {
          if (new URL(w.url).origin === self.location.origin && 'focus' in w) {
            return w.focus();
          }
        }
        return self.clients.openWindow(url);
      }),
  );
});
