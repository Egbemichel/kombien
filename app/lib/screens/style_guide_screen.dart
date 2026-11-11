import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';

import '../app/app_state.dart';
import '../components/k_bits.dart';
import '../components/k_cards.dart';
import '../components/k_controls.dart';
import '../components/k_floating_menu.dart';
import '../components/k_places.dart';
import '../design/k_motion.dart';
import '../design/k_text.dart';
import '../design/k_tokens.dart';

/// Temporary screen: every component from the design screenshots, rebuilt and
/// shown together so the look can be checked before screens are built.
class StyleGuideScreen extends StatelessWidget {
  const StyleGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: KColors.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 402),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              KSpace.page,
              24,
              KSpace.page,
              48,
            ),
            children: const [
              _Header(),
              _Tier(
                'Atoms',
                'The smallest pieces: tokens, controls and illustrations.',
              ),
              _Colors(),
              _Type(),
              _Icons(),
              _Motion(),
              _Buttons(),
              _ChipAtoms(),
              _Controls(),
              _Illustrations(),
              _Tier(
                'Molecules',
                'Atoms combined into working parts. Full screens (organisms) are not shown here.',
              ),
              _Fields(),
              _Places(),
              _Results(),
              _Reporting(),
              _Menu(),
              _Onboarding(),
              _Prompts(),
              _Settings(),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ scaffolding

class _Section extends StatelessWidget {
  const _Section(this.title, this.children);
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 36),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: KText.label.dm(
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
            color: KColors.mango,
          ),
        ),
        const SizedBox(height: 4),
        const Divider(color: KColors.surfaceBorder, thickness: 1.2, height: 1),
        const SizedBox(height: 16),
        ...children,
      ],
    ),
  );
}

/// One labelled specimen: name, spec line, then the component itself.
class _Spec extends StatelessWidget {
  const _Spec(this.name, this.spec, this.child);
  final String name;
  final String spec;
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: KText.section),
        Text(
          spec,
          style: KText.caption.dm(
            fontStyle: FontStyle.normal,
            color: KColors.textSubtle,
            fontSize: 10.5,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SvgPicture.asset('assets/brand/kombien-wordmark-light.svg', height: 30),
      const SizedBox(height: 18),
      Text('Style guide', style: KText.pageTitle),
      const SizedBox(height: 6),
      Text(
        'Every component from the designs, rebuilt in Flutter. Sizes are logical points on a 402-pt-wide phone.',
        style: KText.bodySmall,
      ),
    ],
  );
}

// ------------------------------------------------------------------ colors

class _Colors extends StatelessWidget {
  const _Colors();
  @override
  Widget build(BuildContext context) {
    Widget swatch(String name, Color c, {bool border = false}) {
      final hex =
          '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
      return SizedBox(
        width: 114,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: border ? KColors.surfaceBorder : c,
                  width: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: KText.label.dm(
                fontWeight: FontWeight.w500,
                color: KColors.charcoal,
              ),
            ),
            Text(
              hex,
              style: KText.caption.dm(
                fontStyle: FontStyle.normal,
                color: KColors.textSubtle,
              ),
            ),
          ],
        ),
      );
    }

    Widget grid(List<Widget> items) =>
        Wrap(spacing: 10, runSpacing: 12, children: items);
    return _Section('Colors', [
      _Spec(
        'Named colors',
        'from the product owner',
        grid([
          swatch('kombien-mango', KColors.mango),
          swatch('kombien-charcoal', KColors.charcoal),
          swatch('kombien-dust-grey', KColors.dustGrey),
          swatch('background', KColors.background, border: true),
          swatch('chip-background', KColors.chipBackground, border: true),
          swatch('location-blue', KColors.locationBlue),
          swatch('success', KColors.success),
          swatch('danger', KColors.danger),
        ]),
      ),
      _Spec(
        'Surfaces',
        'sampled from the screens',
        grid([
          swatch('surface (cards)', KColors.surface, border: true),
          swatch('surface-border', KColors.surfaceBorder),
          swatch('field', KColors.field, border: true),
          swatch('divider', KColors.divider),
        ]),
      ),
      _Spec(
        'Text',
        'darkest to faintest',
        grid([
          swatch('text-primary', KColors.textPrimary),
          swatch('text-body', KColors.textBody),
          swatch('text-muted', KColors.textMuted),
          swatch('text-subtle', KColors.textSubtle),
          swatch('text-faint', KColors.textFaint),
          swatch('placeholder', KColors.placeholder),
          swatch('on-dust', KColors.onDust),
        ]),
      ),
    ]);
  }
}

// ------------------------------------------------------------------ type

