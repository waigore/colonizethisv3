// Widget tests for the dark editorial-monocle visual contract on
// `CtNinePatchButton` (`Refs #2859` S2 / R1). Verifies the AC set:
//   - gradient background sourced from `CtGradients.buttonGradient`
//   - 1 px border, default `--border`, hover `--accent`
//   - four 10x10 brass corner brackets, default `--accent` at 0.75 alpha,
//     hover `--accent-bright` at 1.0 alpha
//   - engraved label text shadow `Offset(0, 1)` blur 0 colour `--surface`
//   - disabled wraps the button in 0.4 opacity and suppresses taps.

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_shell_harness.dart';

Future<void> _pumpButton(
  WidgetTester tester, {
  required VoidCallback? onPressed,
  bool enabled = true,
  bool dangerVariant = false,
  bool mutedVariant = false,
  double? disabledOpacityOverride,
  LinearGradient? gradient,
  LinearGradient? pressedGradient,
  Widget child = const Text('Confirm'),
}) async {
  await pumpAppShell(
    tester,
    settle: true,
    child: Scaffold(
      body: Center(
        child: SizedBox(
          width: 200,
          child: CtNinePatchButton(
            onPressed: onPressed,
            enabled: enabled,
            dangerVariant: dangerVariant,
            mutedVariant: mutedVariant,
            disabledOpacityOverride: disabledOpacityOverride,
            gradient: gradient,
            pressedGradient: pressedGradient,
            child: child,
          ),
        ),
      ),
    ),
  );
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
  expect(boxes, findsAtLeastNWidgets(1));
  return tester.widget<DecoratedBox>(boxes.first);
}

BoxDecoration _surfaceDecoration(WidgetTester tester) =>
    _findButtonSurfaceDecoratedBox(tester).decoration as BoxDecoration;

TextSpan _labelSpan(WidgetTester tester, String label) {
  final RichText rich = tester.widget<RichText>(
    find.descendant(of: find.text(label), matching: find.byType(RichText)),
  );
  return rich.text as TextSpan;
}

Finder _opacityFinder(double opacity) => find.descendant(
      of: find.byType(CtNinePatchButton),
      matching: find.byWidgetPredicate(
        (Widget w) => w is Opacity && w.opacity == opacity,
      ),
    );

void _expectGradientColors(
  WidgetTester tester,
  List<Color> colors, {
  String? reason,
}) {
  final LinearGradient gradient =
      _surfaceDecoration(tester).gradient! as LinearGradient;
  expect(gradient.colors, colors, reason: reason);
}

void _expectBorderColor(WidgetTester tester, Color color, {String? reason}) {
  final Border border = _surfaceDecoration(tester).border! as Border;
  expect(border.top.color, color, reason: reason);
}

void _expectLabelColor(
  WidgetTester tester,
  String label,
  Color color, {
  String? reason,
}) {
  expect(_labelSpan(tester, label).style?.color, color, reason: reason);
}

Future<TestGesture> _hoverOverButton(WidgetTester tester) async {
  final TestGesture gesture = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
  );
  addTearDown(gesture.removePointer);
  await gesture.addPointer(location: const Offset(1, 1));
  await tester.pumpAndSettle();
  await gesture.moveTo(tester.getCenter(find.byType(CtNinePatchButton)));
  await tester.pump();
  await tester.pump(CtNinePatchButton.animationDuration);
  await tester.pumpAndSettle();
  return gesture;
}

