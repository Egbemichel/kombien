import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/app_state.dart';
import '../app/release.dart';
import '../components/k_animated.dart';
import '../components/k_bits.dart';
import '../components/k_cards.dart';
import '../components/k_controls.dart';
import '../components/k_layout.dart';
import '../design/k_text.dart';
import '../design/k_tokens.dart';
import '../data/report_repository.dart';
import '../services/install.dart';
import '../services/location_service.dart';
import 'my_reports_screen.dart';

/// Settings, from the design: language, location, my city, offline packs,
/// data use, privacy, my reports, about, the developer card and footer.
///
/// Live today: language (app-wide), location on/off, my city, data-use
/// choices, the report count, the info pages and the GitHub / website
/// links. The offline city packs download a placeholder until the backend
/// serves real packs; their states (download → progress ring → saved, with
/// the date; trash to delete) are real and remembered.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const repoUrl = 'https://github.com/Egbemichel/kombien';
  static const websiteUrl = 'https://egbemichel.tech';
  static const osmCopyrightUrl = 'https://www.openstreetmap.org/copyright';

  // The developer's profiles (tracking parameters left off).
  static const githubUrl = 'https://github.com/Egbemichel';
  static const linkedinUrl =
      'https://www.linkedin.com/in/egbe-michel-40863a299';
  static const instagramUrl = 'https://www.instagram.com/egbemichel';
  static const xUrl = 'https://x.com/egbe_michel';

  static const cities = [
    'Yaoundé',
    'Douala',
    'Buea',
    'Bafoussam',
    'Bamenda',
    'Garoua',
    'Kribi',
    'Limbé',
  ];

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

enum _DataUse { any, mobile, wifi }

class _SettingsScreenState extends State<SettingsScreen> {
  static const _listKey = 'offline_list',
      _offlineDataKey = 'offline_data',
      _sendingKey = 'sending_reports';

  SharedPreferences? _prefs;
  final _toasts = GlobalKey<KToastHostState>();
  KAppState? _app;