class _Type extends StatelessWidget {
  const _Type();
  @override
  Widget build(BuildContext context) {
    Widget row(String name, TextStyle s, String sample) => _Spec(
      name,
      'DM Sans ${s.fontSize!.toStringAsFixed(s.fontSize! % 1 == 0 ? 0 : 1)} · w${s.fontWeight!.value}${s.fontStyle == FontStyle.italic ? ' italic' : ''}',
      Text(sample, style: s),
    );
    return _Section('Typography', [
      row('Fare', KText.fare, '500 - 700 FCFA'),
      row('Onboarding title', KText.onboardingTitle, 'Je paie combien?'),
      row(
        'Headline',
        KText.headline,
        'Hey there! Worried about what fare to propose?',
      ),
      row('Title', KText.title, 'Tu go où?'),
      row('Page title', KText.pageTitle, 'Settings'),
      row('Entry', KText.entry, 'Awae Escaliers'),
      row('Route value', KText.routeValue, 'CICM Efoulan'),
      row('Toast title', KText.toastTitle, 'Feedback recorded!'),
      row(
        'Onboarding body',
        KText.onboardingBody,
        'See what other riders reported for your route before you start negotiating.',
      ),
      row(
        'Body',
        KText.body,
        'Turn on location so Kombien can pinpoint your exact starting spot.',
      ),
      row('Link', KText.link, 'Report it here'),
      row('Chip', KText.chip, 'Home'),
      row('Label', KText.label, 'Where are you leaving from?'),
      row(
        'Caption',
        KText.caption,
        'This range is a crowd-sourced average of what real riders recently paid.',
      ),
    ]);
  }
}

// ------------------------------------------------------------------ icons

