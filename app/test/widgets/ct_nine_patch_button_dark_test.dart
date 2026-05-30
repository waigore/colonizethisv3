// Widget tests for the dark editorial-monocle visual contract on
// `CtNinePatchButton` (`Refs #2859` S2 / R1). Verifies the AC set:
//   - gradient background sourced from `CtGradients.buttonGradient`
//   - 1 px border, default `--border`, hover `--accent`
//   - four 10x10 brass corner brackets, default `--accent` at 0.75 alpha,
//     hover `--accent-bright` at 1.0 alpha
//   - engraved label text shadow `Offset(0, 1)` blur 0 colour `--surface`
//   - disabled wraps the button in 0.4 opacity and suppresses taps.

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpButton(
  WidgetTester tester, {
  required VoidCallback? onPressed,
  bool enabled = true,
  bool dangerVariant = false,
  double? disabledOpacityOverride,
  LinearGradient? gradient,
  LinearGradient? pressedGradient,
  Widget child = const Text('Confirm'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppThemes.editorialMonocle,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 200,
            child: CtNinePatchButton(
              onPressed: onPressed,
              enabled: enabled,
              dangerVariant: dangerVariant,
              disabledOpacityOverride: disabledOpacityOverride,
              gradient: gradient,
              pressedGradient: pressedGradient,
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

DecoratedBox _findButtonSurfaceDecoratedBox(WidgetTester tester) {
  final Finder boxes = find.descendant(
    of: find.byType(CtNinePatchButton),
    matching: find.byWidgetPredicate(
      (Widget widget) =>
          widget is DecoratedBox &&
          (widget.decoration is BoxDecoration) &&
          (widget.decoration as BoxDecoration).gradient != null,
    ),
  );
  expect(
    boxes,
    findsAtLeastNWidgets(1),
    reason: 'CtNinePatchButton must paint a gradient surface',
  );
  return tester.widget<DecoratedBox>(boxes.first);
}

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'default state paints buttonGradient and 1px --border border',
    (WidgetTester tester) async {
      await _pumpButton(tester, onPressed: () {});

      final DecoratedBox box = _findButtonSurfaceDecoratedBox(tester);
      final BoxDecoration decoration = box.decoration as BoxDecoration;

      expect(decoration.gradient, isA<LinearGradient>());
      final LinearGradient gradient = decoration.gradient! as LinearGradient;
      expect(gradient.begin, Alignment.topCenter);
      expect(gradient.end, Alignment.bottomCenter);
      expect(gradient.colors, <Color>[
        EditorialMonoclePalette.surfaceLite,
        EditorialMonoclePalette.surface,
      ]);
      expect(
        gradient.colors,
        CtGradients.buttonGradient.colors,
        reason: 'Surface gradient must originate from CtGradients.buttonGradient',
      );

      final Border? border = decoration.border as Border?;
      expect(border, isNotNull);
      expect(border!.top.width, CtNinePatchButton.borderWidth);
      expect(border.top.color, EditorialMonoclePalette.border);
    },
  );

  testWidgets(
    'hover brightens corner brackets and shifts border to --accent',
    (WidgetTester tester) async {
      await _pumpButton(tester, onPressed: () {});

      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: const Offset(1, 1));
      await tester.pumpAndSettle();

      final Offset center = tester.getCenter(find.byType(CtNinePatchButton));
      await gesture.moveTo(center);
      await tester.pump();
      await tester.pump(CtNinePatchButton.animationDuration);
      await tester.pumpAndSettle();

      final DecoratedBox hoverBox = _findButtonSurfaceDecoratedBox(tester);
      final BoxDecoration hoverDecoration =
          hoverBox.decoration as BoxDecoration;
      final Border hoverBorder = hoverDecoration.border! as Border;
      expect(
        hoverBorder.top.color,
        EditorialMonoclePalette.accent,
        reason: 'Hover state must shift border to --accent',
      );

      await gesture.moveTo(const Offset(-50, -50));
      await tester.pumpAndSettle();

      final DecoratedBox restBox = _findButtonSurfaceDecoratedBox(tester);
      final BoxDecoration restDecoration = restBox.decoration as BoxDecoration;
      final Border restBorder = restDecoration.border! as Border;
      expect(restBorder.top.color, EditorialMonoclePalette.border);
    },
  );

  testWidgets(
    'engraved label text uses a 1px downward shadow coloured from --surface',
    (WidgetTester tester) async {
      await _pumpButton(tester, onPressed: () {});

      final Finder labelFinder = find.text('Confirm');
      expect(labelFinder, findsOneWidget);

      final RichText rich = tester.widget<RichText>(
        find.descendant(of: labelFinder, matching: find.byType(RichText)),
      );
      final TextSpan span = rich.text as TextSpan;
      final List<Shadow>? shadows = span.style?.shadows;
      expect(shadows, isNotNull);
      expect(shadows!.length, 1);
      expect(shadows.first.offset, CtNinePatchButton.engravedShadowOffset);
      expect(shadows.first.blurRadius, 0);
      expect(
        shadows.first.color,
        EditorialMonoclePalette.surface,
        reason: 'Engraved-text shadow must resolve from the --surface token',
      );
    },
  );

  testWidgets(
    'disabled state wraps button in 0.4 opacity and suppresses taps',
    (WidgetTester tester) async {
      int taps = 0;
      await _pumpButton(
        tester,
        onPressed: () => taps += 1,
        enabled: false,
      );

      final Finder opacityFinder = find.descendant(
        of: find.byType(CtNinePatchButton),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is Opacity && w.opacity == CtNinePatchButton.disabledOpacity,
        ),
      );
      expect(
        opacityFinder,
        findsOneWidget,
        reason: 'Disabled CtNinePatchButton must render at 0.4 opacity',
      );
      expect(CtNinePatchButton.disabledOpacity, 0.4);

      await tester.tap(
        find.byType(CtNinePatchButton),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(taps, 0, reason: 'Disabled button must not fire onPressed');
    },
  );

  testWidgets(
    'disabledOpacityOverride replaces the catalog 0.4 default when set '
    '(positive path — issue #2861 R1 / AC#9 next-turn button uses 0.35)',
    (WidgetTester tester) async {
      // Mirrors the in-game Next-turn button contract: a per-instance
      // override of 0.35 replaces the shared catalog default (0.4) for
      // this widget tree only. SPEC: SPEC/ui/game-screen.md Acceptance
      // Criteria + .next-turn.disabled in
      // SPEC/ui/mockups/GAME10001-game-screen.html.
      await _pumpButton(
        tester,
        onPressed: () {},
        enabled: false,
        disabledOpacityOverride: 0.35,
      );

      final Finder overrideFinder = find.descendant(
        of: find.byType(CtNinePatchButton),
        matching: find.byWidgetPredicate(
          (Widget w) => w is Opacity && w.opacity == 0.35,
        ),
      );
      expect(
        overrideFinder,
        findsOneWidget,
        reason:
            'disabledOpacityOverride: 0.35 must apply Opacity(opacity: 0.35) '
            'instead of the catalog default 0.4.',
      );

      final Finder defaultFinder = find.descendant(
        of: find.byType(CtNinePatchButton),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is Opacity && w.opacity == CtNinePatchButton.disabledOpacity,
        ),
      );
      expect(
        defaultFinder,
        findsNothing,
        reason:
            'When disabledOpacityOverride is set the catalog default 0.4 '
            'Opacity wrapper must not also paint (no double dim).',
      );
    },
  );

  testWidgets(
    'disabledOpacityOverride: null preserves the catalog 0.4 default '
    '(negative / regression guard — every other CtNinePatchButton call '
    'site must keep the shared disabled convention)',
    (WidgetTester tester) async {
      await _pumpButton(
        tester,
        onPressed: () {},
        enabled: false,
      );

      final Finder defaultFinder = find.descendant(
        of: find.byType(CtNinePatchButton),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is Opacity && w.opacity == CtNinePatchButton.disabledOpacity,
        ),
      );
      expect(
        defaultFinder,
        findsOneWidget,
        reason:
            'CtNinePatchButton with no disabledOpacityOverride must keep '
            'the shared catalog convention CtNinePatchButton.disabledOpacity '
            '(0.4) so CtBackButton, CtToggleSwitch, CtProgressBar, etc. '
            'continue to read consistently with every other dark-theme '
            'disabled control.',
      );

      // Confirm 0.35 is not accidentally applied to non-next-turn buttons.
      final Finder strayNextTurnFinder = find.descendant(
        of: find.byType(CtNinePatchButton),
        matching: find.byWidgetPredicate(
          (Widget w) => w is Opacity && w.opacity == 0.35,
        ),
      );
      expect(
        strayNextTurnFinder,
        findsNothing,
        reason:
            'Default CtNinePatchButton must not pick up the 0.35 next-turn '
            'override when no disabledOpacityOverride is passed.',
      );
    },
  );

  testWidgets(
    'enabled state with disabledOpacityOverride does not apply any Opacity '
    'wrapper (the override only takes effect when the button is disabled)',
    (WidgetTester tester) async {
      await _pumpButton(
        tester,
        onPressed: () {},
        disabledOpacityOverride: 0.35,
      );

      final Finder opacityFinder = find.descendant(
        of: find.byType(CtNinePatchButton),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is Opacity &&
              (w.opacity == 0.35 ||
                  w.opacity == CtNinePatchButton.disabledOpacity),
        ),
      );
      expect(
        opacityFinder,
        findsNothing,
        reason:
            'disabledOpacityOverride must only activate when the button is '
            'disabled; enabled buttons never paint the dimming wrapper.',
      );
    },
  );

  testWidgets(
    'enabled state with non-null onPressed fires callback on tap',
    (WidgetTester tester) async {
      int taps = 0;
      await _pumpButton(tester, onPressed: () => taps += 1);

      await tester.tap(find.byType(CtNinePatchButton));
      await tester.pumpAndSettle();
      expect(taps, 1);
    },
  );

  testWidgets(
    'four brass corner brackets are painted via CustomPaint',
    (WidgetTester tester) async {
      await _pumpButton(tester, onPressed: () {});

      // The painter sits behind the surface so the brackets remain non-
      // interactive. We verify exactly one painter instance is present
      // (it paints all four corners).
      final Finder painters = find.descendant(
        of: find.byType(CtNinePatchButton),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is CustomPaint &&
              w.painter != null &&
              w.painter.runtimeType.toString() ==
                  '_BrassCornerBracketsPainter',
        ),
      );
      expect(painters, findsOneWidget);
      expect(CtNinePatchButton.cornerBracketSize, 10);
    },
  );

  testWidgets(
    'pressedGradient swaps the surface gradient transiently while held; '
    'reverts to the rest gradient after the gesture completes',
    (WidgetTester tester) async {
      // SPEC/ui/main-menu.md AC `Wood-panel button pressed gradient
      // inversion`. Drives the button via a fine-grained TestGesture so the
      // pressed-state surface can be inspected between onTapDown and
      // onTap/onTapCancel.
      await _pumpButton(
        tester,
        onPressed: () {},
        gradient: CtGradients.woodPanelButtonGradient,
        pressedGradient: CtGradients.woodPanelButtonGradientPressed,
      );

      final DecoratedBox restBox = _findButtonSurfaceDecoratedBox(tester);
      final BoxDecoration restDecoration = restBox.decoration as BoxDecoration;
      final LinearGradient restGradient =
          restDecoration.gradient! as LinearGradient;
      expect(
        restGradient.colors,
        CtGradients.woodPanelButtonGradient.colors,
        reason: 'Rest state must paint the wood-panel rest gradient.',
      );

      final Offset center = tester.getCenter(find.byType(CtNinePatchButton));
      final TestGesture gesture = await tester.startGesture(center);
      await tester.pump();
      await tester.pump(CtNinePatchButton.animationDuration);
      await tester.pumpAndSettle();

      final DecoratedBox pressedBox = _findButtonSurfaceDecoratedBox(tester);
      final BoxDecoration pressedDecoration =
          pressedBox.decoration as BoxDecoration;
      final LinearGradient pressedGradientPainted =
          pressedDecoration.gradient! as LinearGradient;
      expect(
        pressedGradientPainted.colors,
        CtGradients.woodPanelButtonGradientPressed.colors,
        reason:
            'Pressed-state surface must swap to the inverted wood-panel '
            'pressed gradient (bgDeep → surface → surfaceLite).',
      );

      await gesture.up();
      await tester.pumpAndSettle();

      final DecoratedBox releasedBox = _findButtonSurfaceDecoratedBox(tester);
      final BoxDecoration releasedDecoration =
          releasedBox.decoration as BoxDecoration;
      final LinearGradient releasedGradient =
          releasedDecoration.gradient! as LinearGradient;
      expect(
        releasedGradient.colors,
        CtGradients.woodPanelButtonGradient.colors,
        reason: 'Surface must revert to the rest gradient once the gesture '
            'completes (inversion is strictly transient).',
      );
    },
  );

  testWidgets(
    'when pressedGradient is omitted, pressing the button does not swap the '
    'surface gradient (default 2-stop CtGradients.buttonGradient is preserved)',
    (WidgetTester tester) async {
      // Negative AC: callers that do not opt-in (every non-main-menu
      // CtNinePatchButton) keep the prior 2-stop visual contract regardless
      // of press state.
      await _pumpButton(tester, onPressed: () {});

      final Offset center = tester.getCenter(find.byType(CtNinePatchButton));
      final TestGesture gesture = await tester.startGesture(center);
      await tester.pump();
      await tester.pump(CtNinePatchButton.animationDuration);
      await tester.pumpAndSettle();

      final DecoratedBox pressedBox = _findButtonSurfaceDecoratedBox(tester);
      final BoxDecoration pressedDecoration =
          pressedBox.decoration as BoxDecoration;
      final LinearGradient pressedGradientPainted =
          pressedDecoration.gradient! as LinearGradient;
      expect(
        pressedGradientPainted.colors,
        CtGradients.buttonGradient.colors,
        reason:
            'Without an opt-in pressedGradient, the canonical 2-stop button '
            'gradient must still paint while the button is held.',
      );

      await gesture.up();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'danger variant resolves border and engraved label to --danger',
    (WidgetTester tester) async {
      // SPEC/ui/pixel-art-ui-catalog.md § Pixel-art component catalog
      // (CtNinePatchButton) → Danger variant: border + label switch to
      // `--danger`, gradient surface and brass corner brackets unchanged.
      await _pumpButton(
        tester,
        onPressed: () {},
        dangerVariant: true,
        child: const Text('Declare War'),
      );

      final DecoratedBox box = _findButtonSurfaceDecoratedBox(tester);
      final BoxDecoration decoration = box.decoration as BoxDecoration;

      // Gradient unchanged.
      final LinearGradient gradient = decoration.gradient! as LinearGradient;
      expect(
        gradient.colors,
        CtGradients.buttonGradient.colors,
        reason: 'Danger variant must keep the canonical button gradient.',
      );

      // Border resolves to --danger (not --border).
      final Border border = decoration.border! as Border;
      expect(
        border.top.color,
        EditorialMonoclePalette.danger,
        reason: 'Danger variant must paint a --danger border.',
      );

      // Engraved label colour resolves to --danger (not --accent).
      final RichText rich = tester.widget<RichText>(
        find.descendant(
          of: find.text('Declare War'),
          matching: find.byType(RichText),
        ),
      );
      final TextSpan span = rich.text as TextSpan;
      expect(
        span.style?.color,
        EditorialMonoclePalette.danger,
        reason: 'Danger variant must paint the engraved label in --danger.',
      );
    },
  );
}
