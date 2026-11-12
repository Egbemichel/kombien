import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../design/k_text.dart';
import '../design/k_tokens.dart';
import 'k_cards.dart';
import 'k_controls.dart';
import 'k_layout.dart';

/// Asks what to call a place the rider picked from Google's suggestions.
///
/// Google's name is shown for reference only (with its attribution): what is
/// saved is the rider's own words, which start as what they typed in the
/// search. Returns the name, or null when dismissed.
Future<String?> showAddPlaceSheet(
  BuildContext context, {
  required String suggestedName,
  required String typed,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  barrierColor: KColors.charcoal.withValues(alpha: .35),
  builder: (context) =>
      _AddPlaceSheet(suggestedName: suggestedName, typed: typed),
);

class _AddPlaceSheet extends StatefulWidget {
  const _AddPlaceSheet({required this.suggestedName, required this.typed});
  final String suggestedName;
  final String typed;
  @override
  State<_AddPlaceSheet> createState() => _AddPlaceSheetState();
}

class _AddPlaceSheetState extends State<_AddPlaceSheet> {
  late final _name = TextEditingController(text: widget.typed.trim());

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _valid => _name.text.trim().length >= 2;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      // Rides above the keyboard while typing the name.
      padding: EdgeInsets.only(bottom: keyboard),
      child: KSafeArea(
        top: false,
        bottom: keyboard == 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: KSpace.page),
          child: KSurfaceCard(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.addPlaceTitle, style: KText.title),
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  autofocus: true,
                  maxLength: 100,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  style: KText.entry,
                  cursorColor: KColors.mango,
                  decoration: InputDecoration(
                    hintText: t.addPlaceHint,
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
                  onSubmitted: (_) {
                    if (_valid) Navigator.of(context).pop(_name.text.trim());
                  },
                ),
                const SizedBox(height: 10),
                // Google's text, shown only here for the rider to check the
                // place, with the required attribution. Never saved.
                Text(
                  t.addPlaceSuggested(widget.suggestedName),
                  style: KText.bodySmall,
                ),
                const SizedBox(height: 2),
                const _GoogleAttribution(),
                const SizedBox(height: 16),
                KButton(
                  label: t.addPlaceAction,
                  onPressed: _valid
                      ? () => Navigator.of(context).pop(_name.text.trim())
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Google's required credit where its suggestions are shown: the text form
/// ("Google Maps", not translated, Roboto, 12 sp or more, grey on a plain
/// background) used where there is no room for the logo.
class GoogleAttribution extends StatelessWidget {
  const GoogleAttribution({super.key});
  @override
  Widget build(BuildContext context) => const _GoogleAttribution();
}

class _GoogleAttribution extends StatelessWidget {
  const _GoogleAttribution();
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Google Maps',
    child: const Text(
      'Google Maps',
      textAlign: TextAlign.left,
      softWrap: false,
      style: TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.normal,
        fontSize: 12,
        color: Color(0xFF5E5E5E),
      ),
    ),
  );
}