class _Icons extends StatelessWidget {
  const _Icons();
  @override
  Widget build(BuildContext context) {
    const icons = <(String, List<List<dynamic>>)>[
      ('Gps01', HugeIcons.strokeRoundedGps01),
      ('Mic01', HugeIcons.strokeRoundedMic01),
      ('DashboardSquare01', HugeIcons.strokeRoundedDashboardSquare01),
      ('StickyNote03', HugeIcons.strokeRoundedStickyNote03),
      ('SaleTag02', HugeIcons.strokeRoundedSaleTag02),
      ('PaintBoard', HugeIcons.strokeRoundedPaintBoard),
      ('Settings01', HugeIcons.strokeRoundedSettings01),
      ('ArrowDownRight01', HugeIcons.strokeRoundedArrowDownRight01),
      ('InformationCircle', HugeIcons.strokeRoundedInformationCircle),
      ('ThumbsUp', HugeIcons.strokeRoundedThumbsUp),
      ('ThumbsDown', HugeIcons.strokeRoundedThumbsDown),
      ('Cancel01', HugeIcons.strokeRoundedCancel01),
      ('ChevronLeft', HugeIcons.strokeRoundedChevronLeft),
      ('ChevronRight', HugeIcons.strokeRoundedChevronRight),
      ('ChevronDown', HugeIcons.strokeRoundedChevronDown),
      ('ChevronUp', HugeIcons.strokeRoundedChevronUp),
      ('Taxi', HugeIcons.strokeRoundedTaxi),
      ('Motorbike02', HugeIcons.strokeRoundedMotorbike02),
      ('Trash', HugeIcons.strokeRoundedTrash),
      ('Download01', HugeIcons.strokeRoundedDownload01),
      ('PlusSign', HugeIcons.strokeRoundedPlusSign),
      ('Github', HugeIcons.strokeRoundedGithub),
      ('PhoneShake', HugeIcons.strokeRoundedPhoneShake),
      ('Coffee01', HugeIcons.strokeRoundedCoffee01),
      ('Globe02', HugeIcons.strokeRoundedGlobe02),
      ('Linkedin02', HugeIcons.strokeRoundedLinkedin02),
      ('Instagram', HugeIcons.strokeRoundedInstagram),
      ('NewTwitter', HugeIcons.strokeRoundedNewTwitter),
      ('Tick02', HugeIcons.strokeRoundedTick02),
      ('Copyright', HugeIcons.strokeRoundedCopyright),
    ];
    return _Section('Icons', [
      _Spec(
        'hugeicons · stroke rounded',
        '1.5 stroke, charcoal unless stated',
        Wrap(
          spacing: 8,
          runSpacing: 12,
          children: [
            for (final (name, icon) in icons)
              SizedBox(
                width: 82,
                child: Column(
                  children: [
                    HugeIcon(
                      icon: icon,
                      size: 24,
                      color: KColors.charcoal,
                      strokeWidth: 1.5,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: KText.caption.dm(
                        fontStyle: FontStyle.normal,
                        color: KColors.textMuted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ]);
  }
}

// ------------------------------------------------------------------ tiers

/// "ATOMS" / "MOLECULES" divider.
class _Tier extends StatelessWidget {
  const _Tier(this.name, this.blurb);
  final String name;
  final String blurb;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 48),
    child: Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: KColors.charcoal,
        borderRadius: BorderRadius.circular(KRadius.button),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: KText.title.dm(color: KColors.mango)),
          const SizedBox(height: 2),
          Text(blurb, style: KText.label.dm(color: KColors.background)),
        ],
      ),
    ),
  );
}

// ------------------------------------------------------------------ atoms: motion

String _f(double v, [int d = 2]) => v.toStringAsFixed(d);

class _Motion extends StatefulWidget {
  const _Motion();
  @override
  State<_Motion> createState() => _MotionState();
}

class _MotionState extends State<_Motion> with SingleTickerProviderStateMixin {
  late final _ball = AnimationController.unbounded(vsync: this, value: 0);
  bool _out = false;

  @override
  void dispose() {
    _ball.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const s = KMotion.spring, e = KMotion.settle;
    final mono = KText.caption.dm(
      fontStyle: FontStyle.normal,
      color: KColors.textBody,
      fontSize: 11.5,
      height: 1.5,
    );
    return _Section('Motion', [
      _Spec(
        'One spring for everything',
        'every component animation runs on these two springs; interrupted motion keeps its velocity',
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: KColors.surface,
            borderRadius: BorderRadius.circular(KRadius.option),
            border: Border.all(color: KColors.surfaceBorder, width: 1.2),
          ),
          child: Text(
            [
              'KMotion.spring: arrivals, draws, presses',
              'm = ${_f(s.mass, 0)}   k = ${_f(s.stiffness, 0)}   c = ${_f(s.damping, 1)}',
              'ω₀ = √(k/m) = ${_f(KMotion.omega0(s))} rad/s',
              'ζ = c / 2√(km) = ${_f(KMotion.zeta(s), 3)}',
              'ω_d = ω₀√(1 − ζ²) = ${_f(KMotion.omegaD(s))} rad/s',
              'x(t) = 1 − e^(−ζω₀t)·(cos ω_d t + (ζω₀/ω_d)·sin ω_d t)',
              'overshoot = e^(−πζ/√(1−ζ²)) = ${_f(KMotion.overshoot(s) * 100, 1)} %',
              'settles (±2 %) ≈ 4/(ζω₀) = ${_f(KMotion.settleTime(s))} s',
              '',
              'KMotion.settle: exits, colours, opacity (no overshoot)',
              'm = ${_f(e.mass, 0)}   k = ${_f(e.stiffness, 0)}   c = ${_f(e.damping, 1)}   ζ ≈ ${_f(KMotion.zeta(e), 2)}',
              'x(t) = 1 − (1 + ω₀t)·e^(−ω₀t),  ω₀ = ${_f(KMotion.omega0(e))} rad/s',
              'settles (±2 %) ≈ ${_f(KMotion.settleTime(e))} s',
              '',
              'Implicit animations use them as curves over ${KMotion.springDuration.inMilliseconds} ms',
              '',
              'KMotion.shake: error wiggle, released with a ${_f(KMotion.shakeKick, 0)} pt/s kick',
              'm = ${_f(KMotion.shake.mass, 0)}   k = ${_f(KMotion.shake.stiffness, 0)}   c = ${_f(KMotion.shake.damping, 0)}   ζ = ${_f(KMotion.zeta(KMotion.shake), 3)}',
              'x(t) = (v₀/ω_d)·e^(−ζω₀t)·sin ω_d t,  ω_d = ${_f(KMotion.omegaD(KMotion.shake))} rad/s (${_f(KMotion.omegaD(KMotion.shake) / (2 * math.pi), 1)} Hz)',
              'rests (±2 %) ≈ ${_f(KMotion.settleTime(KMotion.shake))} s',
            ].join('\n'),
            style: mono,
          ),
        ),
      ),
      _Spec(
        'The curves',
        'x(t) over 0.6 s · mango: spring · dust grey: settle · dashed: target',
        SizedBox(
          height: 120,
          width: double.infinity,
          child: CustomPaint(painter: _CurvePainter()),
        ),
      ),
      _Spec(
        'Try it',
        'tap the track: the dot springs to the other end; tap again mid-flight and it turns around carrying its speed',
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _out = !_out;
            KMotion.springTo(_ball, _out ? 1 : 0);
          },
          child: SizedBox(
            height: 36,
            child: LayoutBuilder(
              builder: (context, box) => AnimatedBuilder(
                animation: _ball,
                builder: (context, _) => Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 9),
                      color: KColors.surfaceBorder,
                    ),
                    Positioned(
                      left: (box.maxWidth - 18) * _ball.value,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: KColors.mango,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _CurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const span = .6, top = 1.1;
    Offset at(double t, double x) =>
        Offset(size.width * t / span, size.height * (1 - x / top));
    final target = Paint()
      ..color = KColors.textFaint
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawLine(
        Offset(x, at(0, 1).dy),
        Offset(x + 4, at(0, 1).dy),
        target,
      );
    }
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      target,
    );
    for (final (spec, color) in [
      (KMotion.settle, KColors.dustGrey),
      (KMotion.spring, KColors.mango),
    ]) {
      final path = Path()..moveTo(0, size.height);
      for (var i = 1; i <= 120; i++) {
        final t = span * i / 120;
        final o = at(t, KMotion.position(spec, t));
        path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_CurvePainter old) => false;
}

// ------------------------------------------------------------------ atoms: buttons

class _Buttons extends StatefulWidget {
  const _Buttons();
  @override
  State<_Buttons> createState() => _ButtonsState();
}

class _ButtonsState extends State<_Buttons> {
  int taps = 0;
  bool loading = false;
  Timer? _done;

  @override
  void dispose() {
    _done?.cancel();
    super.dispose();
  }

  void _load() {
    setState(() => loading = true);
    _done = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => loading = false);
    });
  }

  @override
  Widget build(BuildContext context) => _Section('Buttons & links', [
    _Spec(
      'Button',
      'h44 · r14 · mango · 15 w500 charcoal · press: sinks to 0.97 on the spring · disabled → enabled colour settles in',
      KButton(
        label: taps == 0 ? 'Get started from where I am' : 'Tapped $taps×',
        onPressed: () => setState(() => taps++),
      ),
    ),
    _Spec(
      'Button · loading',
      'tap: label gives way to three dots rising in a travelling wave (1.1 s loop, 0.16 phase step), the chat-app "on it" signal riders already read without thinking; taps ignored until done',
      KButton(
        label: 'See what riders paid',
        loading: loading,
        onPressed: _load,
      ),
    ),
    _Spec(
      'Link',
      '18 w700 italic · mango · underline · tap: underline redraws left → right on the spring',
      KLink('Report it here', onTap: () {}),
    ),
    const _Spec('Skip', '15 italic · text-subtle', KSkip('Skip for now')),
  ]);
}

// ------------------------------------------------------------------ atoms: chips

class _ChipAtoms extends StatefulWidget {
  const _ChipAtoms();
  @override
  State<_ChipAtoms> createState() => _ChipAtomsState();
}

class _ChipAtomsState extends State<_ChipAtoms> {
  bool option = true, icon = true, lang = true, segment = true;
  KCityState city = KCityState.available;
  double progress = 0;
  Timer? _download;

