import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../app/app_state.dart';
import '../design/k_motion.dart';
import '../design/k_text.dart';
import '../design/k_tokens.dart';
import 'k_controls.dart';

// Saved places. The flow lives where the rider already is:
// pick a place from the suggestions (start or destination) → tap
// "Save this place" → name it (Home, School, Work, or type a name) → Save.

/// Name suggestions offered when saving a place, in the app language.
List<String> kPlaceNames(BuildContext context) => [
  context.l10n.placeHome,
  context.l10n.placeSchool,
  context.l10n.placeWork,
];

/// Shown under a field once a place is picked from the suggestions.
///
/// Closed: a one-line "Save this place" link (BookmarkAdd02), or "Saved as
/// Work" once saved. Tap opens an inline row under it: name chips, a custom
/// name field, Save. Nothing else on the screen moves.
class KSavePlacePrompt extends StatefulWidget {
  const KSavePlacePrompt({
    super.key,
    required this.place,
    this.savedAs,
    this.onSave,
    this.onRemove,
  });

  /// The landmark just picked.
  final String place;

  /// The name it is already saved under, if any.
  final String? savedAs;
  final ValueChanged<String>? onSave;
  final VoidCallback? onRemove;

  @override
  State<KSavePlacePrompt> createState() => _KSavePlacePromptState();
}

class _KSavePlacePromptState extends State<KSavePlacePrompt> {
  bool _open = false;
  String? _chip;
  final _custom = TextEditingController();
  final _customFocus = FocusNode();

  @override
  void didUpdateWidget(KSavePlacePrompt old) {
    super.didUpdateWidget(old);
    if (old.place != widget.place) _close();
  }

  @override
  void dispose() {
    _custom.dispose();
    _customFocus.dispose();
    super.dispose();
  }

  String get _name =>
      _custom.text.trim().isNotEmpty ? _custom.text.trim() : (_chip ?? '');

  void _toggle() => setState(() {
    _open = !_open;
    if (_open) {
      final saved = widget.savedAs;
      final names = kPlaceNames(context);
      _chip = names.contains(saved) ? saved : null;
      _custom.text = saved != null && !names.contains(saved) ? saved : '';
    }
  });

  void _close() {
    _customFocus.unfocus();
    setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final saved = widget.savedAs;
    final link = KText.label.dm(
      fontSize: 13,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w500,
      color: KColors.mango,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: saved == null
                      ? HugeIcons.strokeRoundedBookmarkAdd02
                      : HugeIcons.strokeRoundedBookmark02,
                  size: 16,
                  color: KColors.mango,
                  strokeWidth: 1.5,
                ),
                const SizedBox(width: 6),
                AnimatedSwitcher(
                  duration: KMotion.springDuration,
                  switchInCurve: KMotion.settleCurve,
                  child: Text(
                    saved == null
                        ? context.l10n.saveThisPlace
                        : context.l10n.savedAs(saved),
                    key: ValueKey(saved),
                    style: link,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: KMotion.springDuration,
          curve: KMotion.settleCurve,
          alignment: Alignment.topCenter,
          child: !_open
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _editor(saved),
                ),
        ),
      ],
    );
  }

  Widget _editor(String? saved) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    decoration: BoxDecoration(
      color: KColors.surface,
      borderRadius: BorderRadius.circular(KRadius.toast),
      border: Border.all(color: KColors.surfaceBorder, width: 1.2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: KText.label.dm(color: KColors.textMuted),
            children: [
              TextSpan(text: context.l10n.nameThePlace),
              TextSpan(
                text: widget.place,
                style: KText.label.dm(
                  color: KColors.charcoal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final n in kPlaceNames(context))
              KOptionChip(
                n,
                height: 32,
                fontSize: 13,
                selected: _chip == n && _custom.text.trim().isEmpty,
                onTap: () => setState(() {
                  _chip = n;
                  _custom.clear();
                  _customFocus.unfocus();
                }),
              ),
            // Custom name: a chip-sized field that reads as a fourth option.
            Container(
              height: 32,
              width: 118,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: KColors.field,
                borderRadius: BorderRadius.circular(KRadius.option),
                border: Border.all(
                  color: _custom.text.trim().isEmpty
                      ? KColors.surfaceBorder
                      : KColors.mango,
                  width: 1.2,
                ),
              ),
              child: TextField(
                controller: _custom,
                focusNode: _customFocus,
                onChanged: (_) => setState(() {}),
                textCapitalization: TextCapitalization.words,
                style: KText.chip.dm(fontSize: 13, color: KColors.charcoal),
                cursorColor: KColors.charcoal,
                cursorHeight: 14,
                decoration: InputDecoration.collapsed(
                  hintText: context.l10n.otherName,
                  hintStyle: KText.chip.dm(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: KColors.placeholder,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: KButton(
                height: 38,
                label: _name.isEmpty
                    ? context.l10n.save
                    : context.l10n.saveAs(_name),
                onPressed: _name.isEmpty
                    ? null
                    : () {
                        widget.onSave?.call(_name);
                        _close();
                      },
              ),
            ),
            const SizedBox(width: 14),
            saved != null && widget.onRemove != null
                ? KSkip(
                    context.l10n.remove,
                    color: KColors.danger,
                    onTap: () {
                      widget.onRemove!();
                      _close();
                    },
                  )
                : KSkip(context.l10n.cancel, onTap: _close),
          ],
        ),
      ],
    ),
  );
}

/// "Your saved destinations": one Saved destination chip per saved place.
/// Tap to use it. Empty: a one-line hint pointing at "Save this place".
class KSavedPlacesRow extends StatelessWidget {
  const KSavedPlacesRow({
    super.key,
    required this.places,
    this.title,
    this.onUse,
  });

  /// Name → landmark, in display order.
  final Map<String, String> places;

  /// Defaults to the app language's "Your saved destinations".
  final String? title;
  final ValueChanged<String>? onUse;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title ?? context.l10n.savedDestinations,
        style: KText.label.dm(
          fontStyle: FontStyle.italic,
          color: KColors.charcoal,
        ),
      ),
      const SizedBox(height: 8),
      if (places.isEmpty)
        Text(
          context.l10n.savedEmptyHint,
          style: KText.label.dm(color: KColors.textSubtle),
        )
      else
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final MapEntry(key: name, value: place) in places.entries)
              Tooltip(
                message: '$name · $place',
                child: KSavedChip(name, onTap: () => onUse?.call(name)),
              ),
          ],
        ),
    ],
  );
}