  /// Cities listed under "Saved fares and map".
  List<String> _listed = const ['Yaoundé', 'Douala', 'Buea'];
  _DataUse _offlineData = _DataUse.any, _sending = _DataUse.any;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      setState(() {
        _prefs = p;
        _listed = p.getStringList(_listKey) ?? _listed;
        _offlineData = _DataUse.values[p.getInt(_offlineDataKey) ?? 0];
        _sending = _DataUse.values[p.getInt(_sendingKey) ?? 0];
      });
    }, onError: (_) {});
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = KAppScope.of(context);
    if (app == _app) return;
    _unlisten();
    _app = app;
    for (final n in [app.myCity, app.packs.saved, app.packs.progress]) {
      n.addListener(_refresh);
    }
  }

  void _unlisten() {
    final app = _app;
    if (app == null) return;
    for (final n in [app.myCity, app.packs.saved, app.packs.progress]) {
      n.removeListener(_refresh);
    }
  }

  @override
  void dispose() {
    _unlisten();
    super.dispose();
  }

  String get _city => _app!.myCity.value;

  /// Saves [city]'s landmarks and fares on the phone; says so if it can't.
  Future<void> _download(String city) async {
    final ok = await _app!.packs.download(city);
    if (!ok && mounted && !_app!.packs.has(city)) {
      final t = context.l10n;
      _toasts.currentState?.show(
        t.packFailedLabel,
        t.packFailedTitle,
        t.packFailedBody,
      );
    }
  }

  void _delete(String city) => _app!.packs.delete(city);

  /// The city chips: a sheet as tall as its content, edge to edge (no
  /// width cap, even on wide screens), current city selected.
  Future<String?> _pickCity({required Iterable<String> from}) =>
      showModalBottomSheet<String>(
        context: context,
        constraints: const BoxConstraints(maxWidth: double.infinity),
        backgroundColor: KColors.background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(KRadius.sheet),
          ),
        ),
        builder: (context) => KSafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.chooseCity, style: KText.title),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in from)
                        KOptionChip(
                          c,
                          italic: false,
                          fontSize: 16,
                          height: 38,
                          selected: c == _city,
                          selectedText: KColors.charcoal,
                          onTap: () => Navigator.of(context).pop(c),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  /// Information as the card + stickers of the empty/edge states.
  Future<void> _info(String title, String body, KStickerStack stack) =>
      showKCardSheet<void>(
        context: context,
        stack: stack,
        title: title,
        body: body,
      );

  void _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  Widget _heading(String text, {Color? color}) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Text(
      text,
      style: KText.section.dm(color: color ?? KColors.charcoal),
    ),
  );

  Widget _sub(String text) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 8),
    child: Text(text, style: KText.settingsRow),
  );

  Widget _row(
    String label, {
    VoidCallback? onTap,
    List<List<dynamic>>? leading,
    Widget? badge,
    bool chevron = true,
    Color? color,
  }) => Semantics(
    button: onTap != null,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: KSettingsRow(
        label,
        leading: leading,
        badge: badge,
        chevron: chevron,
        color: color,
      ),
    ),
  );

  Widget _dataUse(_DataUse value, ValueChanged<_DataUse> onChanged) {
    final t = context.l10n;
    return Row(
      children: [
        for (final (i, (v, label)) in [
          (_DataUse.any, t.wifiAndMobile),
          (_DataUse.mobile, t.mobileOnly),
          (_DataUse.wifi, t.wifiOnly),
        ].indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: KSegmentOption(
              label,
              selected: value == v,
              onTap: () => onChanged(v),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = KAppScope.of(context);
    final t = context.l10n;
    final packs = app.packs;
    final progress = packs.progress.value;
    return KPage(
      overlay: Align(
        alignment: Alignment.centerRight,
        child: KToastHost(key: _toasts),
      ),
      children: [
        Text(t.settingsTitle, style: KText.pageTitle),

        // ---------------------------------------------------- language
        _heading(t.settingsLanguage),
        ValueListenableBuilder<Locale>(
          valueListenable: app.language,
          builder: (context, current, _) => Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              // Each language named in itself, so anyone finds theirs.
              for (final (locale, flag, name) in const [
                (Locale('en'), KFlag.uk, 'English'),
                (Locale('fr'), KFlag.france, 'Français'),
              ])
                KLanguageChip(
                  flag: flag,
                  label: name,
                  selected: current.languageCode == locale.languageCode,
                  onTap: () => app.setLanguage(locale),
                ),
            ],
          ),
        ),

        // ---------------------------------------------------- location
        _heading(t.settingsLocation),
        ValueListenableBuilder<LocationAccess>(
          valueListenable: app.locationAccess,
          builder: (context, access, _) => Wrap(
            spacing: 8,
            children: [
              KOptionChip(
                t.on,
                italic: false,
                height: 34,
                fontSize: 15,
                selectedText: KColors.charcoal,
                selected: access.isGranted,
                onTap: () => app.setLocationEnabled(true),
              ),
              KOptionChip(
                t.off,
                italic: false,
                height: 34,
                fontSize: 15,
                selectedText: KColors.charcoal,
                selected: !access.isGranted,
                onTap: () => app.setLocationEnabled(false),
              ),
            ],
          ),
        ),

        // ---------------------------------------------------- notifications
        if (app.push.supported) ...[
          _heading(t.notifications),
          _sub(t.pushUnlockedRow),
          ValueListenableBuilder<bool>(
            valueListenable: app.pushOn,
            builder: (context, on, _) => Wrap(
              spacing: 8,
              children: [
                KOptionChip(
                  t.on,
                  italic: false,
                  height: 34,
                  fontSize: 15,
                  selectedText: KColors.charcoal,
                  selected: on,
                  onTap: () async {
                    if (on) return;
                    final ok = await app.enablePush();
                    if (!context.mounted) return;
                    if (ok) {
                      _toasts.currentState?.show(
                        t.pushOnLabel,
                        t.pushOnTitle,
                        t.pushOnBody,
                      );
                    } else if (app.push.permission == 'denied') {
                      _toasts.currentState?.show(
                        t.pushBlockedLabel,
                        t.pushBlockedTitle,
                        t.pushBlockedBody,
                      );
                    }
                  },
                ),
                KOptionChip(
                  t.off,
                  italic: false,
                  height: 34,
                  fontSize: 15,
                  selectedText: KColors.charcoal,
                  selected: !on,
                  onTap: () => on ? app.disablePush() : null,
                ),
              ],
            ),
          ),
        ],

        // ---------------------------------------------------- my city
        _heading(t.myCity),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KCityChip(
              _city,
              icon: HugeIcons.strokeRoundedChevronRight,
              iconColor: KColors.charcoal,
              onTap: () async {
                final c = await _pickCity(from: SettingsScreen.cities);
                if (c == null) return;
                setState(() {
                  if (!_listed.contains(c)) _listed = [c, ..._listed];
                });
                _prefs?.setStringList(_listKey, _listed);
                await _app!.setMyCity(c); // its pack follows by itself
              },
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                t.myCityNote,
                style: KText.caption.dm(fontSize: 12, color: KColors.charcoal),
              ),
            ),
          ],
        ),

        // ---------------------------------------------------- offline
        _heading(t.offline),
        _sub(t.savedFaresMap),
        // Shown until the pack for the rider's city is on the phone.
        if (!packs.has(_city) && !progress.containsKey(_city))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: KNotice(
              text: t.noSavedFares(_city),
              icon: HugeIcons.strokeRoundedDownload01,
            ),
          ),
        for (final city in _listed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                KCityChip(
                  city,
                  state: progress.containsKey(city)
                      ? KCityState.downloading
                      : packs.has(city)
                      ? KCityState.saved
                      : KCityState.available,
                  progress: progress[city] ?? 0,
                  onTap: () =>
                      packs.has(city) ? _delete(city) : _download(city),
                ),
                if (packs.saved.value[city]?.savedAt case final at?) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${t.savedOnPhone}\n'
                      '${t.updatedDaysAgo(DateTime.now().difference(at).inDays)}',
                      style: KText.caption.dm(
                        fontStyle: FontStyle.normal,
                        fontSize: 12,
                        color: KColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: Semantics(
            button: true,
            label: t.addCity,
            child: KPressable(
              pressedScale: .85,
              onTap: () async {
                final c = await _pickCity(
                  from: SettingsScreen.cities.where(
                    (c) => !_listed.contains(c),
                  ),
                );
                if (c == null) return;
                setState(() => _listed = [..._listed, c]);
                _prefs?.setStringList(_listKey, _listed);
              },
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedPlusSign,
                  size: 24,
                  color: KColors.charcoal,
                  strokeWidth: 1.5,
                ),
              ),
            ),
          ),
        ),
        _sub(t.offlineData),
        _dataUse(_offlineData, (v) {
          setState(() => _offlineData = v);
          _prefs?.setInt(_offlineDataKey, v.index);
        }),
        _sub(t.sendingReports),
        _dataUse(_sending, (v) {
          setState(() => _sending = v);
          _prefs?.setInt(_sendingKey, v.index);
        }),

        // ---------------------------------------------------- privacy
        _heading(t.privacy),
        _row(
          t.whatKombienStores,
          onTap: () => _info(
            t.whatKombienStores,
            t.whatKombienStoresBody,
            const KStickerStack(
              left: 'assets/illustrations/hand.webp',
              middle: 'assets/illustrations/empty-drawer.webp',
              right: 'assets/illustrations/sticky-note.webp',
            ),
          ),
        ),

        // ---------------------------------------------------- reports
        _heading(t.myReports),
        ValueListenableBuilder<List<StoredReport>>(
          valueListenable: app.reportHistory,
          builder: (context, history, _) => _row(
            t.reportsFromPhone,
            badge: KCountBadge(history.length),
            onTap: () => Navigator.of(context).push(MyReportsScreen.route()),
          ),
        ),
        ValueListenableBuilder<List<StoredReport>>(
          valueListenable: app.reportHistory,
          builder: (context, history, _) {
            final waiting = history.where((r) => !r.sent).length;
            return waiting == 0
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: KNotice(
                      text: t.reportsWaiting(waiting),
                      icon: HugeIcons.strokeRoundedWifiOff01,
                    ),
                  );
          },
        ),

        // ---------------------------------------------------- about
        _heading(t.aboutKombien, color: KColors.mango),
        // Web only: shown while the browser can install the app.
        ValueListenableBuilder<InstallOffer>(
          valueListenable: installOffer,
          builder: (context, offer, _) => offer == InstallOffer.none
              ? const SizedBox.shrink()
              : _row(
                  t.installKombien,
                  leading: HugeIcons.strokeRoundedDownload01,
                  onTap: () async {
                    if (offer == InstallOffer.ios) {
                      await _info(
                        t.installIosTitle,
                        t.installIosBody,
                        const KStickerStack(
                          left: 'assets/illustrations/hand.webp',
                          middle: 'assets/illustrations/bird-house.webp',
                          right: 'assets/illustrations/sticky-note.webp',
                        ),
                      );
                      return;
                    }
                    if (await askToInstall()) {
                      _toasts.currentState?.show(
                        t.installedLabel,
                        t.installedTitle,
                        t.installedBody,
                      );
                    }
                  },
                ),
        ),
        _row(
          t.howFaresWork,
          onTap: () => _info(
            t.howFaresWork,
            t.howFaresWorkBody,
            const KStickerStack(
              left: 'assets/illustrations/chat-bubble.webp',
              middle: 'assets/illustrations/coin-stack.webp',
              right: 'assets/illustrations/tag.webp',
            ),
          ),
        ),
        _row(
          t.contributeGithub,
          leading: HugeIcons.strokeRoundedGithub,
          onTap: () => _open(SettingsScreen.repoUrl),
        ),
        _row(
          t.reportProblem,
          leading: HugeIcons.strokeRoundedAlert02,
          onTap: () async {
            final report = await showProblemSheet(context);
            if (report == null || !context.mounted) return;
            unawaited(KAppScope.of(context).reportProblem(report));
            _toasts.currentState?.show(
              t.problemThanksLabel,
              t.problemThanksTitle,
              t.problemThanksBody,
            );
          },
        ),
        // Long press, with notifications on: a test notification.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: () async {
            if (!app.pushOn.value) return;
            final result = await app.push.sendTest();
            if (!context.mounted) return;
            result == 'sent'
                ? _toasts.currentState?.show(
                    t.pushTestLabel,
                    t.pushTestSentTitle,
                    t.pushTestSentBody,
                  )
                : _toasts.currentState?.show(
                    t.pushTestLabel,
                    t.pushTestFailTitle,
                    result,
                  );
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              t.release(Release.mark, Release.version),
              style: KText.bodySmall.dm(color: KColors.charcoal),
            ),
          ),
        ),
        // Required by the ODbL licence of the landmark data.
        Semantics(
          link: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _open(SettingsScreen.osmCopyrightUrl),
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 18),
              child: Text(
                t.osmCredit,
                style: KText.caption.dm(
                  fontSize: 12,
                  color: KColors.textMuted,
                  decoration: TextDecoration.underline,
                  decorationColor: KColors.textMuted,
                ),
              ),
            ),
          ),
        ),
        KDevCard(
          onWebsite: () => _open(SettingsScreen.websiteUrl),
          onGithub: () => _open(SettingsScreen.githubUrl),
          onLinkedin: () => _open(SettingsScreen.linkedinUrl),
          onInstagram: () => _open(SettingsScreen.instagramUrl),
          onX: () => _open(SettingsScreen.xUrl),
        ),
        const SizedBox(height: 18),
        const KCopyrightFooter(),
      ],
    );
  }
}