  @override
  void dispose() {
    _download?.cancel();
    super.dispose();
  }

  void _cityTap() {
    if (city == KCityState.saved) {
      setState(() => city = KCityState.available);
      return;
    }
    // Simulated download: uneven chunks, like a real mobile connection.
    final rnd = math.Random();
    setState(() {
      city = KCityState.downloading;
      progress = 0;
    });
    _download = Timer.periodic(const Duration(milliseconds: 260), (t) {
      if (!mounted) return t.cancel();
      setState(
        () => progress = math.min(1, progress + .04 + rnd.nextDouble() * .12),
      );
      if (progress >= 1) {
        t.cancel();
        Timer(const Duration(milliseconds: 380), () {
          if (mounted) setState(() => city = KCityState.saved);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) => _Section('Chips', [
    const _Spec(
      'How every chip moves',
      'select: the mango border traces once round the chip from 12 o\'clock, clockwise; as it closes the loop the fill and label settle to their selected colours. deselect: the dust-grey border traces round the same way, erasing the mango, then the colours settle back. trace on KMotion.spring, colours on KMotion.settle; press sinks to 0.96',
      SizedBox.shrink(),
    ),
    _Spec(
      'Saved destination',
      'h38 · r11 · chip-background · mango 1.2 · 14 w500 italic mango · tap: outline redraws (an action, not a selection)',
      Align(
        alignment: Alignment.centerLeft,
        child: KSavedChip('Home', onTap: () {}),
      ),
    ),
    _Spec(
      'Option',
      'h36 · r12 · selected: outline mango · unselected: dust-grey fill · tap to toggle',
      Align(
        alignment: Alignment.centerLeft,
        child: KOptionChip(
          'Morning',
          selected: option,
          onTap: () => setState(() => option = !option),
        ),
      ),
    ),
    _Spec(
      'Icon option',
      '44 square · r12 · tap to toggle',
      Align(
        alignment: Alignment.centerLeft,
        child: KIconChip(
          icon: HugeIcons.strokeRoundedTaxi,
          selected: icon,
          onTap: () => setState(() => icon = !icon),
        ),
      ),
    ),
    _Spec(
      'Language',
      'flag | label · upright text · tap to toggle',
      Align(
        alignment: Alignment.centerLeft,
        child: KLanguageChip(
          flag: KFlag.uk,
          label: 'English',
          selected: lang,
          onTap: () => setState(() => lang = !lang),
        ),
      ),
    ),
    _Spec(
      'Segment option',
      'h46 · r12 · two-line · tap to toggle',
      Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 120,
          child: KSegmentOption(
            'Wi-Fi and\nmobile data',
            selected: segment,
            onTap: () => setState(() => segment = !segment),
          ),
        ),
      ),
    ),
    _Spec(
      'City',
      'tap Download01: the border empties to a pale track and refills in mango from 12 o\'clock as the download progresses; at 100 % the icon springs into a danger-red Trash. tap Trash: deleted, back to Download01',
      Align(
        alignment: Alignment.centerLeft,
        child: KCityChip(
          'Douala',
          state: city,
          progress: progress,
          onTap: _cityTap,
        ),
      ),
    ),
    const _Spec(
      'Count badge',
      '22 circle · mango 1.2',
      Align(alignment: Alignment.centerLeft, child: KCountBadge(14)),
    ),
  ]);
}

// ------------------------------------------------------------------ atoms: small controls

class _Controls extends StatefulWidget {
  const _Controls();
  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  int dot = 0;
  bool checked = true, menuOpen = false;

  @override
  Widget build(BuildContext context) => _Section('Small controls', [
    const _Spec(
      'Flags',
      'round · 16–18',
      Row(
        children: [
          KFlagIcon(KFlag.uk),
          SizedBox(width: 10),
          KFlagIcon(KFlag.france),
        ],
      ),
    ),
    _Spec(
      'Page dots',
      '7 · active mango · tap to advance · colour settles on KMotion.settle',
      GestureDetector(
        onTap: () => setState(() => dot = (dot + 1) % 2),
        child: Align(
          alignment: Alignment.centerLeft,
          child: KPageDots(count: 2, index: dot),
        ),
      ),
    ),
    _Spec(
      'Checkbox',
      '19 · r4 · mango · Tick02 · tap: box floods mango, tick draws in from the left with a small spring settle; untick runs back',
      KTermsCheckbox(
        checked: checked,
        onChanged: (v) => setState(() => checked = v),
      ),
    ),
    _Spec(
      'Menu button',
      '72.25 × 50.2 stadium · 2.2 rim #FDD896 · 1.25 past the edge · grid outline when closed, solid when open · tap to toggle',
      Align(
        alignment: Alignment.centerRight,
        child: Transform.translate(
          offset: const Offset(KSpace.page, 0),
          child: KMenuButton(
            open: menuOpen,
            onTap: () => setState(() => menuOpen = !menuOpen),
          ),
        ),
      ),
    ),
  ]);
}

// ------------------------------------------------------------------ toasts

// ------------------------------------------------------------------ molecules: fields

const _places = [
  ('Awae Escaliers', '~26km'),
  ('Carrefour l\'amitie', '~27km'),
  ('Carrefour Mvan', '~41km'),
  ('Palais des Congres Yaounde Conference Centre', '~26km'),
  ('Eyang', '~18km'),
];

class _Fields extends StatefulWidget {
  const _Fields();
  @override
  State<_Fields> createState() => _FieldsState();
}

const _landmarks = [
  ('Poste Centrale', '~2km'),
  ('Carrefour Warda', '~3km'),
  ('Marche Mokolo', '~4km'),
  ('Rond-point Nlongkak', '~3km'),
  ('Carrefour Bastos', '~6km'),
];

class _FieldsState extends State<_Fields> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _from = TextEditingController(text: 'My location');
  final _fromFocus = FocusNode();
  bool _picked = false;
  String _fromQuery = '';
  String? _error;
  int _shake = 0;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _from.dispose();
    _fromFocus.dispose();
    super.dispose();
  }

  List<(String, String)> get _landmarkMatches {
    final q = _fromQuery.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final hits = _landmarks
        .where((p) => p.$1.toLowerCase().contains(q))
        .toList();
    return (hits.isEmpty ? _landmarks : hits).take(3).toList();
  }

  Widget _suggestions(
    List<(String, String)> items,
    ValueChanged<int> onSelected,
  ) => AnimatedSize(
    duration: KMotion.springDuration,
    curve: KMotion.settleCurve,
    alignment: Alignment.topCenter,
    child: items.isEmpty
        ? const SizedBox(width: double.infinity)
        : Padding(
            padding: const EdgeInsets.only(top: 14),
            child: KSuggestionsCard(items: items, onSelected: onSelected),
          ),
  );

  List<(String, String)> get _matches {
    final q = _controller.text.trim().toLowerCase();
    if (q.isEmpty || _picked) return const [];
    final hits = _places.where((p) => p.$1.toLowerCase().contains(q)).toList();
    return (hits.isEmpty ? _places : hits).take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches;
    return _Section('Fields', [
      _Spec(
        'Location field',
        'label 12 · field h36 r10 #FDF5E7 · Gps01 21. With permission it opens on "My location" (14 w500 location-blue), one token: tap in and backspace once and it all goes, fading left; a typed letter replaces it. Then it is a landmark search (charcoal) with suggestions. Gps01 or leaving it empty restores My location',
        Column(
          children: [
            KLocationField(
              controller: _from,
              focusNode: _fromFocus,
              onChanged: (q) => setState(() => _fromQuery = q),
            ),
            _suggestions(_landmarkMatches, (i) {
              _from.text = _landmarkMatches[i].$1;
              _fromFocus.unfocus();
              setState(() => _fromQuery = '');
            }),
          ],
        ),
      ),
      _Spec(
        'Location field · denied',
        'no permission: a landmark search from the start · hint 12 text-subtle "Can\'t see where you are. Search a landmark instead" · GpsOff01 danger, tap to ask for location again',
        KLocationField(
          locationDenied: true,
          onRequestLocation: () {},
          onChanged: (_) {},
        ),
      ),
      _Spec(
        'Location field · error',
        'a destination picked with no start: the field wiggles on KMotion.shake, the border turns danger 1.2, Alert02 + 12 danger message eases open below, and the cursor lands in it. Typing clears it. Tap the link to try',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KLocationField(
              locationDenied: true,
              onRequestLocation: () {},
              errorText: _error,
              shakeSignal: _shake,
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 12),
            KLink(
              'Pick a destination first',
              onTap: () => setState(() {
                _error = context.l10n.startMissing;
                _shake++;
              }),
            ),
          ],
        ),
      ),
      _Spec(
        'Destination search',
        'title 22 w700 · entry 26 italic: grey placeholder → charcoal as you type · suggestions r18 open while typing · pick one to fill',
        Column(
          children: [
            KEntryField(
              controller: _controller,
              focusNode: _focus,
              onChanged: (_) => setState(() => _picked = false),
            ),
            _suggestions(matches, (i) {
              _controller.text = matches[i].$1;
              _focus.unfocus();
              setState(() => _picked = true);
            }),
          ],
        ),
      ),
    ]);
  }
}

