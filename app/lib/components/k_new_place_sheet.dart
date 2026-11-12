import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../data/landmark_repository.dart';
import '../data/rider_places.dart';
import '../design/k_text.dart';
import '../design/k_tokens.dart';
import '../services/location_service.dart';
import 'k_cards.dart';
import 'k_controls.dart';
import 'k_layout.dart';

/// Adds a place Kombien doesn't have: what riders call it, and where it is.
///
/// Nothing can prove the rider is at the place, so they say how they know
/// where it is: their phone's position right now (only if it is accurate), a
/// known place it is near, or not at all. The server checks the answer.
/// Returns the place, or null when dismissed.
Future<NewPlace?> showNewPlaceSheet(
  BuildContext context, {
  required String typed,
}) => showModalBottomSheet<NewPlace>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  barrierColor: KColors.charcoal.withValues(alpha: .35),
  builder: (context) => _NewPlaceSheet(typed: typed),
);

enum _How { none, here, near, unknown }

enum _Gps { idle, finding, ok, weak, off }

class _NewPlaceSheet extends StatefulWidget {
  const _NewPlaceSheet({required this.typed});
  final String typed;
  @override
  State<_NewPlaceSheet> createState() => _NewPlaceSheetState();
}

class _NewPlaceSheetState extends State<_NewPlaceSheet> {
  /// The phone is accurate enough to stand behind (the server checks it too).
  static const maxAccuracyM = 100;

  late final _name = TextEditingController(text: widget.typed.trim());
  final _nearQuery = TextEditingController();

  _How _how = _How.none;

  // "I'm here now"
  _Gps _gps = _Gps.idle;
  PositionFix? _fix;

  // "It's near a place I know"
  List<Landmark> _nearMatches = const [];
  Landmark? _anchor;
  int? _metres;
  int _nearRun = 0;

  @override
  void dispose() {
    _name.dispose();
    _nearQuery.dispose();
    super.dispose();
  }

  bool get _nameOk => _name.text.trim().length >= 2;

  bool get _ready =>
      _nameOk &&
      switch (_how) {
        _How.none => false,
        _How.here => _gps == _Gps.ok,
        _How.near => _anchor?.id != null && _metres != null,
        _How.unknown => true,
      };

  Future<void> _findPosition() async {
    final app = KAppScope.of(context);
    setState(() {
      _gps = _Gps.finding;
      _fix = null;
    });
    if (!app.locationAccess.value.isGranted) {
      final access = await app.requestLocation();
      if (!mounted) return;
      if (!access.isGranted) {
        setState(() => _gps = _Gps.off);
        return;
      }
    }
    final fix = await app.location.fix();
    if (!mounted) return;
    setState(() {
      _fix = fix;
      _gps = fix == null
          ? _Gps.off
          : fix.accuracyM <= maxAccuracyM
          ? _Gps.ok
          : _Gps.weak;
    });
  }

  void _choose(_How how) {
    setState(() => _how = how);
    if (how == _How.here && _gps != _Gps.ok && _gps != _Gps.finding) {
      _findPosition();
    }
  }

  Future<void> _searchNear(String query) async {
    final run = ++_nearRun;
    setState(() => _anchor = null);
    if (query.trim().length < 2) {
      setState(() => _nearMatches = const []);
      return;
    }
    List<Landmark> found;
    try {
      found = await KAppScope.of(context).landmarks.search(query, limit: 3);
    } catch (_) {
      found = const [];
    }
    if (!mounted || run != _nearRun) return;
    setState(() => _nearMatches = found);
  }

  NewPlace _result() {
    final label = _name.text.trim();
    return NewPlace(label, switch (_how) {
      _How.here => PlaceWhere.gps(_fix!.lat, _fix!.lng, _fix!.accuracyM.ceil()),
      _How.near => PlaceWhere.near(_anchor!.id!, _metres!),
      _ => const PlaceWhere.unknown(),
    });
  }

  Widget _question(String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(text, style: KText.section),
  );

  Widget _status(String text, {bool bad = false, VoidCallback? retry}) =>
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: KText.bodySmall.dm(color: bad ? KColors.danger : null),
              ),
            ),
            if (retry != null)
              GestureDetector(
                onTap: retry,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    context.l10n.gpsRetry,
                    style: KText.link.dm(fontSize: 14),
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _hereDetails() {
    final t = context.l10n;
    return switch (_gps) {
      _Gps.idle || _Gps.finding => _status(t.gpsFinding),
      _Gps.ok => _status(t.gpsFound(_fix!.accuracyM.ceil())),
      _Gps.weak => _status(
        t.gpsWeak(_fix!.accuracyM.ceil()),
        bad: true,
        retry: _findPosition,
      ),
      _Gps.off => _status(t.gpsOff, bad: true, retry: _findPosition),
    };
  }

  Widget _nearDetails() {
    final t = context.l10n;
    final distances = [(t.nearNext, 50), (t.near200, 200), (t.near500, 500)];
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nearQuery,
            style: KText.body,
            cursorColor: KColors.mango,
            decoration: InputDecoration(
              hintText: t.nearSearchHint,
              hintStyle: KText.body.dm(color: KColors.placeholder),
              isDense: true,
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: KColors.divider),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: KColors.mango, width: 2),
              ),
            ),
            onChanged: _searchNear,
          ),
          if (_nearMatches.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final l in _nearMatches)
                  KOptionChip(
                    l.name,
                    selected: _anchor?.id == l.id,
                    onTap: () => setState(() => _anchor = l),
                  ),
              ],
            ),
          ],
          if (_anchor != null) ...[
            _question(t.nearHowFar),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, m) in distances)
                  KOptionChip(
                    label,
                    selected: _metres == m,
                    onTap: () => setState(() => _metres = m),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      // Rides above the keyboard while typing.
      padding: EdgeInsets.only(bottom: keyboard),
      child: KSafeArea(
        top: false,
        bottom: keyboard == 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: KSpace.page),
          child: KSurfaceCard(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.newPlaceTitle, style: KText.title),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('newPlaceName'),
                    controller: _name,
                    maxLength: 100,
                    textCapitalization: TextCapitalization.words,
                    style: KText.entry,
                    cursorColor: KColors.mango,
                    decoration: InputDecoration(
                      hintText: t.newPlaceNameHint,
                      hintStyle: KText.entryPlaceholder,
                      counterText: '',
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: KColors.divider),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: KColors.mango, width: 2),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  _question(t.newPlaceWhereTitle),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      KOptionChip(
                        t.whereHere,
                        selected: _how == _How.here,
                        onTap: () => _choose(_How.here),
                      ),
                      KOptionChip(
                        t.whereNear,
                        selected: _how == _How.near,
                        onTap: () => _choose(_How.near),
                      ),
                      KOptionChip(
                        t.whereUnknown,
                        selected: _how == _How.unknown,
                        onTap: () => _choose(_How.unknown),
                      ),
                    ],
                  ),
                  if (_how == _How.here) _hereDetails(),
                  if (_how == _How.near) _nearDetails(),
                  if (_how == _How.unknown) _status(t.unknownNote),
                  const SizedBox(height: 18),
                  KButton(
                    label: t.newPlaceAction,
                    onPressed: _ready
                        ? () => Navigator.of(context).pop(_result())
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
