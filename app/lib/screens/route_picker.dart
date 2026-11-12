import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app/app_state.dart';
import '../components/k_add_place_sheet.dart';
import '../components/k_cards.dart';
import '../components/k_controls.dart';
import '../components/k_layout.dart';
import '../components/k_places.dart';
import '../data/google_places.dart';
import '../data/landmark_repository.dart';
import '../data/problem_repository.dart';
import '../design/k_motion.dart';
import '../design/k_text.dart';
import '../design/k_tokens.dart';
import '../services/location_service.dart';

/// Where from, where to: the two fields shared by the fare lookup and the
/// report flow, with everything about finding a place.
///
/// - The start opens on "My location" when location is allowed, or as a
///   landmark search with a red GpsOff (tap to ask again) when it is not.
/// - Either field searches landmarks as you type (a short pause, stale
///   answers dropped); "See all suggestions" lists more. Picking one offers
///   "Save this place".
/// - Nothing found: "Couldn't find that place…". No connection: the
///   offline card, with Retry.
/// - A destination with no start: the start field wiggles, turns red with a
///   message, and takes the cursor; typing there clears it.
/// - Saved places sit at the bottom: a tap fills the field last in use.
///
/// [onRoute] hears the route whenever it changes: both points, or nulls.
class KRoutePicker extends StatefulWidget {
  const KRoutePicker({
    super.key,
    required this.onRoute,
    this.fromLabel,
    this.toTitle,
    this.header,
    this.below,
    this.bottom,
  });

  final void Function(Landmark? from, Landmark? to) onRoute;

  /// Defaults: "Where are you leaving from?" and "Tu go où?".
  final String? fromLabel;
  final String? toTitle;

  /// Under the wordmark (e.g. a back row).
  final Widget? header;

  /// Scrolls under the fields (results).
  final Widget? below;

  /// Pinned at the very bottom, under the saved places (feedback).
  final Widget? bottom;

  @override
  State<KRoutePicker> createState() => _KRoutePickerState();
}

enum _SearchState { idle, noMatch, offline }

class _KRoutePickerState extends State<KRoutePicker> {
  final _from = TextEditingController();
  final _fromFocus = FocusNode();
  final _to = TextEditingController();
  final _toFocus = FocusNode();
  List<Landmark> _fromMatches = const [], _toMatches = const [];
  Landmark? _fromLm, _toLm;
  Timer? _debounce;

  /// Waits a moment after "not found" shows before noting the search, so a
  /// rider still typing counts once, for what they finally typed.
  Timer? _missTimer;
  static const _missSettle = Duration(milliseconds: 2500);
  int _searchRun = 0;

  /// For a place Kombien does not have: after the rider stops typing for a
  /// moment, places other riders already added are looked up, then Google's
  /// suggestions. Waiting keeps the number of asks (and their cost) down.
  Timer? _helpTimer;
  static const _helpSettle = Duration(milliseconds: 600);
  List<PlaceSuggestion> _google = const [];
  bool _googleStart = false;
  bool _addFailed = false;

  /// The last search, for "See all" and Retry.
  String _lastQuery = '';
  bool _lastStart = false;
  bool _expanded = false;
  _SearchState _searchState = _SearchState.idle;
  bool _retrying = false;

  String? _startError;
  int _shake = 0;
  final _toasts = GlobalKey<KToastHostState>();

  /// "Can't find it?": the problem sheet, on "A place is missing", with what
  /// was typed. Thanks the rider after.
  Future<void> _reportMissing(String typed) async {
    final app = KAppScope.of(context);
    final t = context.l10n;
    final report = await showProblemSheet(
      context,
      kind: ProblemKind.placeMissing,
      note: typed.trim(),
    );
    if (report == null || !mounted) return;
    unawaited(app.reportProblem(report));
    _toasts.currentState?.show(
      t.problemThanksLabel,
      t.problemThanksTitle,
      t.problemThanksBody,
    );
  }

  /// The field a saved place fills: the one last in use.
  bool _fillStart = false;

  /// "My location" as a landmark: the known place nearest the rider, so
  /// the route can be looked up and reported. Null until found.
  Landmark? _here;
  bool _locating = false;
  KAppState? _app;

