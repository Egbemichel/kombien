import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../app/app_state.dart';
import '../components/k_cards.dart';
import '../components/k_controls.dart';
import '../components/k_layout.dart';
import '../data/fare_repository.dart';
import '../data/landmark_repository.dart';
import '../data/report_repository.dart';
import '../design/k_motion.dart';
import '../design/k_text.dart';
import '../design/k_tokens.dart';
import 'route_picker.dart';

/// Report: "I paid this".
///
/// Step 1, the route: the same two fields as the fare lookup, labelled "Where
/// are you/did you leave from?" and "To". Opened from a fare result ("Report
/// it here", "Add report") it skips straight to step 2 on that route.
///
/// Step 2, the form: the route card, price chips suggested from the route's
/// range, "Paid something else?" (grouped as you type), then optional time
/// of day, weather and vehicle. Add report stays grey until the amount is
/// between 50 and 50 000 FCFA in steps of 50; it runs the loading dots while sending and
/// confirms with a toast (or, offline / no backend yet, keeps the report on
/// the phone and says so).
class ReportFareScreen extends StatefulWidget {
  const ReportFareScreen({super.key});

  @override
  State<ReportFareScreen> createState() => _ReportFareScreenState();
}

class _ReportFareScreenState extends State<ReportFareScreen> {
  (Landmark, Landmark)? _route;
  KAppState? _app;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = KAppScope.of(context);
    if (!identical(app, _app)) {
      _app?.reportRoute.removeListener(_handOver);
      _app = app..reportRoute.addListener(_handOver);
      _handOver();
    }
  }

  /// A route handed over from the fare lookup opens the form on it.
  void _handOver() {
    final r = _app?.reportRoute.value;
    if (r == null) return;
    setState(() => _route = r);
    _app!.reportRoute.value = null;
  }

  @override
  void dispose() {
    _app?.reportRoute.removeListener(_handOver);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route = _route;
    return AnimatedSwitcher(
      duration: KMotion.springDuration,
      switchInCurve: KMotion.settleCurve,
      switchOutCurve: KMotion.settleCurve,
      child: route == null
          ? KRoutePicker(
              key: const ValueKey('route'),
              fromLabel: context.l10n.reportFromLabel,
              toTitle: context.l10n.reportTo,
              onRoute: (from, to) {
                if (from != null && to != null) {
                  setState(() => _route = (from, to));
                }
              },
            )
          : _ReportForm(
              key: ValueKey(route),
              from: route.$1,
              to: route.$2,
              onBack: () => setState(() => _route = null),
            ),
    );
  }
}

class _ReportForm extends StatefulWidget {
  const _ReportForm({
    super.key,
    required this.from,
    required this.to,
    required this.onBack,
  });
  final Landmark from, to;
  final VoidCallback onBack;

