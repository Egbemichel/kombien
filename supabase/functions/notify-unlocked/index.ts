// notify-unlocked: "Your report unlocked fares for Poste -> Eyang."
//
// POST { from_id, to_id }  after a fare report is sent (the app calls it).
//   When that route has 3+ reports in 90 days and was never announced,
//   queues a notification for every rider who reported it (except the
//   caller, who sees it in the app), in their language.
// POST { flush: true }     when the app opens (every 30 min at most), and
//                          after the above.
//   Sends what is due: never 21:00-07:00 Cameroon time, one a day per
//   phone; drops subscriptions the browser says are gone.
//
// Callers need the app's key (Supabase checks the JWT); even so, a call can
// only send what the data already justifies, once.
//
// POST { job: "reminders" }              (scheduled, 08:30 Cameroon time daily)
//   Sends what was held back overnight, then the morning nudge: every phone
//   with the 'reminders' topic that has not had one for 3 days (and none
//   today), never in quiet hours.
// POST { job: "flush" }                  (scheduled, 07:00 Cameroon time daily)
//   Only what was held back overnight (and places added since), the moment
//   quiet hours end. The 08:30 reminders job still does the same first.
// POST { announce: "update", key }       (after a release deploys)
//   "Kombien has been updated", once per key, to phones with the 'updates'
//   topic; held until the morning when it is quiet hours.
//   Both need the x-notify-secret header (NOTIFY_SECRET).
//
// POST { thanks: true }                  (the app, after a 👍 on a fare range)
//   A thank-you to the caller's own phones, at most one a day, never at
//   night. It does not use up the day's notification.
// POST { job: "places" }                 (also part of job "reminders")
//   "<place> is now on Kombien" to the riders who asked for a place that has
//   been added since: they searched for it with notifications on, or used
//   "Tell us about it" (place_requests, answered_place_requests()). One
//   notification per rider and run (several places become one), never in
//   quiet hours, never a second notification the same day.
//
// Secrets: VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY, NOTIFY_SECRET
// (supabase secrets set).
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided by Supabase.

import { createClient } from "npm:@supabase/supabase-js@2";
import webpush from "npm:web-push@3.6.7";

const db = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false } },
);

// Read when first sending, so the function still answers (and queues)
// before the keys are set.
let vapidReady = false;
function vapid(): boolean {
  if (vapidReady) return true;
  const pub = Deno.env.get("VAPID_PUBLIC_KEY");
  const priv = Deno.env.get("VAPID_PRIVATE_KEY");
  if (!pub || !priv) return false;
  webpush.setVapidDetails("https://kombien.egbemichel.tech", pub, priv);
  return (vapidReady = true);
}

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const UUID =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const DAY = 24 * 60 * 60 * 1000;

const text = {
  en: (from: string, to: string) => ({
    title: "Fares unlocked",
    body: `Your report helped show a fare range for ${from} → ${to}.`,
  }),
  fr: (from: string, to: string) => ({
    title: "Tarifs débloqués",
    body: `Votre signalement a permis d'afficher les tarifs pour ${from} → ${to}.`,
  }),
};

const REMINDER_EVERY_HOURS = 66; // "every 3 days", with room for a late run

// A morning nudge, and at this stage it asks for ONE thing: a fare report.
// Reports are what Kombien runs on (a route only shows a range once 3 riders
// reported it), so every reminder asks riders to add what they paid, never
// to look a route up. A reason to help, never a scolding. Rotates every
// 3 days; the same text goes to everyone on the same day. A tap opens the
// report form (REMINDER_URL).
const reminders = {
  en: [
    {
      title: "Paid for a ride lately?",
      body: "Add your fare in a few taps. It helps the next rider.",
    },
    {
      title: "Took a taxi or a moto?",
      body: "Tell Kombien what you paid. Every fare you add helps riders after you.",
    },
    {
      title: "Your fare matters",
      body: "Riders count on fares like yours. Add what you paid in a few taps.",
    },
  ],
  fr: [
    {
      title: "Un trajet récemment ?",
      body: "Ajoute ton tarif en quelques secondes. Ça aide le prochain passager.",
    },
    {
      title: "Tu as pris un taxi ou une moto ?",
      body: "Dis à Kombien ce que tu as payé. Chaque tarif aide les passagers après toi.",
    },
    {
      title: "Ton tarif compte",
      body: "Les passagers comptent sur des tarifs comme le tien. Ajoute ce que tu as payé.",
    },
  ],
};