// ------------------------------------------------------------------ molecules: saved places

class _Places extends StatefulWidget {
  const _Places();
  @override
  State<_Places> createState() => _PlacesState();
}

class _PlacesState extends State<_Places> {
  final _toasts = GlobalKey<KToastHostState>();

  /// Name → landmark.
  final places = <String, String>{'Home': 'Carrefour Bastos'};

  final _from = TextEditingController(text: 'My location');
  final _fromFocus = FocusNode();
  final _to = TextEditingController();
  final _toFocus = FocusNode();
  String _fromQuery = '', _toQuery = '';
  String? _fromPicked, _toPicked, used;

  @override
  void dispose() {
    _from.dispose();
    _fromFocus.dispose();
    _to.dispose();
    _toFocus.dispose();
    super.dispose();
  }

  List<(String, String)> _match(List<(String, String)> from, String q) {
    q = q.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final hits = from.where((p) => p.$1.toLowerCase().contains(q)).toList();
    return (hits.isEmpty ? from : hits).take(3).toList();
  }

  String? _savedAs(String? place) {
    for (final e in places.entries) {
      if (e.value == place) return e.key;
    }
    return null;
  }

  void _save(String name, String place) {
    setState(() {
      places.removeWhere((k, v) => v == place); // one name per place
      places[name] = place;
    });
    _toasts.currentState?.show(
      'Saved!',
      '$name is $place',
      'It is in your saved destinations, ready as a start or a destination',
    );
  }