  @override
  State<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<_ReportForm> {
  final _amount = TextEditingController();
  final _toasts = GlobalKey<KToastHostState>();
  List<int> _suggested = const [];
  int? _chip;
  DayPart? _day;
  bool? _raining;
  Vehicle _vehicle = Vehicle.taxi;
  bool _sending = false;

  /// Sent: the form is finished; it waits for the toast, then resets.
  bool _done = false;

  int? get _xaf => KMoneyFormatter.parse(_amount.text);
  bool get _valid => FareReport.validAmount(_xaf);

  @override
  void initState() {
    super.initState();
    // Price chips: the bottom, middle and top of the route's range.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      FareRange? r;
      try {
        r = await KAppScope.of(context).fares.range(widget.from, widget.to);
      } on FaresOffline catch (e) {
        r = e.saved;
      } catch (_) {}
      if (!mounted || r == null) return;
      int step(num x) => (x / FareReport.stepXaf).round() * FareReport.stepXaf;
      final mid = step((r.low + r.high) / 2);
      setState(() => _suggested = {step(r!.low), mid, step(r.high)}.toList());
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = context.l10n;
    setState(() => _sending = true);
    final sent = await KAppScope.of(context).submitReport(
      FareReport(
        from: widget.from,
        to: widget.to,
        amountXaf: _xaf!,
        dayPart: _day,
        raining: _raining,
        vehicle: _vehicle,
      ),
    );
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = false;
      _done = true;
    });
    // Once the rider has seen the confirmation, send them home (Je paie
    // combien?) and leave the report page ready for the next one.
    final app = KAppScope.of(context);
    await _toasts.currentState?.show(
      t.reportAddedLabel,
      sent ? t.reportAddedTitle : t.reportQueuedTitle,
      sent ? t.reportAddedBody : t.reportQueuedBody,
    );
    app.page.value = 0;
    if (mounted) widget.onBack();
  }

  Widget _optionRow(String label, List<Widget> chips) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: KText.bodySmall.dm(
              fontStyle: FontStyle.italic,
              color: KColors.charcoal,
              fontSize: 13,
            ),
          ),
        ),
        ...chips,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final typed = _amount.text.trim().isNotEmpty;
    final outOfRange = typed && !_valid;
    return KPage(
      header: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: KBackRow(title: t.reportTitle, onBack: widget.onBack),
      ),
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          KToastHost(key: _toasts),
          const SizedBox(height: 12),
          KButton(
            label: t.addReport,
            loading: _sending,
            onPressed: _valid && !_done ? _submit : null,
          ),
        ],
      ),
      children: [
        KRouteCard(from: widget.from.name, to: widget.to.name),
        const SizedBox(height: 18),
        if (_suggested.isNotEmpty) ...[
          Text(
            t.priceSuggestions,
            style: KText.label.dm(
              fontStyle: FontStyle.italic,
              color: KColors.charcoal,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [
              for (final (i, p) in _suggested.indexed)
                KOptionChip(
                  KMoneyFormatter.format('$p'),
                  selected: _chip == i,
                  onTap: () => setState(() {
                    _chip = i;
                    _amount.text = KMoneyFormatter.format('$p');
                  }),
                ),
            ],
          ),
          const SizedBox(height: 18),
        ],
        KEntryField(
          title: t.paidSomethingElse,
          controller: _amount,
          keyboardType: TextInputType.number,
          inputFormatters: const [KMoneyFormatter()],
          onChanged: (_) => setState(() {
            final i = _suggested.indexOf(_xaf ?? -1);
            _chip = i >= 0 ? i : null;
          }),
        ),
        AnimatedSize(
          duration: KMotion.springDuration,
          curve: KMotion.settleCurve,
          alignment: Alignment.topLeft,
          child: outOfRange
              ? Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    t.amountRange,
                    style: KText.label.dm(color: KColors.danger),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 16),
        Text(t.optional, style: KText.label.dm(color: KColors.textMuted)),
        const SizedBox(height: 8),
        _optionRow(t.timeOfDay, [
          for (final (d, label) in [
            (DayPart.morning, t.dayMorning),
            (DayPart.afternoon, t.dayDay),
            (DayPart.night, t.dayNight),
          ])
            KOptionChip(
              label,
              height: 32,
              fontSize: 13,
              selected: _day == d,
              // Optional: tap the chosen one again to clear it.
              onTap: () => setState(() => _day = _day == d ? null : d),
            ),
        ]),
        _optionRow(t.weather, [
          for (final (rain, label) in [
            (false, t.weatherClear),
            (true, t.weatherRainy),
          ])
            KOptionChip(
              label,
              height: 32,
              fontSize: 13,
              selected: _raining == rain,
              onTap: () =>
                  setState(() => _raining = _raining == rain ? null : rain),
            ),
        ]),
        _optionRow(t.vehicleType, [
          for (final (v, icon, label) in [
            (Vehicle.taxi, HugeIcons.strokeRoundedTaxi, t.vehicleTaxi),
            (Vehicle.moto, HugeIcons.strokeRoundedMotorbike02, t.vehicleMoto),
          ])
            Semantics(
              label: label,
              selected: _vehicle == v,
              child: KIconChip(
                icon: icon,
                selected: _vehicle == v,
                onTap: () => setState(() => _vehicle = v),
              ),
            ),
        ]),
      ],
    );
  }
}