// Where a tap on a reminder goes: the report page ("?page=1").
const REMINDER_URL = "/?page=1";

const updated = {
  en: {
    title: "Kombien has been updated",
    body: "A new version is ready. Open the app to get it.",
  },
  fr: {
    title: "Kombien a été mis à jour",
    body: "Une nouvelle version est prête. Ouvre l'app pour l'avoir.",
  },
};

const thanks = {
  en: {
    title: "Thank you!",
    body: "Thanks for letting us know the fare range helped.",
  },
  fr: {
    title: "Merci !",
    body: "Merci de nous avoir dit que la fourchette de tarifs t'a aidé.",
  },
};

// "<place> is now on Kombien": a reminder that they looked for it, that it is
// here, and that Kombien keeps growing.
const placeAdded = {
  en: {
    one: (place: string, kind: string) => ({
      title: `${place} is now on Kombien`,
      body: (kind === "suggestion"
        ? "You told us about it. It's on the app now, thank you! "
        : "You searched for it and we hadn't found it yet. It's on the app now. ") +
        "We're working tirelessly to add more places and make Kombien better.",
    }),
    many: (n: number, names: string[]) => ({
      title: `${n} places you asked for are now on Kombien`,
      body: `${names.slice(0, 2).join(", ")}${n > 2 ? " and more" : ""}. ` +
        "We're working tirelessly to add more places and make Kombien better.",
    }),
  },
  fr: {
    one: (place: string, kind: string) => ({
      title: `${place} est maintenant sur Kombien`,
      body: (kind === "suggestion"
        ? "Tu nous en avais parlé. C'est sur l'app maintenant, merci ! "
        : "Tu l'avais cherché et on ne l'avait pas encore. C'est sur l'app maintenant. ") +
        "On travaille sans relâche pour ajouter plus de lieux et améliorer Kombien.",
    }),
    many: (n: number, names: string[]) => ({
      title: `${n} lieux que tu cherchais sont maintenant sur Kombien`,
      body: `${names.slice(0, 2).join(", ")}${n > 2 ? " et d'autres" : ""}. ` +
        "On travaille sans relâche pour ajouter plus de lieux et améliorer Kombien.",
    }),
  },
};

// Cameroon is UTC+1 all year.
const wat = (d: Date) => new Date(d.getTime() + 60 * 60 * 1000);
const watDay = (d: Date) => wat(d).toISOString().slice(0, 10);

/** Now, or 07:00 Cameroon time when it is quiet hours (21:00-07:00). */
function allowedFrom(now: Date): Date {
  const h = wat(now).getUTCHours();
  if (h >= 7 && h < 21) return now;
  const next = new Date(now);
  next.setUTCHours(6, 0, 0, 0); // 07:00 WAT
  if (next <= now) next.setTime(next.getTime() + DAY);
  return next;
}

/** 07:00 Cameroon time tomorrow (the daily limit was reached). */
function tomorrowMorning(now: Date): Date {
  const next = new Date(now);
  next.setUTCHours(6, 0, 0, 0);
  next.setTime(next.getTime() + (next <= now ? DAY : 0));
  return next;
}

/** The scheduler and the deploy prove themselves with a shared secret. */
function trusted(req: Request): boolean {
  const secret = Deno.env.get("NOTIFY_SECRET");
  const given = req.headers.get("x-notify-secret") ?? "";
  if (!secret || secret.length < 20 || given.length !== secret.length) {
    return false;
  }
  let diff = 0; // constant time
  for (let i = 0; i < secret.length; i++) {
    diff |= secret.charCodeAt(i) ^ given.charCodeAt(i);
  }
  return diff === 0;
}

