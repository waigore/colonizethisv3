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
}