  Widget _suggest(List<(String, String)> items, ValueChanged<int> pick) =>
      AnimatedSize(
        duration: KMotion.springDuration,
        curve: KMotion.settleCurve,
        alignment: Alignment.topCenter,
        child: items.isEmpty
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: const EdgeInsets.only(top: 12),
                child: KSuggestionsCard(items: items, onSelected: pick),
              ),
      );

  Widget _prompt(String? place) => AnimatedSize(
    duration: KMotion.springDuration,
    curve: KMotion.settleCurve,
    alignment: Alignment.topCenter,
    child: place == null
        ? const SizedBox(width: double.infinity)
        : Padding(
            padding: const EdgeInsets.only(top: 4),
            child: KSavePlacePrompt(
              place: place,
              savedAs: _savedAs(place),
              onSave: (name) => _save(name, place),
              onRemove: () =>
                  setState(() => places.removeWhere((k, v) => v == place)),
            ),
          ),
  );

  @override
  Widget build(BuildContext context) {
    final fromMatches = _match(_landmarks, _fromQuery);
    final toMatches = _match(_places, _toQuery);
    return _Section('Saved places', [
      _Spec(
        'Pick → Save this place → name → Save',
        'after a suggestion is picked, start or destination, one quiet line appears under the field: BookmarkAdd02 + "Save this place" (13 italic w500 mango). Tap: an inline r14 surface opens with name chips (Home, School, Work) and an "Other name…" field, then Save. Once saved the line reads "Saved as Work" (Bookmark02); tap it to rename or remove. Try it: search a start, then a destination',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KLocationField(
              controller: _from,
              focusNode: _fromFocus,
              onChanged: (q) => setState(() {
                _fromQuery = q;
                _fromPicked = null;
              }),
            ),
            _suggest(fromMatches, (i) {
              _from.text = fromMatches[i].$1;
              _fromFocus.unfocus();
              setState(() {
                _fromPicked = fromMatches[i].$1;
                _fromQuery = '';
              });
            }),
            _prompt(_fromPicked),
            const SizedBox(height: 18),
            KEntryField(
              controller: _to,
              focusNode: _toFocus,
              onChanged: (q) => setState(() {
                _toQuery = q;
                _toPicked = null;
              }),
            ),
            _suggest(toMatches, (i) {
              _to.text = toMatches[i].$1;
              _toFocus.unfocus();
              setState(() {
                _toPicked = toMatches[i].$1;
                _toQuery = '';
              });
            }),
            _prompt(_toPicked),
            KToastHost(key: _toasts),
          ],
        ),
      ),
      _Spec(
        'Saved places row',
        'bottom of home · one Saved destination chip per saved place, tap to use (fills the start if that field is active, else the destination) · empty: a one-line hint',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KSavedPlacesRow(
              places: places,
              onUse: (name) => setState(() => used = name),
            ),
            if (used != null && places[used] != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  '$used → ${places[used]}',
                  style: KText.label.dm(color: KColors.textMuted),
                ),
              ),
          ],
        ),
      ),
    ]);
  }
}

// ------------------------------------------------------------------ molecules: results

class _Results extends StatefulWidget {
  const _Results();
  @override
  State<_Results> createState() => _ResultsState();
}

class _ResultsState extends State<_Results> {
  final _toasts = GlobalKey<KToastHostState>();

  void _thanks() => _toasts.currentState?.show(
    'Thank you!',
    'Feedback recorded!',
    'Your answer will help us make the product even better',
  );

  @override
  Widget build(BuildContext context) => _Section('Results', [
    const _Spec(
      'Fare card',
      'r22 · label 14 mango · 56 w700 · InformationCircle + caption 10 italic',
      KFareCard(range: '500 - 700\nFCFA'),
    ),
    _Spec('Cash hint', 'coin-stack 26 · 15 text-faint', const KCashHint()),
    _Spec(
      'Feedback',
      'ThumbsUp success · ThumbsDown danger · 24 · tap a thumb: toast w237 r14, gone after 4 s or ×',
      Column(
        children: [
          KFeedbackRow(onUp: _thanks, onDown: _thanks),
          KToastHost(key: _toasts),
        ],
      ),
    ),
  ]);
}

// ------------------------------------------------------------------ molecules: reporting

class _Reporting extends StatefulWidget {
  const _Reporting();
  @override
  State<_Reporting> createState() => _ReportingState();
}