async function caller(req: Request): Promise<string | null> {
  const jwt = req.headers.get("authorization")?.replace(/^Bearer /i, "");
  if (!jwt) return null;
  const { data } = await db.auth.getUser(jwt);
  return data.user?.id ?? null;
}

async function queueUnlock(fromId: string, toId: string, by: string | null) {
  if (!UUID.test(fromId) || !UUID.test(toId)) return 0;
  const since = new Date(Date.now() - 90 * DAY).toISOString();
  const { data: reports } = await db
    .from("fare_reports")
    .select("reported_by")
    .eq("from_landmark_id", fromId)
    .eq("to_landmark_id", toId)
    .gt("created_at", since);
  if (!reports || reports.length < 3) return 0;

  // Once per route: the insert fails if it was announced already.
  const { error } = await db
    .from("route_unlocks")
    .insert({ from_landmark_id: fromId, to_landmark_id: toId });
  if (error) return 0;

  const riders = [...new Set(reports.map((r) => r.reported_by as string))]
    .filter((id) => id !== by);
  if (riders.length === 0) return 0;

  const { data: places } = await db
    .from("landmarks")
    .select("id, name")
    .in("id", [fromId, toId]);
  const name = (id: string) =>
    places?.find((p) => p.id === id)?.name ?? "";

  const { data: subs } = await db
    .from("push_subscriptions")
    .select("id, locale")
    .in("user_id", riders)
    .contains("topics", ["unlocked"]);
  if (!subs || subs.length === 0) return 0;

  const at = allowedFrom(new Date()).toISOString();
  await db.from("push_outbox").insert(
    subs.map((s) => ({
      subscription_id: s.id,
      send_after: at,
      payload: {
        ...(s.locale === "fr" ? text.fr : text.en)(name(fromId), name(toId)),
        tag: `unlocked-${fromId}-${toId}`,
        url: "/",
      },
    })),
  );
  return subs.length;
}

async function flush() {
  const now = new Date();
  if (allowedFrom(now) > now) return 0; // quiet hours
  if (!vapid()) return 0; // keys not set yet: everything waits
  const { data: due } = await db
    .from("push_outbox")
    .select(
      "id, payload, subscription_id, push_subscriptions(endpoint, p256dh, auth, last_sent_at)",
    )
    .is("sent_at", null)
    .lte("send_after", now.toISOString())
    .order("send_after")
    .limit(50);

  let sent = 0;
  const today = watDay(now);
  const sentTo = new Set<string>();
  for (const item of due ?? []) {
    const sub = item.push_subscriptions as unknown as {
      endpoint: string;
      p256dh: string;
      auth: string;
      last_sent_at: string | null;
    } | null;
    if (!sub) continue;
    const last = sub.last_sent_at ? watDay(new Date(sub.last_sent_at)) : "";
    if (last === today || sentTo.has(item.subscription_id)) {
      await db.from("push_outbox")
        .update({ send_after: tomorrowMorning(now).toISOString() })
        .eq("id", item.id);
      continue;
    }
    try {
      await webpush.sendNotification(
        { endpoint: sub.endpoint, keys: { p256dh: sub.p256dh, auth: sub.auth } },
        JSON.stringify(item.payload),
        { TTL: 24 * 60 * 60 },
      );
      sent++;
      sentTo.add(item.subscription_id);
      await db.from("push_outbox").update({ sent_at: now.toISOString() })
        .eq("id", item.id);
      await db.from("push_subscriptions")
        .update({ last_sent_at: now.toISOString() })
        .eq("id", item.subscription_id);
    } catch (e) {
      const status = (e as { statusCode?: number }).statusCode;
      if (status === 404 || status === 410) {
        // The phone unsubscribed or the app was removed.
        await db.from("push_subscriptions").delete()
          .eq("id", item.subscription_id);
      } else {
        // Try again in an hour.
        await db.from("push_outbox")
          .update({ send_after: new Date(now.getTime() + 3600_000).toISOString() })
          .eq("id", item.id);
      }
    }
  }
  // Keep the outbox small.
  await db.from("push_outbox").delete()
    .lt("sent_at", new Date(now.getTime() - 30 * DAY).toISOString());
  return sent;
}