  Future<void> _locate() async {
    final app = _app;
    if (app == null || _locating || !app.locationAccess.value.isGranted) return;
    _locating = true;
    final here = await app.locateHere();
    _locating = false;
    if (!mounted || here == null) return;
    setState(() => _here = here);
    if (_onMyLocation && _toLm != null) _routeChanged(); // look up again
  }

  void _accessChanged() {
    if (_app?.locationAccess.value.isGranted ?? false) {
      unawaited(_locate());
    } else {
      _here = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = KAppScope.of(context);
    if (app == _app) return;
    _app?.locationAccess.removeListener(_accessChanged);
    _app = app..locationAccess.addListener(_accessChanged);
    _accessChanged();
  }

  @override
  void initState() {
    super.initState();
    _fromFocus.addListener(() {
      if (_fromFocus.hasFocus) _fillStart = true;
    });
    _toFocus.addListener(() {
      if (_toFocus.hasFocus) _fillStart = false;
    });
  }

  @override
  void dispose() {
    _app?.locationAccess.removeListener(_accessChanged);
    _debounce?.cancel();
    _missTimer?.cancel();
    _helpTimer?.cancel();
    _from.dispose();
    _fromFocus.dispose();
    _to.dispose();
    _toFocus.dispose();
    super.dispose();
  }

  bool get _onMyLocation =>
      KAppScope.of(context).locationAccess.value.isGranted &&
      _from.text == context.l10n.myLocation;

  Landmark? get _start =>
      _fromLm ??
      (_onMyLocation ? _here ?? Landmark(name: context.l10n.myLocation) : null);

  void _routeChanged() {
    final to = _toLm, from = _start;
    if (to != null && from == null) {
      setState(() {
        _startError = _from.text.trim().isEmpty
            ? context.l10n.startMissing
            : context.l10n.startPickOne;
        _shake++;
      });
      // Next frame: the tap that picked the destination also counts as a
      // tap outside the start field, which would take the focus back.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fromFocus.requestFocus();
      });
    }
    widget.onRoute(to == null ? null : from, from == null ? null : to);
  }

  void _search(String query, {required bool start, bool more = false}) {
    _debounce?.cancel();
    _missTimer?.cancel();
    _helpTimer?.cancel();
    setState(() {
      _google = const [];
      _addFailed = false;
      if (start) {
        _fromLm = null;
        _startError = null; // typing in the start field clears its error
      } else {
        _toLm = null;
      }
      _expanded = more;
      _searchState = _SearchState.idle;
      if (query.trim().isEmpty) {
        start ? _fromMatches = const [] : _toMatches = const [];
      }
    });
    _lastQuery = query;
    _lastStart = start;
    if (query.trim().isEmpty) {
      _routeChanged();
      return;
    }
    widget.onRoute(null, null);
    final run = ++_searchRun;
    _debounce = Timer(Duration(milliseconds: more ? 0 : 180), () async {
      List<Landmark> found;
      var state = _SearchState.idle;
      try {
        found = await KAppScope.of(
          context,
        ).landmarks.search(query, limit: more ? 10 : 3);
        if (found.isEmpty && query.trim().length >= 2) {
          state = _SearchState.noMatch;
        }
      } catch (_) {
        found = const [];
        state = _SearchState.offline;
      }
      if (!mounted || run != _searchRun) return;
      setState(() {
        start ? _fromMatches = found : _toMatches = found;
        _searchState = state;
        _retrying = false;
      });
      if (state == _SearchState.noMatch) {
        final app = KAppScope.of(context);
        _missTimer = Timer(
          _missSettle,
          () => unawaited(app.logSearchMiss(query)),
        );
        _helpTimer = Timer(
          _helpSettle,
          () => unawaited(_helpWithMissing(query, start: start, run: run)),
        );
      }
    });
  }

  /// Places other riders added that match, shown like any other result; else
  /// Google's suggestions, to pick from.
  Future<void> _helpWithMissing(
    String query, {
    required bool start,
    required int run,
  }) async {
    final help = await KAppScope.of(context).helpWithMissingPlace(query);
    if (!mounted || run != _searchRun || help.isEmpty) return;
    setState(() {
      if (help.known.isNotEmpty) {
        start ? _fromMatches = help.known : _toMatches = help.known;
        _searchState = _SearchState.idle;
      } else {
        _google = help.suggestions;
        _googleStart = start;
      }
    });
  }

  /// The rider picked one of Google's suggestions: ask what to call it, save
  /// it as a place they can report against, and use it.
  Future<void> _pickGoogle(PlaceSuggestion s) async {
    final start = _googleStart;
    final label = await showAddPlaceSheet(
      context,
      suggestedName: s.title,
      typed: _lastQuery,
    );
    if (label == null || !mounted) return;
    try {
      final place = await KAppScope.of(context).addGooglePlace(s, label);
      if (!mounted) return;
      setState(() => _google = const []);
      _pick(place, start: start);
    } catch (_) {
      if (mounted) setState(() => _addFailed = true);
    }
  }

  void _pick(Landmark l, {required bool start}) {
    ++_searchRun;
    _debounce?.cancel();
    _missTimer?.cancel();
    _helpTimer?.cancel();
    (start ? _fromFocus : _toFocus).unfocus();
    setState(() {
      _google = const [];
      _addFailed = false;
      _searchState = _SearchState.idle;
      if (start) {
        _from.text = l.name;
        _fromLm = l;
        _fromMatches = const [];
        _startError = null;
      } else {
        _to.text = l.name;
        _toLm = l;
        _toMatches = const [];
      }
    });
    _routeChanged();
  }

  void _useSaved(String name) {
    final place = KAppScope.of(context).savedPlace(name);
    if (place == null) return;
    FocusScope.of(context).unfocus();
    _pick(place, start: _fillStart);
  }

  Widget _suggestions(List<Landmark> found, {required bool start}) =>
      AnimatedSize(
        duration: KMotion.springDuration,
        curve: KMotion.settleCurve,
        alignment: Alignment.topCenter,
        child: found.isEmpty
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: const EdgeInsets.only(top: 12),
                child: KSuggestionsCard(
                  items: [for (final l in found) (l.name, l.distanceLabel)],
                  onSelected: (i) => _pick(found[i], start: start),
                  showSeeAll: !_expanded && found.length >= 3,
                  onSeeAll: () => _search(
                    start ? _from.text : _to.text,
                    start: start,
                    more: true,
                  ),
                ),
              ),
      );

  /// Under the suggestions: not the place you meant?
  Widget _missingLink(List<Landmark> found, {required bool start}) =>
      found.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 10, left: 4),
          child: Semantics(
            button: true,
            child: KSkip(
              context.l10n.placeMissingLink,
              onTap: () => _reportMissing(start ? _from.text : _to.text),
            ),
          ),
        );

  Widget _savePrompt(KAppState app, Landmark? place) => AnimatedSize(
    duration: KMotion.springDuration,
    curve: KMotion.settleCurve,
    alignment: Alignment.topCenter,
    child: place == null
        ? const SizedBox(width: double.infinity)
        : Padding(
            padding: const EdgeInsets.only(top: 6),
            child: ValueListenableBuilder(
              valueListenable: app.places,
              builder: (context, places, _) => KSavePlacePrompt(
                place: place.name,
                savedAs: places.entries
                    .where((e) => e.value == place.name)
                    .map((e) => e.key)
                    .firstOrNull,
                onSave: (name) => app.savePlace(name, place.name, id: place.id),
                onRemove: () => app.removePlace(place.name),
              ),
            ),
          ),
  );

  /// Google's suggestions for a place Kombien does not have, with Google's
  /// attribution. Only the place ID of the one picked is kept.
  Widget _googleSuggestions() {
    final t = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KSurfaceCard(
          radius: 18,
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.googleSuggestionsTitle, style: KText.section),
              for (final s in _google) ...[
                const SizedBox(height: 4),
                // Pointer-down, like the other result rows: one tap even
                // while a field has focus.
                Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (_) => unawaited(_pickGoogle(s)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.title, style: KText.rowName),
                        if (s.subtitle.isNotEmpty)
                          Text(s.subtitle, style: KText.bodySmall),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: KColors.divider),
              ],
              const SizedBox(height: 10),
              const GoogleAttribution(),
            ],
          ),
        ),
        if (_addFailed)
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 4),
            child: Text(
              t.addPlaceFailed,
              style: KText.bodySmall.dm(color: KColors.danger),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 10, left: 4),
          child: Semantics(
            button: true,
            child: KSkip(
              t.placeMissingLink,
              onTap: () => _reportMissing(_lastQuery),
            ),
          ),
        ),
      ],
    );
  }

  /// No match / offline, under the fields.
  Widget _searchCard() {
    final t = context.l10n;
    final Widget card = switch (_searchState) {
      _SearchState.idle => const SizedBox(
        key: ValueKey('idle'),
        width: double.infinity,
      ),
      _SearchState.noMatch when _google.isNotEmpty => Padding(
        key: const ValueKey('googleSuggestions'),
        padding: const EdgeInsets.only(top: 12),
        child: _googleSuggestions(),
      ),
      _SearchState.noMatch => Padding(
        key: const ValueKey('noMatch'),
        padding: const EdgeInsets.only(top: 24),
        child: KPromptCard(
          compact: true,
          stack: const KStickerStack(
            left: 'assets/illustrations/reunification-monument.webp',
            middle: 'assets/illustrations/mountain-landmark.webp',
            right: 'assets/illustrations/magnifying-glass.webp',
          ),
          title: t.noMatchTitle,
          action: t.placeMissingAction,
          onAction: () => _reportMissing(_lastQuery),
        ),
      ),
      _SearchState.offline => Padding(
        key: const ValueKey('offline'),
        padding: const EdgeInsets.only(top: 24),
        child: KPromptCard(
          compact: true,
          stack: const KStickerStack(
            left: 'assets/illustrations/bird-house.webp',
            middle: 'assets/illustrations/empty-drawer.webp',
            right: 'assets/illustrations/no-internet.webp',
          ),
          title: t.offlineNoSaved,
          action: t.retry,
          actionLoading: _retrying,
          onAction: () {
            setState(() => _retrying = true);
            _search(_lastQuery, start: _lastStart, more: true);
          },
        ),
      ),
    };
    return AnimatedSize(
      duration: KMotion.springDuration,
      curve: KMotion.settleCurve,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: KMotion.springDuration,
        switchInCurve: KMotion.springCurve,
        switchOutCurve: Curves.easeIn,
        child: card,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = KAppScope.of(context);
    return KPage(
      header: widget.header,
      overlay: Align(
        alignment: Alignment.centerRight,
        child: KToastHost(key: _toasts),
      ),
      // The faint skyline behind the saved places.
      background: SvgPicture.asset(
        'assets/illustrations/bottom-building.svg',
        fit: BoxFit.fitWidth,
      ),
      footer: [
        ValueListenableBuilder(
          valueListenable: app.places,
          builder: (context, places, _) =>
              KSavedPlacesRow(places: places, onUse: _useSaved),
        ),
        ?widget.bottom,
      ],
      children: [
        const SizedBox(height: 10),
        ValueListenableBuilder<LocationAccess>(
          valueListenable: app.locationAccess,
          builder: (context, access, _) => KLocationField(
            // A new key when access changes rebuilds the field in its mode.
            key: ValueKey(access.isGranted),
            label: widget.fromLabel,
            controller: _from,
            focusNode: _fromFocus,
            hasLocation: access.isGranted,
            locationDenied: !access.isGranted,
            onRequestLocation: app.requestLocation,
            errorText: _startError,
            shakeSignal: _shake,
            onChanged: (q) => _search(q, start: true),
          ),
        ),
        // "My location" is the known place nearest to the rider: say which,
        // so a wrong match is seen (and can be replaced by typing).
        if (_onMyLocation && _here != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              context.l10n.nearPlace(_here!.name),
              style: KText.caption.dm(
                fontStyle: FontStyle.normal,
                fontSize: 12,
                color: KColors.textMuted,
              ),
            ),
          ),
        _suggestions(_fromMatches, start: true),
        _missingLink(_fromMatches, start: true),
        _savePrompt(app, _fromLm),
        const SizedBox(height: 26),
        KEntryField(
          title: widget.toTitle,
          controller: _to,
          focusNode: _toFocus,
          onChanged: (q) => _search(q, start: false),
        ),
        _suggestions(_toMatches, start: false),
        _missingLink(_toMatches, start: false),
        _savePrompt(app, _toLm),
        _searchCard(),
        ?widget.below,
      ],
    );
  }
}