class _ReportingState extends State<_Reporting> {
  final _amount = TextEditingController();
  final _toasts = GlobalKey<KToastHostState>();
  int? price;
  int time = 0;
  static const _prices = ['500', '600', '750'];

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasAmount = _amount.text.trim().isNotEmpty;
    return _Section('Reporting', [
      const _Spec(
        'Route card',
        'r20 · label 14 mango · 26 w700 italic · 3 lines then ellipsis',
        KRouteCard(
          from: 'CICM Efoulan',
          to: 'Palais des Congres Yaounde Conference Centre',
        ),
      ),
      _Spec(
        'Fare entry',
        'price chips fill the amount, or type one: grouped live as you type, 1500 → 1 500, 10000 → 10 000 (no-break space) · Add report stays disabled (dust grey) until there is an amount, then confirms with a toast',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Some suggestions (prices in FCFA)',
              style: KText.label.dm(
                fontStyle: FontStyle.italic,
                color: KColors.charcoal,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: [
                for (final (i, p) in _prices.indexed)
                  KOptionChip(
                    p,
                    selected: price == i,
                    onTap: () => setState(() {
                      price = i;
                      _amount.text = p;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            KEntryField(
              title: 'Paid something else?',
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: const [KMoneyFormatter()],
              onChanged: (v) {
                final i = _prices.indexOf('${KMoneyFormatter.parse(v) ?? ''}');
                setState(() => price = i >= 0 ? i : null);
              },
            ),
            KToastHost(key: _toasts),
            const SizedBox(height: 14),
            KButton(
              label: 'Add report',
              onPressed: hasAmount
                  ? () {
                      _toasts.currentState?.show(
                        'Thanks!',
                        'Report added!',
                        'Your report is now helping other riders on this route',
                      );
                      setState(() {
                        _amount.clear();
                        price = null;
                      });
                    }
                  : null,
            ),
          ],
        ),
      ),
      _Spec(
        'Option row',
        'italic label + option chips · one selected at a time',
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Time of day',
              style: KText.bodySmall.dm(
                fontStyle: FontStyle.italic,
                color: KColors.charcoal,
              ),
            ),
            for (final (i, t) in ['Morning', 'Day', 'Night'].indexed)
              KOptionChip(
                t,
                selected: time == i,
                onTap: () => setState(() => time = i),
              ),
          ],
        ),
      ),
    ]);
  }
}

// ------------------------------------------------------------------ menu

class _Menu extends StatefulWidget {
  const _Menu();
  @override
  State<_Menu> createState() => _MenuState();
}

class _MenuState extends State<_Menu> {
  int current = 3;
  @override
  Widget build(BuildContext context) => _Section('Floating menu', [
    _Spec(
      'Menu',
      '48 rows · 25 icon · 16.8 medium −0.82 · 0.4 mango underline · current page filled · Je paie combien? beside the button, Report above, Settings and Style guide below · springs out, picking or closing reverses',
      Transform.translate(
        offset: const Offset(KSpace.page, 0),
        child: SizedBox(
          height: 260,
          child: KFloatingMenu(
            verticalPosition: .34,
            current: current,
            onSelected: (i) => setState(() => current = i),
            entries: const [
              KMenuEntry(
                icon: HugeIcons.strokeRoundedSaleTag02,
                label: 'Je paie combien?',
              ),
              KMenuEntry(
                icon: HugeIcons.strokeRoundedStickyNote03,
                label: 'Report',
              ),
              KMenuEntry(
                icon: HugeIcons.strokeRoundedSettings01,
                label: 'Settings',
              ),
              KMenuEntry(
                icon: HugeIcons.strokeRoundedPaintBoard,
                label: 'Style guide',
              ),
            ],
          ),
        ),
      ),
    ),
  ]);
}

// ------------------------------------------------------------------ onboarding

/// Onboarding: Continue advances to step 2; Get started needs the terms ticked.
class _Onboarding extends StatefulWidget {
  const _Onboarding();
  @override
  State<_Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<_Onboarding> {
  int step = 0;
  bool accepted = false;

  @override
  Widget build(BuildContext context) => _Section('Onboarding', [
    const _Spec(
      'Language selector',
      'flag | En · ChevronDown · tap: a dropdown springs open under it (r14 surface, each language named in itself, current ticked); pick to switch, tap outside to close',
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [_LanguageDemo()],
      ),
    ),
    _Spec(
      'Sheet',
      'top r28 · dots · title · body 19 · pill button. Tap Continue; tick the box to enable Get started',
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: step == 0
            ? KOnboardingSheet(
                key: const ValueKey(0),
                title: 'Je paie combien?',
                body:
                    'See what other riders reported for your route before you start negotiating. A range, not a guess.',
                footnote: "Fares are reported by riders. They're not official.",
                action: 'Continue',
                onAction: () => setState(() => step = 1),
              )
            : KOnboardingSheet(
                key: const ValueKey(1),
                index: 1,
                title: 'Paid? Say so.',
                body:
                    'Add what you paid in a few taps. The next rider will see it.',
                footnote: 'Help someone help you',
                terms: true,
                termsAccepted: accepted,
                onTermsChanged: (v) => setState(() => accepted = v),
                action: 'Get started',
                onAction: () => setState(() {
                  step = 0;
                  accepted = false;
                }),
              ),
      ),
    ),
  ]);
}

// ------------------------------------------------------------------ prompts

class _Prompts extends StatefulWidget {
  const _Prompts();
  @override
  State<_Prompts> createState() => _PromptsState();
}

