import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app/app_state.dart';
import '../components/k_cards.dart';
import '../components/k_layout.dart';
import '../design/k_tokens.dart';

/// After onboarding: the case for turning on location.
///
/// "Get started from where I am" shows the system prompt (the button runs
/// its loading dots while the rider answers); "Skip for now" moves on
/// without asking. Either way the app opens next, in the matching state:
/// "My location" if allowed, the landmark search if not.
class LocationPromptScreen extends StatefulWidget {
  const LocationPromptScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<LocationPromptScreen> createState() => _LocationPromptScreenState();
}

class _LocationPromptScreenState extends State<LocationPromptScreen> {
  bool _asking = false;

  Future<void> _allow() async {
    setState(() => _asking = true);
    await KAppScope.of(context).requestLocation();
    if (mounted) widget.onDone();
  }

  void _skip() {
    KAppScope.of(context).skipLocation();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Scaffold(
      backgroundColor: KColors.background,
      resizeToAvoidBottomInset: false,
      body: KSafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  KSpace.page,
                  44,
                  KSpace.page,
                  24,
                ),
                child: Column(
                  children: [
                    SvgPicture.asset(
                      'assets/brand/kombien-wordmark-light.svg',
                      width: 117,
                      semanticsLabel: 'Kombien',
                    ),
                    SizedBox(height: box.maxHeight > 700 ? 96 : 40),
                    KPromptCard(
                      stack: const KStickerStack(
                        left: 'assets/illustrations/chat-bubble.webp',
                        middle: 'assets/illustrations/coin-stack.webp',
                        right: 'assets/illustrations/clock.webp',
                      ),
                      title: t.locationPromptTitle,
                      body: t.locationPromptBody,
                      action: t.locationPromptAction,
                      actionLoading: _asking,
                      onAction: _allow,
                      skip: t.locationPromptSkip,
                      onSkip: _asking ? null : _skip,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
