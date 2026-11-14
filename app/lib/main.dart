import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app_state.dart';
import 'design/k_motion.dart';
import 'design/k_tokens.dart';
import 'l10n/app_localizations.dart';
import 'screens/location_prompt_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/root_shell.dart';
import 'screens/splash_screen.dart';
import 'services/backend.dart';
import 'theme/kombien_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Connects Supabase when the build was given its URL and key; otherwise
  // the app runs on built-in sample data. It never holds up the first
  // screen: if it has not finished in 3 seconds the app opens anyway and
  // the connection becomes ready when it does (offline-first).
  await Backend.init().timeout(const Duration(seconds: 3), onTimeout: () {});
  runApp(const KombienApp());
}

class KombienApp extends StatefulWidget {
  const KombienApp({super.key, this.showSplash = true, this.state});

  /// Play the splash and the first-run flow (off in tests; skipped by the
  /// ?page= dev link).
  final bool showSplash;

  /// Injected in tests; the app makes its own otherwise.
  final KAppState? state;

  @override
  State<KombienApp> createState() => _KombienAppState();
}

class _KombienAppState extends State<KombienApp> {
  late final KAppState _state = widget.state ?? KAppState();
  late final Future<void> _loaded = _state.load().then((_) {
    // Background sending (on resume, every 2 min while something waits);
    // tests inject their own state and drive it themselves.
    if (widget.state == null) _state.startSync();
  });

  @override
  void initState() {
    super.initState();
    // Start loading at once, whatever the first screen is (the ?page= dev
    // link skips the launch flow, which would otherwise start it).
    if (widget.state == null) unawaited(_loaded);
  }

  @override
  void dispose() {
    if (widget.state == null) _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KAppScope(
    state: _state,
    // The whole app follows the language live: switching it anywhere
    // (onboarding, Settings) rebuilds every screen in place.
    child: ValueListenableBuilder<Locale>(
      valueListenable: _state.language,
      builder: (context, locale, _) => MaterialApp(
        onGenerateTitle: (context) => 'Kombien',
        debugShowCheckedModeBanner: false,
        theme: KombienTheme.light,
        darkTheme: KombienTheme.dark,
        themeMode: ThemeMode.system,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: widget.showSplash && !Uri.base.queryParameters.containsKey('page')
            ? _Launch(loaded: _loaded)
            : const RootShell(),
      ),
    ),
  );
}

/// Splash, then on the first run onboarding and the location prompt, then
/// the app; each hand-over cross-fades on KMotion.settle.
class _Launch extends StatefulWidget {
  const _Launch({required this.loaded});

  /// Saved state finishes loading while the splash plays.
  final Future<void> loaded;

  @override
  State<_Launch> createState() => _LaunchState();
}

enum _Stage { boot, splash, onboarding, location, app }

class _LaunchState extends State<_Launch> {
  static const _onboardedKey = 'onboarded';
  static const _locationAskedKey = 'location_asked';
  _Stage _stage = _Stage.boot;

  @override
  void initState() {
    super.initState();
    _start();
  }

  /// First launches play the splash and the first-run flow; later ones go
  /// straight to the app as soon as it is loaded (the page's own wordmark
  /// covers the engine starting), because riders open Kombien in a hurry.
  Future<void> _start() async {
    final returning =
        await _flag(_onboardedKey) && await _flag(_locationAskedKey);
    if (!mounted) return;
    if (!returning) return setState(() => _stage = _Stage.splash);
    await widget.loaded;
    if (mounted) setState(() => _stage = _Stage.app);
  }

  // Dev aid: ?onboarding replays the first run even after it was finished.
  static final _replay = Uri.base.queryParameters.containsKey('onboarding');

  Future<bool> _flag(String key) async {
    if (_replay) return false;
    try {
      return (await SharedPreferences.getInstance()).getBool(key) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _setFlag(String key) async {
    try {
      await (await SharedPreferences.getInstance()).setBool(key, true);
    } catch (_) {
      // Not remembered this time; that step shows again next launch.
    }
  }

  Future<void> _afterSplash() async {
    await widget.loaded;
    final onboarded = await _flag(_onboardedKey);
    final asked = await _flag(_locationAskedKey);
    if (!mounted) return;
    setState(
      () => _stage = !onboarded
          ? _Stage.onboarding
          : !asked
          ? _Stage.location
          : _Stage.app,
    );
  }

  void _afterOnboarding() {
    _setFlag(_onboardedKey);
    setState(() => _stage = _Stage.location);
  }

  void _afterLocation() {
    _setFlag(_locationAskedKey);
    setState(() => _stage = _Stage.app);
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: KMotion.springDuration,
    switchInCurve: KMotion.settleCurve,
    switchOutCurve: KMotion.settleCurve,
    child: switch (_stage) {
      _Stage.boot => const ColoredBox(
        key: ValueKey(_Stage.boot),
        color: KColors.background,
        child: SizedBox.expand(),
      ),
      _Stage.splash => SplashScreen(
        key: const ValueKey(_Stage.splash),
        onDone: _afterSplash,
      ),
      _Stage.onboarding => OnboardingScreen(
        key: const ValueKey(_Stage.onboarding),
        onDone: _afterOnboarding,
      ),
      _Stage.location => LocationPromptScreen(
        key: const ValueKey(_Stage.location),
        onDone: _afterLocation,
      ),
      _Stage.app => const RootShell(key: ValueKey(_Stage.app)),
    },
  );
}