class _PromptsState extends State<_Prompts> {
  bool retrying = false;
  Timer? _t;

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Section('Prompt card', [
    const _Spec(
      'Prompt card',
      'card r20 · sticker stack (r20 cards) breaks the top edge · headline 30 w700. Used for the location prompt and the no-reports empty state',
      KPromptCard(
        stack: KStickerStack(
          left: 'assets/illustrations/chat-bubble.webp',
          middle: 'assets/illustrations/coin-stack.webp',
          right: 'assets/illustrations/clock.webp',
        ),
        title: 'Hey there! Worried about what fare to propose?',
        body:
            'Turn on location so Kombien can pinpoint your exact starting spot and match it against real fares reported by other riders nearby. Propose with confidence. No guessing, no overpaying.',
        action: 'Get started from where I am',
        skip: 'Skip for now',
      ),
    ),
    const SizedBox(height: 12),
    _Spec(
      'Offline',
      'compact: title 23 w700, no body · bird-house · empty-drawer · no-internet · Retry shows the loading dots while it tries',
      KPromptCard(
        compact: true,
        stack: const KStickerStack(
          left: 'assets/illustrations/bird-house.webp',
          middle: 'assets/illustrations/empty-drawer.webp',
          right: 'assets/illustrations/no-internet.webp',
        ),
        title: 'No connection. Showing saved fares.',
        action: 'Retry',
        actionLoading: retrying,
        onAction: () {
          setState(() => retrying = true);
          _t = Timer(const Duration(milliseconds: 2200), () {
            if (mounted) setState(() => retrying = false);
          });
        },
      ),
    ),
    const SizedBox(height: 12),
    const _Spec(
      'No match',
      'compact, no button: the field above stays the way out · reunification-monument · mountain-landmark · magnifying-glass',
      KPromptCard(
        compact: true,
        stack: KStickerStack(
          left: 'assets/illustrations/reunification-monument.webp',
          middle: 'assets/illustrations/mountain-landmark.webp',
          right: 'assets/illustrations/magnifying-glass.webp',
        ),
        title: "Couldn't find that place. Try a nearby landmark instead",
      ),
    ),
  ]);
}

// ------------------------------------------------------------------ settings

class _Settings extends StatelessWidget {
  const _Settings();
  @override
  Widget build(BuildContext context) => _Section('Settings', [
    _Spec(
      'Rows',
      'h42 · 14 text-subtle · ChevronRight · optional count badge or leading icon',
      Column(
        children: [
          const KSettingsRow('Reports from this phone', badge: KCountBadge(14)),
          const KSettingsRow(
            'Contribute on Github',
            leading: HugeIcons.strokeRoundedGithub,
          ),
          KSettingsRow(
            'Shake to report a problem',
            leading: HugeIcons.strokeRoundedPhoneShake,
            chevron: false,
            color: KColors.mango.withValues(alpha: .7),
          ),
        ],
      ),
    ),
    const _Spec(
      'Developer card',
      'surface · Coffee01 button · social buttons 46 r12',
      KDevCard(),
    ),
    const _Spec('Footer', 'Copyright 16 · 12 text-subtle', KCopyrightFooter()),
  ]);
}

// ------------------------------------------------------------------ illustrations

class _Illustrations extends StatelessWidget {
  const _Illustrations();
  @override
  Widget build(BuildContext context) {
    const objects = [
      'chat-bubble',
      'coin-stack',
      'clock',
      'hand',
      'tag',
      'sticky-note',
      'money',
      'magnifying-glass',
      'empty-drawer',
      'no-internet',
      'bird-house',
      'mountain-landmark',
      'reunification-monument',
    ];
    final cardColors = [
      KColors.stickerGrey,
      KColors.stickerMango,
      KColors.stickerDust,
    ];
    return _Section('Illustrations', [
      _Spec(
        'Wordmark',
        'vector · brand/logo/exports/svg',
        Align(
          alignment: Alignment.centerLeft,
          child: SvgPicture.asset(
            'assets/brand/kombien-wordmark-light.svg',
            height: 34,
          ),
        ),
      ),
      _Spec(
        'City backdrop',
        'splash background (raster)',
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(
            'assets/illustrations/splash-city.webp',
            height: 420,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ),
      _Spec(
        'Kids',
        'onboarding: the girl hailing a taxi and the boy at the notice board (rasters from brand/product/image)',
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/illustrations/splash-girl.webp',
                  height: 340,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/illustrations/splash-boy.webp',
                  height: 340,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
      _Spec(
        'Objects',
        'sticker style: flat color, white rim · on tilted cards r20',
        Wrap(
          spacing: 18,
          runSpacing: 22,
          children: [
            for (final (i, o) in objects.indexed)
              Column(
                children: [
                  KStickerCard(
                    asset: 'assets/illustrations/$o.webp',
                    color: cardColors[i % 3],
                    angle: (i.isEven ? -1 : 1) * .06,
                    width: 96,
                    height: 112,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    o,
                    style: KText.caption.dm(
                      fontStyle: FontStyle.normal,
                      color: KColors.textMuted,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      _Spec(
        'Skyline',
        'vector · sits faded behind the working screens',
        Opacity(
          opacity: .45,
          child: SvgPicture.asset('assets/illustrations/bottom-building.svg'),
        ),
      ),
    ]);
  }
}

class _LanguageDemo extends StatefulWidget {
  const _LanguageDemo();
  @override
  State<_LanguageDemo> createState() => _LanguageDemoState();
}

class _LanguageDemoState extends State<_LanguageDemo> {
  Locale current = const Locale('en');
  @override
  Widget build(BuildContext context) => KLanguageSelector(
    current: current,
    onSelected: (l) => setState(() => current = l),
  );
}