Future<TestGesture> _holdPress(WidgetTester tester) async {
  final TestGesture gesture = await tester.startGesture(
    tester.getCenter(find.byType(CtNinePatchButton)),
  );
  await tester.pump();
  await tester.pump(CtNinePatchButton.animationDuration);
  await tester.pumpAndSettle();
  return gesture;
}

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'default state paints buttonGradient and 1px --border border',
    (WidgetTester tester) async {
      await _pumpButton(tester, onPressed: () {});
      final BoxDecoration decoration = _surfaceDecoration(tester);
      final LinearGradient gradient = decoration.gradient! as LinearGradient;
      expect(gradient.begin, Alignment.topCenter);
      expect(gradient.end, Alignment.bottomCenter);
      expect(gradient.colors, <Color>[
        EditorialMonoclePalette.surfaceLite,
        EditorialMonoclePalette.surface,
      ]);
      expect(gradient.colors, CtGradients.buttonGradient.colors);
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
      final TestGesture gesture = await _hoverOverButton(tester);
      _expectBorderColor(tester, EditorialMonoclePalette.accent);
      await gesture.moveTo(const Offset(-50, -50));
      await tester.pumpAndSettle();
      _expectBorderColor(tester, EditorialMonoclePalette.border);
    },
  );

  testWidgets(
    'engraved label text uses a 1px downward shadow coloured from --surface',
    (WidgetTester tester) async {
      await _pumpButton(tester, onPressed: () {});
      expect(find.text('Confirm'), findsOneWidget);
      final List<Shadow>? shadows = _labelSpan(tester, 'Confirm').style?.shadows;
      expect(shadows, isNotNull);
      expect(shadows!.length, 1);
      expect(shadows.first.offset, CtNinePatchButton.engravedShadowOffset);
      expect(shadows.first.blurRadius, 0);
      expect(shadows.first.color, EditorialMonoclePalette.surface);
    },
  );

  testWidgets(
    'disabled state wraps button in 0.4 opacity and suppresses taps',
    (WidgetTester tester) async {
      int taps = 0;
      await _pumpButton(tester, onPressed: () => taps += 1, enabled: false);
      expect(_opacityFinder(CtNinePatchButton.disabledOpacity), findsOneWidget);
      expect(CtNinePatchButton.disabledOpacity, 0.4);
      await tester.tap(find.byType(CtNinePatchButton), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(taps, 0);
    },
  );

  testWidgets(
    'disabledOpacityOverride replaces the catalog 0.4 default when set '
    '(positive path — issue #2861 R1 / AC#9 next-turn button uses 0.35)',
    (WidgetTester tester) async {
      await _pumpButton(
        tester,
        onPressed: () {},
        enabled: false,
        disabledOpacityOverride: 0.35,
      );
      expect(_opacityFinder(0.35), findsOneWidget);
      expect(_opacityFinder(CtNinePatchButton.disabledOpacity), findsNothing);
    },
  );

  testWidgets(
    'disabledOpacityOverride: null preserves the catalog 0.4 default '
    '(negative / regression guard — every other CtNinePatchButton call '
    'site must keep the shared disabled convention)',
    (WidgetTester tester) async {
      await _pumpButton(tester, onPressed: () {}, enabled: false);
      expect(_opacityFinder(CtNinePatchButton.disabledOpacity), findsOneWidget);
      expect(_opacityFinder(0.35), findsNothing);
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
      expect(
        find.descendant(
          of: find.byType(CtNinePatchButton),
          matching: find.byWidgetPredicate(
            (Widget w) =>
                w is Opacity &&
                (w.opacity == 0.35 ||
                    w.opacity == CtNinePatchButton.disabledOpacity),
          ),
        ),
        findsNothing,
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
      expect(
        find.descendant(
          of: find.byType(CtNinePatchButton),
          matching: find.byWidgetPredicate(
            (Widget w) =>
                w is CustomPaint &&
                w.painter != null &&
                w.painter.runtimeType.toString() ==
                    'CtNinePatchButtonBracketsPainter',
          ),
        ),
        findsOneWidget,
      );
      expect(CtNinePatchButton.cornerBracketSize, 10);
    },
  );

  testWidgets(
    'pressedGradient swaps the surface gradient transiently while held; '
    'reverts to the rest gradient after the gesture completes',
    (WidgetTester tester) async {
      await _pumpButton(
        tester,
        onPressed: () {},
        gradient: CtGradients.woodPanelButtonGradient,
        pressedGradient: CtGradients.woodPanelButtonGradientPressed,
      );
      _expectGradientColors(
        tester,
        CtGradients.woodPanelButtonGradient.colors,
      );
      final TestGesture gesture = await _holdPress(tester);
      _expectGradientColors(
        tester,
        CtGradients.woodPanelButtonGradientPressed.colors,
      );
      await gesture.up();
      await tester.pumpAndSettle();
      _expectGradientColors(
        tester,
        CtGradients.woodPanelButtonGradient.colors,
      );
    },
  );

  testWidgets(
    'when pressedGradient is omitted, pressing the button does not swap the '
    'surface gradient (default 2-stop CtGradients.buttonGradient is preserved)',
    (WidgetTester tester) async {
      await _pumpButton(tester, onPressed: () {});
      final TestGesture gesture = await _holdPress(tester);
      _expectGradientColors(tester, CtGradients.buttonGradient.colors);
      await gesture.up();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'danger variant resolves border and engraved label to --danger',
    (WidgetTester tester) async {
      await _pumpButton(
        tester,
        onPressed: () {},
        dangerVariant: true,
        child: const Text('Declare War'),
      );
      _expectGradientColors(tester, CtGradients.buttonGradient.colors);
      _expectBorderColor(tester, EditorialMonoclePalette.danger);
      _expectLabelColor(tester, 'Declare War', EditorialMonoclePalette.danger);
    },
  );

  testWidgets(
    'muted variant resolves idle border to --accent-dim and idle label to '
    '--muted (positive — issue #2867 R26b)',
    (WidgetTester tester) async {
      await _pumpButton(
        tester,
        onPressed: () {},
        mutedVariant: true,
        child: const Text('Do naught'),
      );
      _expectBorderColor(tester, EditorialMonoclePalette.accentDim);
      expect(
        (_surfaceDecoration(tester).border! as Border).top.color,
        isNot(EditorialMonoclePalette.border),
      );
      _expectLabelColor(tester, 'Do naught', EditorialMonoclePalette.muted);
      _expectGradientColors(tester, CtGradients.buttonGradient.colors);
    },
  );

  testWidgets(
    'muted variant lifts border + label to --accent on hover '
    '(positive — issue #2867 R26b)',
    (WidgetTester tester) async {
      await _pumpButton(
        tester,
        onPressed: () {},
        mutedVariant: true,
        child: const Text('Diplomatic protest'),
      );
      await _hoverOverButton(tester);
      _expectBorderColor(tester, EditorialMonoclePalette.accent);
      _expectLabelColor(
        tester,
        'Diplomatic protest',
        EditorialMonoclePalette.accent,
      );
      expect(
        _labelSpan(tester, 'Diplomatic protest').style?.color,
        isNot(EditorialMonoclePalette.accentBright),
      );
    },
  );

  testWidgets(
    'mutedVariant + dangerVariant: dangerVariant wins (negative — issue '
    '#2867 R26b mutual-exclusivity contract)',
    (WidgetTester tester) async {
      await _pumpButton(
        tester,
        onPressed: () {},
        dangerVariant: true,
        mutedVariant: true,
        child: const Text('Declare War'),
      );
      _expectBorderColor(tester, EditorialMonoclePalette.danger);
      expect(
        (_surfaceDecoration(tester).border! as Border).top.color,
        isNot(EditorialMonoclePalette.accentDim),
      );
      _expectLabelColor(tester, 'Declare War', EditorialMonoclePalette.danger);
    },
  );

  testWidgets(
    'default (no muted, no danger) keeps --border idle border and --accent '
    'idle label (negative regression guard for muted variant introduction)',
    (WidgetTester tester) async {
      await _pumpButton(tester, onPressed: () {});
      _expectBorderColor(tester, EditorialMonoclePalette.border);
      expect(
        (_surfaceDecoration(tester).border! as Border).top.color,
        isNot(EditorialMonoclePalette.accentDim),
      );
      _expectLabelColor(tester, 'Confirm', EditorialMonoclePalette.accent);
      expect(
        _labelSpan(tester, 'Confirm').style?.color,
        isNot(EditorialMonoclePalette.muted),
      );
    },
  );

  test(
    'mutedCornerAlphaScale halves the bracket alpha (canonical 0.5 scale; '
    '#2867 R26b — keeps brackets visible at narrow viewports while reading '
    'as half-strength against a sibling primary)',
    () {
      expect(CtNinePatchButton.mutedCornerAlphaScale, 0.5);
      expect(
        CtNinePatchButton.defaultCornerAlpha *
            CtNinePatchButton.mutedCornerAlphaScale,
        closeTo(0.375, 1e-9),
      );
      expect(
        CtNinePatchButton.hoverCornerAlpha *
            CtNinePatchButton.mutedCornerAlphaScale,
        closeTo(0.5, 1e-9),
      );
    },
  );
}
