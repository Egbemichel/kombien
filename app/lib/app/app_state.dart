import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/city_pack.dart';
import '../data/fare_repository.dart';
import '../data/landmark_repository.dart';
import '../data/problem_repository.dart';
import '../data/report_repository.dart';
import '../l10n/app_localizations.dart';
import '../services/backend.dart';
import 'release.dart';
import '../services/location_service.dart';
import '../services/push.dart';

/// The app's shared, persisted state, kept deliberately small: plain
/// [ValueNotifier]s, saved with shared_preferences, handed down by
/// [KAppScope]. No state-management package until the app needs one.
class KAppState {
  KAppState({
    LocationService? location,
    LandmarkRepository? landmarks,
    FareRepository? fares,
    ReportRepository? reports,
    ProblemRepository? problems,
    CityPacks? packs,
    PushClient? push,
  }) : this._(
         packs ?? CityPacks(),
         push: push,
         location: location,
         landmarks: landmarks,
         fares: fares,
         reports: reports,
         problems: problems,
       );

  KAppState._(
    this.packs, {
    PushClient? push,
    LocationService? location,
    LandmarkRepository? landmarks,
    FareRepository? fares,
    ReportRepository? reports,
    ProblemRepository? problems,
  }) : push = push ?? PushClient.standard(),
       problems = problems ?? ProblemRepository(),
       location = location ?? LocationService(),
       landmarks = landmarks ?? LandmarkRepository.standard(packs),
       fares = fares ?? FareRepository.standard(packs),
       reports = reports ?? ReportRepository.standard();

  /// City packs kept on the phone: offline search, fares, "My location".
  final CityPacks packs;

  static const _languageKey = 'language';
  static const _placesKey = 'saved_places';
  static const _menuKey = 'menu_position';
  static const _locationOffKey = 'location_off';
  static const _placeIdsKey = 'saved_place_ids';

  /// The rider allowed location here before. Browsers (installed web apps
  /// especially) often report "not decided" after a grant, so the app
  /// remembers it itself.
  static const _locationGrantedKey = 'location_granted';
  static const _cityKey = 'my_city';
  static const defaultCity = 'Yaoundé';

  final LocationService location;

  /// Landmark search: Supabase when configured, else the sample list.
  final LandmarkRepository landmarks;

  /// Fare ranges: Supabase when configured, else demo ranges.
  final FareRepository fares;

  /// Fare reports: sent, or kept on the phone until they can be.
  final ReportRepository reports;

  /// "Report a problem" messages: sent, or kept until they can be.
  final ProblemRepository problems;

  Future<void> reportProblem(ProblemReport report) async {
    try {
      await problems.submit(
        report.toJson(
          appVersion: Release.tag,
          locale: language.value.languageCode,
          platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
        ),
      );
    } catch (_) {
      // Never block the rider on this.
    }
  }

  /// Every report made on this phone, newest first (My reports).
  final reportHistory = ValueNotifier<List<StoredReport>>(const []);

  int get reportsWaiting => reportHistory.value.where((r) => !r.sent).length;

  /// Submits [report] and remembers it. True when it reached the server.
  Future<bool> submitReport(FareReport report) async {
    // Was there a range before this report? If not, and there is one
    // after, this rider's report unlocked it (see [unlocked]).
    final from = report.from, to = report.to;
    final watch = online() && from.id != null && to.id != null;
    var hadRange = true;
    if (watch) {
      try {
        hadRange =
            await fares.range(from, to).timeout(const Duration(seconds: 3)) !=
            null;
      } catch (_) {} // unknown: no claim either way
    }
    final stored = await reports.submit(report);
    reportHistory.value = [stored, ...reportHistory.value];
    if (stored.sent) _reported(stored);
    await _forgetTripIf(from, to); // reported: no need to ask on arrival
    if (watch && !hadRange) {
      await _addPendingUnlock(from, to);
      if (stored.sent) await checkUnlocks();
    }
    // A connection is back: anything still waiting goes now too.
    if (stored.sent && reportsWaiting > 0) await sendWaitingReports();
    if (stored.sent) await _offerPush();
    return stored.sent;
  }

  /// A report reached the server: it may have unlocked fares for others.
  void _reported(StoredReport r) {
    final from = r.fromId, to = r.toId;
    if (from != null && to != null) unawaited(push.routeReported(from, to));
  }

