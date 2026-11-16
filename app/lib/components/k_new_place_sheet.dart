import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../data/rider_places.dart';
import '../design/k_text.dart';
import '../design/k_tokens.dart';
import '../services/location_service.dart';
import 'k_cards.dart';
import 'k_controls.dart';
import 'k_layout.dart';

/// "Tell us about it": a place Kombien does not have.
///
/// The rider names it and says whether they are there now:
///
/// - **I'm here now** (location on): their phone's position is used, and the
///   place is added at once where they stand. Only if the position is accurate
///   (the server checks it too).
/// - **I'm not there**: nothing is added now. What they typed, and where they
///   say it is, is saved for the people who maintain the place list, who look
///   it up and add it. The rider is told when it is on Kombien.
///
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

enum _How { none, here, notThere }

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
  final _note = TextEditingController();

  _How _how = _How.none;

  // "I'm here now"
  _Gps _gps = _Gps.idle;
  PositionFix? _fix;

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  bool get _nameOk => _name.text.trim().length >= 3;

  bool get _ready =>
      _nameOk &&
      switch (_how) {
        _How.none => false,
        _How.here => _gps == _Gps.ok,
        _How.notThere => true,
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

  NewPlace _result() {
    final label = _name.text.trim();
    return NewPlace(label, switch (_how) {
      _How.here => PlaceWhere.gps(_fix!.lat, _fix!.lng, _fix!.accuracyM.ceil()),
      _ => PlaceWhere.review(_note.text.trim()),
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
      _Gps.off => _status(t.gpsOffHere, bad: true, retry: _findPosition),
    };
  }

  Widget _notThereDetails() {
    final t = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const ValueKey('newPlaceNote'),
            controller: _note,
            maxLength: 120,
            textCapitalization: TextCapitalization.sentences,
            style: KText.body,
            cursorColor: KColors.mango,
            decoration: InputDecoration(
              hintText: t.notThereHint,
              hintStyle: KText.body.dm(color: KColors.placeholder),
              isDense: true,
              counterText: '',
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: KColors.divider),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: KColors.mango, width: 2),
              ),
            ),
          ),
          _status(t.notThereNote),
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
                  Text(t.tellUsTitle, style: KText.title),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('newPlaceName'),
                    controller: _name,
                    maxLength: 80,
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
                  _question(t.areYouThere),
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
                        t.whereNotThere,
                        selected: _how == _How.notThere,
                        onTap: () => _choose(_How.notThere),
                      ),
                    ],
                  ),
                  if (_how == _How.here) _hereDetails(),
                  if (_how == _How.notThere) _notThereDetails(),
                  const SizedBox(height: 18),
                  KButton(
                    label: _how == _How.notThere ? t.send : t.newPlaceAction,
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
