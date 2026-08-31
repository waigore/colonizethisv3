import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ct_nine_patch_button_dark_test_support.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('default state paints buttonGradient and 1px --border border', (
    WidgetTester tester,
  ) async {
    await pumpNinePatchButton(tester, onPressed: () {});
    final BoxDecoration decoration = ninePatchButtonSurfaceDecoration(tester);
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
  });

  testWidgets('hover brightens corner brackets and shifts border to --accent', (
    WidgetTester tester,
  ) async {
    await pumpNinePatchButton(tester, onPressed: () {});
    final TestGesture gesture = await hoverOverNinePatchButton(tester);
    expectNinePatchBorderColor(tester, EditorialMonoclePalette.accent);
    await gesture.moveTo(const Offset(-50, -50));
    await tester.pumpAndSettle();
    expectNinePatchBorderColor(tester, EditorialMonoclePalette.border);
  });

  testWidgets(
    'engraved label text uses a 1px downward shadow coloured from --surface',
    (WidgetTester tester) async {
      await pumpNinePatchButton(tester, onPressed: () {});
      expect(find.text('Confirm'), findsOneWidget);
      final List<Shadow>? shadows = ninePatchButtonLabelSpan(
        tester,
        'Confirm',
      ).style?.shadows;
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
      await pumpNinePatchButton(
        tester,
        onPressed: () => taps += 1,
        enabled: false,
      );
      expect(
        ninePatchButtonOpacityFinder(CtNinePatchButton.disabledOpacity),
        findsOneWidget,
      );
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
      await pumpNinePatchButton(
        tester,
        onPressed: () {},
        enabled: false,
        disabledOpacityOverride: 0.35,
      );
      expect(ninePatchButtonOpacityFinder(0.35), findsOneWidget);
      expect(
        ninePatchButtonOpacityFinder(CtNinePatchButton.disabledOpacity),
        findsNothing,
      );
    },
  );

  testWidgets('disabledOpacityOverride: null preserves the catalog 0.4 default '
      '(negative / regression guard — every other CtNinePatchButton call '
      'site must keep the shared disabled convention)', (
    WidgetTester tester,
  ) async {
    await pumpNinePatchButton(tester, onPressed: () {}, enabled: false);
    expect(
      ninePatchButtonOpacityFinder(CtNinePatchButton.disabledOpacity),
      findsOneWidget,
    );
    expect(ninePatchButtonOpacityFinder(0.35), findsNothing);
  });

  testWidgets(
    'enabled state with disabledOpacityOverride does not apply any Opacity '
    'wrapper (the override only takes effect when the button is disabled)',
    (WidgetTester tester) async {
      await pumpNinePatchButton(
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

  testWidgets('enabled state with non-null onPressed fires callback on tap', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    await pumpNinePatchButton(tester, onPressed: () => taps += 1);
    await tester.tap(find.byType(CtNinePatchButton));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('four brass corner brackets are painted via CustomPaint', (
    WidgetTester tester,
  ) async {
    await pumpNinePatchButton(tester, onPressed: () {});
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
  });

  testWidgets(
    'pressedGradient swaps the surface gradient transiently while held; '
    'reverts to the rest gradient after the gesture completes',
    (WidgetTester tester) async {
      await pumpNinePatchButton(
        tester,
        onPressed: () {},
        gradient: CtGradients.woodPanelButtonGradient,
        pressedGradient: CtGradients.woodPanelButtonGradientPressed,
      );
      expectNinePatchGradientColors(
        tester,
        CtGradients.woodPanelButtonGradient.colors,
      );
      final TestGesture gesture = await holdNinePatchButtonPress(tester);
      expectNinePatchGradientColors(
        tester,
        CtGradients.woodPanelButtonGradientPressed.colors,
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expectNinePatchGradientColors(
        tester,
        CtGradients.woodPanelButtonGradient.colors,
      );
    },
  );

  testWidgets(
    'when pressedGradient is omitted, pressing the button does not swap the '
    'surface gradient (default 2-stop CtGradients.buttonGradient is preserved)',
    (WidgetTester tester) async {
      await pumpNinePatchButton(tester, onPressed: () {});
      final TestGesture gesture = await holdNinePatchButtonPress(tester);
      expectNinePatchGradientColors(tester, CtGradients.buttonGradient.colors);
      await gesture.up();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('danger variant resolves border and engraved label to --danger', (
    WidgetTester tester,
  ) async {
    await pumpNinePatchButton(
      tester,
      onPressed: () {},
      dangerVariant: true,
      child: const Text('Declare War'),
    );
    expectNinePatchGradientColors(tester, CtGradients.buttonGradient.colors);
    expectNinePatchBorderColor(tester, EditorialMonoclePalette.danger);
    expectNinePatchLabelColor(
      tester,
      'Declare War',
      EditorialMonoclePalette.danger,
    );
  });

  testWidgets(
    'muted variant resolves idle border to --accent-dim and idle label to '
    '--muted (positive — issue #2867 R26b)',
    (WidgetTester tester) async {
      await pumpNinePatchButton(
        tester,
        onPressed: () {},
        mutedVariant: true,
        child: const Text('Do naught'),
      );
      expectNinePatchBorderColor(tester, EditorialMonoclePalette.accentDim);
      expect(
        (ninePatchButtonSurfaceDecoration(tester).border! as Border).top.color,
        isNot(EditorialMonoclePalette.border),
      );
      expectNinePatchLabelColor(
        tester,
        'Do naught',
        EditorialMonoclePalette.muted,
      );
      expectNinePatchGradientColors(tester, CtGradients.buttonGradient.colors);
    },
  );

  testWidgets('muted variant lifts border + label to --accent on hover '
      '(positive — issue #2867 R26b)', (WidgetTester tester) async {
    await pumpNinePatchButton(
      tester,
      onPressed: () {},
      mutedVariant: true,
      child: const Text('Diplomatic protest'),
    );
    await hoverOverNinePatchButton(tester);
    expectNinePatchBorderColor(tester, EditorialMonoclePalette.accent);
    expectNinePatchLabelColor(
      tester,
      'Diplomatic protest',
      EditorialMonoclePalette.accent,
    );
    expect(
      ninePatchButtonLabelSpan(tester, 'Diplomatic protest').style?.color,
      isNot(EditorialMonoclePalette.accentBright),
    );
  });

  testWidgets(
    'mutedVariant + dangerVariant: dangerVariant wins (negative — issue '
    '#2867 R26b mutual-exclusivity contract)',
    (WidgetTester tester) async {
      await pumpNinePatchButton(
        tester,
        onPressed: () {},
        dangerVariant: true,
        mutedVariant: true,
        child: const Text('Declare War'),
      );
      expectNinePatchBorderColor(tester, EditorialMonoclePalette.danger);
      expect(
        (ninePatchButtonSurfaceDecoration(tester).border! as Border).top.color,
        isNot(EditorialMonoclePalette.accentDim),
      );
      expectNinePatchLabelColor(
        tester,
        'Declare War',
        EditorialMonoclePalette.danger,
      );
    },
  );

  testWidgets(
    'default (no muted, no danger) keeps --border idle border and --accent '
    'idle label (negative regression guard for muted variant introduction)',
    (WidgetTester tester) async {
      await pumpNinePatchButton(tester, onPressed: () {});
      expectNinePatchBorderColor(tester, EditorialMonoclePalette.border);
      expect(
        (ninePatchButtonSurfaceDecoration(tester).border! as Border).top.color,
        isNot(EditorialMonoclePalette.accentDim),
      );
      expectNinePatchLabelColor(
        tester,
        'Confirm',
        EditorialMonoclePalette.accent,
      );
      expect(
        ninePatchButtonLabelSpan(tester, 'Confirm').style?.color,
        isNot(EditorialMonoclePalette.muted),
      );
    },
  );

  test('mutedCornerAlphaScale halves the bracket alpha (canonical 0.5 scale; '
      '#2867 R26b — keeps brackets visible at narrow viewports while reading '
      'as half-strength against a sibling primary)', () {
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
  });
}