/** The morning nudge, to every phone that is due. Returns how many got it. */
async function sendReminders(): Promise<number> {
  const now = new Date();
  if (allowedFrom(now) > now) return 0; // quiet hours
  if (!vapid()) return 0;
  const due = new Date(now.getTime() - REMINDER_EVERY_HOURS * 3600_000)
    .toISOString();
  const { data: subs } = await db
    .from("push_subscriptions")
    .select("id, endpoint, p256dh, auth, locale, last_sent_at")
    .contains("topics", ["reminders"])
    .lte("last_reminder_at", due)
    .limit(500);
  const today = watDay(now);
  const slot = Math.floor(now.getTime() / DAY / 3);
  let sent = 0;
  for (const s of subs ?? []) {
    if (s.last_sent_at && watDay(new Date(s.last_sent_at)) === today) continue;
    const set = s.locale === "fr" ? reminders.fr : reminders.en;
    const msg = set[slot % set.length];
    try {
      await webpush.sendNotification(
        { endpoint: s.endpoint, keys: { p256dh: s.p256dh, auth: s.auth } },
        JSON.stringify({ ...msg, tag: "reminder", url: REMINDER_URL }),
        { TTL: 6 * 3600 }, // stale by the afternoon
      );
      sent++;
      await db.from("push_subscriptions")
        .update({
          last_reminder_at: now.toISOString(),
          last_sent_at: now.toISOString(),
        })
        .eq("id", s.id);
    } catch (e) {
      const status = (e as { statusCode?: number }).statusCode;
      if (status === 404 || status === 410) {
        await db.from("push_subscriptions").delete().eq("id", s.id);
      }
    }
  }
  return sent;
}

/** "Kombien has been updated", once per [key], to phones that opted in. */
async function announceUpdate(key: string): Promise<number> {
  if (!/^[A-Za-z0-9._-]{1,64}$/.test(key)) return 0;
  // No second announcement within 12 hours, whatever the key.
  const recent = new Date(Date.now() - 12 * 3600_000).toISOString();
  const { count } = await db.from("push_announcements")
    .select("key", { count: "exact", head: true })
    .eq("kind", "update").gt("created_at", recent);
  if ((count ?? 0) > 0) return 0;
  const { error } = await db.from("push_announcements")
    .insert({ kind: "update", key });
  if (error) return 0; // already announced
  const { data: subs } = await db.from("push_subscriptions")
    .select("id, locale").contains("topics", ["updates"]);
  if (!subs || subs.length === 0) return 0;
  const at = allowedFrom(new Date()).toISOString();
  await db.from("push_outbox").insert(subs.map((s) => ({
    subscription_id: s.id,
    send_after: at,
    payload: {
      ...(s.locale === "fr" ? updated.fr : updated.en),
      tag: "update",
      url: "/",
    },
  })));
  return subs.length;
}

/**
 * A test notification to the caller's own phone(s), at once (quiet hours
 * and the daily limit don't apply), at most 3 an hour. Settings: a long
 * press on the version line.
 */