  /// Sends reports still waiting for a connection (on start, and whenever
  /// a send succeeds).
  Future<void> sendWaitingReports() async {
    try {
      final waiting = {
        for (final r in reportHistory.value)
          if (!r.sent) r.id,
      };
      reportHistory.value = await reports.sendWaiting();
      for (final r in reportHistory.value) {
        if (r.sent && waiting.contains(r.id)) _reported(r);
      }
    } catch (_) {}
  }

  /// Forgets every report on this phone; sent ones stay in the shared data.
  Future<void> deleteReports() async {
    await reports.deleteAll();
    reportHistory.value = const [];
  }

  /// The app language. Defaults to French on a French phone, else English.
  final language = ValueNotifier<Locale>(_deviceDefault());

  /// Saved places, name → landmark, in the order they were saved.
  final places = ValueNotifier<Map<String, String>>({});

  /// Database ids of saved landmarks (landmark name → id), so a saved
  /// place can be looked up and reported like a searched one.
  Map<String, String> _placeIds = {};

  /// The saved place [name] as a landmark.
  Landmark? savedPlace(String name) {
    final place = places.value[name];
    return place == null ? null : Landmark(id: _placeIds[place], name: place);
  }

  /// Settings → My city: its pack is kept on the phone automatically.
  final myCity = ValueNotifier<String>(defaultCity);

  Future<void> setMyCity(String city) async {
    myCity.value = city;
    await _prefs?.setString(_cityKey, city);
    unawaited(keepCityPack());
  }

  /// Saves (or refreshes, once a week) My city's pack without being asked,
  /// so search and fares keep working when the connection drops.
  Future<void> keepCityPack() async {
    if (!Backend.ready) return; // sample data needs no pack
    // My city first, then the other covered cities (a few hundred KB each):
    // with all of them saved, search never waits on the network.
    final cities = [
      myCity.value,
      ...kCityAreas.keys.where((c) => c != myCity.value),
    ];
    for (final city in cities) {
      if (packs.has(city) && !packs.stale(city)) continue;
      if (!await packs.download(city)) return; // offline: try again later
    }
  }