async function sendTest(by: string | null): Promise<string> {
  if (!by) return "not signed in";
  if (!vapid()) return "no keys";
  const { data: subs } = await db
    .from("push_subscriptions")
    .select("id, endpoint, p256dh, auth, locale")
    .eq("user_id", by);
  if (!subs || subs.length === 0) return "no subscription";
  const hourAgo = new Date(Date.now() - 3600_000).toISOString();
  const { count } = await db
    .from("push_outbox")
    .select("id", { count: "exact", head: true })
    .in("subscription_id", subs.map((s) => s.id))
    .eq("payload->>tag", "test")
    .gt("created_at", hourAgo);
  if ((count ?? 0) >= 3) return "limit";
  let sent = 0;
  for (const s of subs) {
    const payload = s.locale === "fr"
      ? {
        title: "Kombien",
        body:
          "Les notifications marchent. Vous saurez quand vos signalements débloquent des tarifs.",
      }
      : {
        title: "Kombien",
        body:
          "Notifications work. You'll hear when your reports unlock fares.",
      };
    const now = new Date().toISOString();
    await db.from("push_outbox").insert({
      subscription_id: s.id,
      payload: { ...payload, tag: "test", url: "/" },
      sent_at: now,
    });
    try {
      await webpush.sendNotification(
        { endpoint: s.endpoint, keys: { p256dh: s.p256dh, auth: s.auth } },
        JSON.stringify({ ...payload, tag: "test", url: "/" }),
        { TTL: 600 },
      );
      sent++;
    } catch (e) {
      const status = (e as { statusCode?: number }).statusCode;
      if (status === 404 || status === 410) {
        await db.from("push_subscriptions").delete().eq("id", s.id);
      }
      return `push service said ${status ?? (e as Error).message}`;
    }
  }
  return sent > 0 ? "sent" : "not sent";
}

/**
 * A thank-you to the caller's own phones after a 👍. At most one a day per
 * rider and never at night; it does not use up the day's notification.
 */
async function sendThanks(by: string | null): Promise<string> {
  if (!by) return "not signed in";
  if (!vapid()) return "no keys";
  const now = new Date();
  if (allowedFrom(now) > now) return "quiet hours";
  const { data: subs } = await db
    .from("push_subscriptions")
    .select("id, endpoint, p256dh, auth, locale")
    .eq("user_id", by);
  if (!subs || subs.length === 0) return "no subscription";
  const dayAgo = new Date(now.getTime() - DAY).toISOString();
  const { count } = await db
    .from("push_outbox")
    .select("id", { count: "exact", head: true })
    .in("subscription_id", subs.map((s) => s.id))
    .eq("payload->>tag", "thanks")
    .gt("created_at", dayAgo);
  if ((count ?? 0) > 0) return "already thanked today";
  let sent = 0;
  for (const s of subs) {
    const msg = s.locale === "fr" ? thanks.fr : thanks.en;
    const payload = { ...msg, tag: "thanks", url: "/" };
    try {
      await webpush.sendNotification(
        { endpoint: s.endpoint, keys: { p256dh: s.p256dh, auth: s.auth } },
        JSON.stringify(payload),
        { TTL: 3600 },
      );
      sent++;
      await db.from("push_outbox").insert({
        subscription_id: s.id,
        payload,
        sent_at: now.toISOString(),
      });
    } catch (e) {
      const status = (e as { statusCode?: number }).statusCode;
      if (status === 404 || status === 410) {
        await db.from("push_subscriptions").delete().eq("id", s.id);
      }
    }
  }
  return sent > 0 ? "sent" : "not sent";
}

type Answered = {
  request_id: string;
  user_id: string;
  kind: string;
  asked: string;
  landmark_id: string;
  place_name: string;
  locale: string;
};

/**
 * "<place> is now on Kombien" for every rider with a request that a place now
 * answers. Returns how many riders were told.
 */