  /// The landmark the rider is standing at (for "My location"), or null
  /// when location is off, unavailable, or no known place is near.
  Future<Landmark?> locateHere() async {
    final at = await _position();
    if (at == null) return null;
    final (lat, lng) = at;
    final saved = packs.nearest(lat, lng);
    if (saved != null || !Backend.ready) return saved;
    try {
      final rows =
          await Backend.client.rpc(
                'nearest_landmark',
                params: {'lat': lat, 'lng': lng},
              )
              as List<dynamic>;
      if (rows.isEmpty) return null;
      final r = rows.first as Map<String, dynamic>;
      return Landmark(
        id: r['id'] as String,
        name: r['name'] as String,
        distanceM: (r['distance_m'] as num?)?.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  /// "Was this information helpful?" on [range] for [from] → [to].
  Future<void> rateRange(
    Landmark from,
    Landmark to,
    FareRange range,
    bool helpful,
  ) async {
    if (!Backend.ready || range.demo || from.id == null || to.id == null) {
      return;
    }
    try {
      await Backend.ensureSignedIn();
      await Backend.client.from('fare_feedback').insert({
        'from_landmark_id': from.id,
        'to_landmark_id': to.id,
        'helpful': helpful,
        'low_xaf': range.low,
        'high_xaf': range.high,
      });
    } catch (_) {
      // A thumbs is never worth an error.
    }
  }

  // ------------------------------------------------------------ sync

  Timer? _syncTimer;
  AppLifecycleListener? _lifecycle;

  /// Sends what is waiting (reports, problems) without the rider asking:
  /// when the app comes back to the front, and every two minutes while
  /// something is still waiting.
  void startSync() {
    _lifecycle ??= AppLifecycleListener(
      onResume: () {
        unawaited(sync());
        unawaited(lookAround());
      },
    );
    _syncTimer ??= Timer.periodic(const Duration(minutes: 2), (_) {
      if (reportsWaiting > 0) unawaited(sync());
    });
  }

  Future<void> sync() async {
    await sendWaitingReports();
    await problems.sendWaiting().catchError((_) {});
    await keepCityPack();
    await checkUnlocks();
  }

  // ------------------------------------------------------------ nudges
  //
  // What Kombien does without being asked, each behind conditions so it
  // never nags: at most one question a day, and a question turned down
  // twice is never asked again.

  static const _tripKey = 'last_trip',
      _nudgeDayKey = 'nudge_day',
      _arrivalNoKey = 'arrival_declined',
      _pendingUnlockKey = 'pending_unlock',
      _cityDeclinedKey = 'city_declined';

  /// Whether background checks may ask the server (tests switch it on).
  bool Function() online = () => Backend.ready;

  (double, double)? _fix;
  DateTime? _fixAt;

  /// The rider's position, shared by everything that needs it: one fix a
  /// minute at most (each costs battery and a few seconds).
  Future<(double, double)?> _position() async {
    if (!locationAccess.value.isGranted) return null;
    final at = _fixAt;
    if (at != null && DateTime.now().difference(at).inSeconds < 60) {
      return _fix;
    }
    final fix = await location.position();
    if (fix != null) {
      _fix = fix;
      _fixAt = DateTime.now();
    }
    return fix;
  }

  /// Looks around on launch and whenever the app comes back: the city the
  /// rider is in, and whether they just arrived somewhere they looked up.
  Future<void> lookAround() async {
    await detectCity();
    await checkArrival();
  }

  String _today() => DateTime.now().toIso8601String().substring(0, 10);
  bool get _askedToday => _prefs?.getString(_nudgeDayKey) == _today();

  // --- "Arrived? What did you pay?"

  /// Set when the rider is at a destination they looked up in the last two
  /// hours: the app asks what they paid (one tap reports it).
  final arrival = ValueNotifier<Trip?>(null);

  /// Remembers a looked-up route, to ask on arrival. Only routes whose
  /// destination position is known (saved in a city pack).
  Future<void> rememberTrip(
    Landmark from,
    Landmark to,
    FareRange? range,
  ) async {
    final fromId = from.id, toId = to.id;
    final dest = toId == null ? null : packs.place(toId);
    if (fromId == null || toId == null || dest == null || dest.lat == null) {
      return;
    }
    final usable = range != null && !range.demo;
    final trip = Trip(
      from: from.name,
      fromId: fromId,
      to: to.name,
      toId: toId,
      lat: dest.lat!,
      lng: dest.lng!,
      at: DateTime.now(),
      low: usable ? range.low : null,
      high: usable ? range.high : null,
    );
    await _prefs?.setString(_tripKey, jsonEncode(trip.toJson()));
  }

  Future<void> _forgetTripIf(Landmark from, Landmark to) async {
    final raw = _prefs?.getString(_tripKey);
    if (raw == null) return;
    try {
      final t = Trip.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (t.fromId != from.id || t.toId != to.id) return;
    } catch (_) {}
    await _prefs?.remove(_tripKey);
  }

  /// Asks only when: a route was looked up 2 min to 2 h ago, the rider is
  /// within 300 m of its destination, nothing was asked today, and they
  /// have not turned this question down twice.
  Future<void> checkArrival() async {
    final raw = _prefs?.getString(_tripKey);
    if (raw == null || arrival.value != null) return;
    final Trip trip;
    try {
      trip = Trip.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await _prefs?.remove(_tripKey);
      return;
    }
    final age = DateTime.now().difference(trip.at);
    if (age > const Duration(hours: 2)) {
      await _prefs?.remove(_tripKey);
      return;
    }
    if (age < const Duration(minutes: 2)) return; // still setting off
    if ((_prefs?.getInt(_arrivalNoKey) ?? 0) >= 2 || _askedToday) return;
    final at = await _position();
    if (at == null) return;
    if (metresBetween(at.$1, at.$2, trip.lat, trip.lng) > 300) return;
    await _prefs?.setString(_nudgeDayKey, _today());
    arrival.value = trip;
  }

  /// The rider's answer: an amount reports it; null is "Not now".
  Future<void> answerArrival(int? amount) async {
    final trip = arrival.value;
    arrival.value = null;
    await _prefs?.remove(_tripKey);
    if (trip == null) return;
    if (amount == null) {
      final no = (_prefs?.getInt(_arrivalNoKey) ?? 0) + 1;
      await _prefs?.setInt(_arrivalNoKey, no);
      return;
    }
    await submitReport(
      FareReport(
        from: trip.fromLandmark,
        to: trip.toLandmark,
        amountXaf: amount,
      ),
    );
  }

  /// "Another amount": the report form on that route.
  Future<void> reportArrivalElsewhere() async {
    final trip = arrival.value;
    arrival.value = null;
    await _prefs?.remove(_tripKey);
    if (trip != null) reportOn(trip.fromLandmark, trip.toLandmark);
  }

  // --- "Your report unlocked a range"

  /// A route whose first range this rider's report made possible:
  /// (from, to) names, shown once.
  final unlocked = ValueNotifier<(String, String)?>(null);

  Future<void> _addPendingUnlock(Landmark from, Landmark to) async {
    final list = _prefs?.getStringList(_pendingUnlockKey) ?? [];
    final key = '${from.id}|${to.id}';
    if (list.any((e) => e.startsWith('$key|'))) return;
    await _prefs?.setStringList(_pendingUnlockKey, [
      ...list,
      '$key|${from.name}|${to.name}|${DateTime.now().toIso8601String()}',
    ]);
  }

  /// Routes this rider reported before any range existed: has one appeared?
  /// Checks a few at a time; forgets them after 90 days.
  Future<void> checkUnlocks() async {
    if (!online()) return;
    final list = _prefs?.getStringList(_pendingUnlockKey) ?? [];
    if (list.isEmpty) return;
    final keep = <String>[];
    var checked = 0;
    (String, String)? found;
    for (final e in list) {
      final f = e.split('|');
      if (f.length != 5) continue;
      final age = DateTime.now().difference(
        DateTime.tryParse(f[4]) ?? DateTime(2000),
      );
      if (age.inDays > 90) continue;
      if (found != null || checked >= 5) {
        keep.add(e);
        continue;
      }
      checked++;
      try {
        final r = await fares.range(
          Landmark(id: f[0], name: f[2]),
          Landmark(id: f[1], name: f[3]),
        );
        if (r != null && !r.demo) {
          found = (f[2], f[3]);
          continue; // unlocked: no longer pending
        }
      } catch (_) {}
      keep.add(e);
    }
    await _prefs?.setStringList(_pendingUnlockKey, keep);
    if (found != null) unlocked.value = found;
  }

  // --- My city, detected

  /// Set after My city followed the rider to another city: (before, now),
  /// with Undo offered.
  final cityMoved = ValueNotifier<(String, String)?>(null);

  /// My city follows the rider into another covered city (its pack comes
  /// along), unless they undid that for this city before.
  Future<void> detectCity() async {
    final at = await _position();
    if (at == null) return;
    final city = cityAt(at.$1, at.$2);
    if (city == null || city == myCity.value) return;
    if ((_prefs?.getStringList(_cityDeclinedKey) ?? []).contains(city)) return;
    final before = myCity.value;
    await setMyCity(city);
    cityMoved.value = (before, city);
  }

  // --- Notifications ("Your report unlocked fares")

  static const _pushOnKey = 'push_on',
      _pushOffersKey = 'push_offers',
      _pushFlushKey = 'push_flush_at';

  /// Push notifications: the browser and the server.
  final PushClient push;

  /// Notifications are on for this phone.
  final pushOn = ValueNotifier<bool>(false);

  /// Set right after a sent report, when offering notifications makes
  /// sense (the moment their value is obvious).
  final pushOffer = ValueNotifier<bool>(false);

  /// Offered when: this phone can get notifications, they are off and not
  /// blocked, nothing else was asked today, and it was offered fewer than
  /// two times before.
  Future<void> _offerPush() async {
    if (!push.supported || pushOn.value) return;
    if (push.permission == 'denied' || _askedToday) return;
    final offers = _prefs?.getInt(_pushOffersKey) ?? 0;
    if (offers >= 2) return;
    await _prefs?.setInt(_pushOffersKey, offers + 1);
    await _prefs?.setString(_nudgeDayKey, _today());
    pushOffer.value = true;
  }

  /// Turns notifications on (call from a tap: browsers require it).
  Future<bool> enablePush() async {
    pushOffer.value = false;
    final ok = await push.enable(language.value.languageCode);
    pushOn.value = ok;
    await _prefs?.setBool(_pushOnKey, ok);
    return ok;
  }

  Future<void> disablePush() async {
    pushOn.value = false;
    await _prefs?.setBool(_pushOnKey, false);
    await push.disable();
  }

  /// On open: notifications on only if still allowed by the browser, and
  /// held-back notifications sent (every 30 minutes at most).
  Future<void> _loadPush() async {
    pushOn.value =
        (_prefs?.getBool(_pushOnKey) ?? false) &&
        push.supported &&
        push.permission == 'granted';
    if (!online()) return;
    final last = DateTime.tryParse(_prefs?.getString(_pushFlushKey) ?? '');
    if (last != null && DateTime.now().difference(last).inMinutes < 30) return;
    await _prefs?.setString(_pushFlushKey, DateTime.now().toIso8601String());
    unawaited(push.flush());
  }

  /// Undo: back to the earlier city, and never switch to this one again.
  Future<void> undoCityMove() async {
    final moved = cityMoved.value;
    cityMoved.value = null;
    if (moved == null) return;
    await setMyCity(moved.$1);
    await _prefs?.setStringList(_cityDeclinedKey, [
      ...?_prefs?.getStringList(_cityDeclinedKey),
      moved.$2,
    ]);
  }

  /// The page showing in the app: 0 fares, 1 report, 2 settings (and, in
  /// debug builds only, 3 style guide). Dev aid: ?page=N opens page N.
  final page = ValueNotifier<int>(
    (int.tryParse(Uri.base.queryParameters['page'] ?? '') ?? 0).clamp(
      0,
      kDebugMode ? 3 : 2,
    ),
  );

  /// The route to report, handed over from the fare screen.
  final reportRoute = ValueNotifier<(Landmark, Landmark)?>(null);

  /// Opens the report page on [from] → [to].
  void reportOn(Landmark from, Landmark to) {
    reportRoute.value = (from, to);
    page.value = 1;
  }

  /// Where the rider parked the menu button (centre, fraction of height).
  final menuPosition = ValueNotifier<double>(.6);

  /// Whether Kombien may read the phone's location right now.
  final locationAccess = ValueNotifier<LocationAccess>(LocationAccess.unknown);

  SharedPreferences? _prefs;

  static Locale _deviceDefault() {
    final device = PlatformDispatcher.instance.locale.languageCode;
    return Locale(device == 'fr' ? 'fr' : 'en');
  }

  /// Reads what was saved. Safe to call once at start-up; storage failures
  /// leave the defaults in place.
  Future<void> load() async {
    try {
      final p = _prefs = await SharedPreferences.getInstance();
      final code = p.getString(_languageKey);
      if (code != null &&
          AppLocalizations.supportedLocales.any(
            (l) => l.languageCode == code,
          )) {
        language.value = Locale(code);
      }
      menuPosition.value = p.getDouble(_menuKey) ?? menuPosition.value;
      final raw = p.getString(_placesKey);
      if (raw != null) {
        places.value = Map<String, String>.from(jsonDecode(raw) as Map);
      }
      final ids = p.getString(_placeIdsKey);
      if (ids != null) {
        _placeIds = Map<String, String>.from(jsonDecode(ids) as Map);
      }
      myCity.value = p.getString(_cityKey) ?? myCity.value;
    } catch (_) {
      // Keep defaults.
    }
    try {
      reportHistory.value = await reports.history();
    } catch (_) {}
    await packs.load();
    await _loadPush();
    unawaited(sync());
    // The in-app switch (Settings) wins over the phone's permission.
    final off = _prefs?.getBool(_locationOffKey) ?? false;
    final status = off ? LocationAccess.denied : await location.status();
    final grantedBefore = _prefs?.getBool(_locationGrantedKey) ?? false;
    if (!off && !status.isGranted && grantedBefore) {
      // Allowed before but reported otherwise: trust the earlier grant now
      // (no red icon on launch) and confirm it in the background. Asking
      // the browser again is silent while it still holds the permission.
      locationAccess.value = LocationAccess.granted;
      unawaited(_confirmLocation());
    } else {
      locationAccess.value = status;
      if (status.isGranted) await _prefs?.setBool(_locationGrantedKey, true);
    }
    unawaited(lookAround());
  }

  Future<void> _confirmLocation() async {
    final result = await location.request();
    if (result.isGranted) return;
    locationAccess.value = result;
    await _prefs?.setBool(_locationGrantedKey, false);
  }

  Future<void> moveMenu(double fraction) async {
    menuPosition.value = fraction;
    await _prefs?.setDouble(_menuKey, fraction);
  }

  Future<void> setLanguage(Locale locale) async {
    language.value = locale;
    if (pushOn.value) unawaited(push.setLocale(locale.languageCode));
    await _prefs?.setString(_languageKey, locale.languageCode);
  }

  /// Saves [place] under [name]. A place keeps one name: saving it again
  /// under another name moves it.
  Future<void> savePlace(String name, String place, {String? id}) async {
    final next = Map<String, String>.from(places.value)
      ..removeWhere((_, v) => v == place)
      ..[name] = place;
    places.value = next;
    if (id != null) _placeIds = {..._placeIds, place: id};
    await _prefs?.setString(_placesKey, jsonEncode(next));
    await _prefs?.setString(_placeIdsKey, jsonEncode(_placeIds));
  }

  Future<void> removePlace(String place) async {
    final next = Map<String, String>.from(places.value)
      ..removeWhere((_, v) => v == place);
    places.value = next;
    await _prefs?.setString(_placesKey, jsonEncode(next));
  }

  /// Asks for location (or, if the rider blocked it for good, opens the
  /// app's settings) and records the answer.
  Future<LocationAccess> requestLocation() async {
    final result = await location.request();
    locationAccess.value = result;
    await _prefs?.setBool(_locationGrantedKey, result.isGranted);
    return result;
  }

  /// Settings → Location: On asks the phone (or opens its settings); Off
  /// stops Kombien using location even where the phone allows it.
  Future<void> setLocationEnabled(bool on) async {
    await _prefs?.setBool(_locationOffKey, !on);
    if (on) {
      await requestLocation();
    } else {
      locationAccess.value = LocationAccess.denied;
    }
  }

  /// "Skip for now": no prompt, treated as no access.
  void skipLocation() => locationAccess.value = LocationAccess.denied;

  void dispose() {
    _syncTimer?.cancel();
    _lifecycle?.dispose();
    arrival.dispose();
    unlocked.dispose();
    pushOn.dispose();
    pushOffer.dispose();
    cityMoved.dispose();
    myCity.dispose();
    packs.saved.dispose();
    packs.progress.dispose();
    language.dispose();
    places.dispose();
    menuPosition.dispose();
    page.dispose();
    reportHistory.dispose();
    reportRoute.dispose();
    locationAccess.dispose();
  }
}

/// Hands [KAppState] to the widget tree.
class KAppScope extends InheritedWidget {
  const KAppScope({super.key, required this.state, required super.child});
  final KAppState state;

  static KAppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<KAppScope>();
    assert(scope != null, 'No KAppScope above this widget');
    return scope!.state;
  }

  /// Null outside the app (component previews, tests).
  static KAppState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KAppScope>()?.state;

  @override
  bool updateShouldNotify(KAppScope old) => old.state != state;
}

/// Localized strings; English where no app localizations are installed
/// (component tests and previews).
extension KL10n on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      lookupAppLocalizations(const Locale('en'));
}

/// A route the rider looked up, kept to ask "what did you pay?" when they
/// arrive. [low]/[high]: the range shown then (one-tap amounts), if any.
class Trip {
  const Trip({
    required this.from,
    required this.fromId,
    required this.to,
    required this.toId,
    required this.lat,
    required this.lng,
    required this.at,
    this.low,
    this.high,
  });

  final String from, fromId, to, toId;
  final double lat, lng;
  final DateTime at;
  final int? low, high;

  Landmark get fromLandmark => Landmark(id: fromId, name: from);
  Landmark get toLandmark => Landmark(id: toId, name: to);

  /// One-tap answers: the range's low, middle and high, to 50 FCFA.
  List<int> get amounts {
    final l = low, h = high;
    if (l == null || h == null) return const [];
    final mid = ((l + h) / 2 / 50).round() * 50;
    return {l, mid, h}.toList()..sort();
  }

  Map<String, Object?> toJson() => {
    'from': from,
    'from_id': fromId,
    'to': to,
    'to_id': toId,
    'lat': lat,
    'lng': lng,
    'at': at.toIso8601String(),
    'low': low,
    'high': high,
  };

  factory Trip.fromJson(Map<String, dynamic> j) => Trip(
    from: j['from'] as String,
    fromId: j['from_id'] as String,
    to: j['to'] as String,
    toId: j['to_id'] as String,
    lat: (j['lat'] as num).toDouble(),
    lng: (j['lng'] as num).toDouble(),
    at: DateTime.parse(j['at'] as String),
    low: j['low'] as int?,
    high: j['high'] as int?,
  );
}