async function notifyPlacesAdded(): Promise<number> {
  const now = new Date();
  // Housekeeping first: searches are only kept 90 days, and what was told is
  // forgotten after 30 (the rider already knows).
  await db.from("place_requests").delete().eq("kind", "search")
    .lt("created_at", new Date(now.getTime() - 90 * DAY).toISOString());
  await db.from("place_requests").delete()
    .not("notified_at", "is", null)
    .lt("notified_at", new Date(now.getTime() - 30 * DAY).toISOString());

  if (allowedFrom(now) > now) return 0; // quiet hours: tomorrow morning
  if (!vapid()) return 0;
  const { data, error } = await db.rpc("answered_place_requests");
  if (error || !data || data.length === 0) return 0;

  const byRider = new Map<string, Answered[]>();
  for (const row of data as Answered[]) {
    byRider.set(row.user_id, [...(byRider.get(row.user_id) ?? []), row]);
  }

  const today = watDay(now);
  let told = 0;
  for (const [riderId, rows] of byRider) {
    const { data: subs } = await db
      .from("push_subscriptions")
      .select("id, endpoint, p256dh, auth, locale, last_sent_at")
      .eq("user_id", riderId)
      .contains("topics", ["places"]);
    if (!subs || subs.length === 0) {
      // Notifications are off: there is nobody to tell. Mark it answered so
      // it is not looked at again.
      await markAnswered(rows, null);
      continue;
    }
    // One notification a day per phone: if every phone had one today, wait.
    const free = subs.filter((s) =>
      !s.last_sent_at || watDay(new Date(s.last_sent_at)) !== today
    );
    if (free.length === 0) continue;

    // One message per rider: several places become one notification.
    const places = [...new Map(rows.map((r) => [r.landmark_id, r])).values()];
    const lang = (rows[0].locale || free[0].locale) === "fr" ? "fr" : "en";
    const msg = places.length === 1
      ? placeAdded[lang].one(places[0].place_name, places[0].kind)
      : placeAdded[lang].many(places.length, places.map((p) => p.place_name));

    let sentAny = false;
    for (const s of free) {
      try {
        await webpush.sendNotification(
          { endpoint: s.endpoint, keys: { p256dh: s.p256dh, auth: s.auth } },
          JSON.stringify({ ...msg, tag: "place-added", url: "/" }),
          { TTL: 24 * 3600 },
        );
        sentAny = true;
        await db.from("push_subscriptions")
          .update({ last_sent_at: now.toISOString() }).eq("id", s.id);
      } catch (e) {
        const status = (e as { statusCode?: number }).statusCode;
        if (status === 404 || status === 410) {
          await db.from("push_subscriptions").delete().eq("id", s.id);
        }
      }
    }
    if (sentAny) {
      told++;
      await markAnswered(rows, now.toISOString());
    } // else: nothing went out; try again at the next run
  }
  return told;
}

/** Marks requests answered (and told, when [toldAt] is set). */
async function markAnswered(rows: Answered[], toldAt: string | null) {
  for (const r of rows) {
    await db.from("place_requests")
      .update({
        status: "added",
        landmark_id: r.landmark_id,
        notified_at: toldAt ?? new Date().toISOString(),
      })
      .eq("id", r.request_id);
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") {
    return new Response("POST only", { status: 405, headers: cors });
  }
  const body = await req.json().catch(() => ({}));
  if (body.test === true) {
    return Response.json({ test: await sendTest(await caller(req)) }, {
      headers: cors,
    });
  }
  if (body.thanks === true) {
    return Response.json({ thanks: await sendThanks(await caller(req)) }, {
      headers: cors,
    });
  }
  if (body.job === "places") {
    if (!trusted(req)) {
      return new Response("not allowed", { status: 403, headers: cors });
    }
    return Response.json({ placesAdded: await notifyPlacesAdded() }, {
      headers: cors,
    });
  }
  if (body.job === "reminders" || body.job === "flush" ||
      body.announce === "update") {
    if (!trusted(req)) {
      return new Response("not allowed", { status: 403, headers: cors });
    }
    if (body.job === "flush") {
      const sent = await flush();
      return Response.json({ sent, placesAdded: await notifyPlacesAdded() }, {
        headers: cors,
      });
    }
    if (body.job === "reminders") {
      // First, whatever was held back overnight (an update announcement, an
      // unlocked-fares notice); then the morning nudge to those still due.
      const sent = await flush();
      const reminded = await sendReminders();
      // Places riders asked for that have been added since the last run.
      const placesAdded = await notifyPlacesAdded();
      return Response.json({ sent, reminded, placesAdded }, {
        headers: cors,
      });
    }
    const announced = await announceUpdate(String(body.key ?? ""));
    return Response.json({ announced, sent: await flush() }, { headers: cors });
  }
  let queued = 0;
  if (typeof body.from_id === "string" && typeof body.to_id === "string") {
    queued = await queueUnlock(body.from_id, body.to_id, await caller(req));
  }
  const sent = await flush();
  return Response.json({ queued, sent }, { headers: cors });
});
