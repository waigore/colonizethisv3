// Tests for allocation step buttons. SPEC/ui/production-panel.md.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/production_allocation_repeat_timing.dart';
import 'package:colonizethis_app/features/game/widgets/production_allocation_row_buttons.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';

import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  Widget harness(Widget child) =>
      MaterialApp(home: Scaffold(body: Center(child: child)));

  ({SizedBox box, DecoratedBox surface, Opacity opacity}) resolveSurface(
    WidgetTester tester,
    Finder buttonFinder,
  ) {
    final sized = tester.widget<SizedBox>(
      find
          .descendant(
            of: buttonFinder,
            matching: find.byWidgetPredicate(
              (w) =>
                  w is SizedBox &&
                  w.width == kProductionAllocationStepButtonSize &&
                  w.height == kProductionAllocationStepButtonSize,
            ),
          )
          .first,
    );
    final decorated = tester.widget<DecoratedBox>(
      find.descendant(of: buttonFinder, matching: find.byType(DecoratedBox)).first,
    );
    final opacity = tester.widget<Opacity>(
      find.descendant(of: buttonFinder, matching: find.byType(Opacity)).first,
    );
    return (box: sized, surface: decorated, opacity: opacity);
  }

  testWidgets('ProductionAllocationStepButton long-press repeats', (
    WidgetTester tester,
  ) async {
    final map = <String, int>{};
    var last = 0;
    await tester.pumpWidget(
      harness(
        ProductionAllocationStepButton(
          enabled: true,
          readDesired: () => map,
          tryStepFromCurrent: (_) {
            last += 1;
            map['k'] = (map['k'] ?? 0) + 1;
            return true;
          },
          semanticLabel: 'step',
          tooltip: 'step',
          assetFileName: 'ui_icon_production_alloc_increment.png',
        ),
      ),
    );
    await pumpSettleCapped(tester);

    final finder = find.byType(ProductionAllocationStepButton);
    final gesture = await tester.startGesture(tester.getCenter(finder));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(kProductionAllocationRepeatInitialDelay);
    await tester.pump(kProductionAllocationRepeatInterval);
    await tester.pump(kProductionAllocationRepeatInterval);
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 16));

    expect(last, greaterThanOrEqualTo(3));
    expect(map['k'], greaterThanOrEqualTo(3));
  });

  group('Dark editorial-monocle step-button surface (Refs #2862 S3 / R14)', () {
    testWidgets(
      'Enabled stepper renders a 26x26 surface with buttonGradient + '
      'border 1px and full opacity',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          harness(
            ProductionAllocationStepButton(
              enabled: true,
              readDesired: () => const <String, int>{},
              tryStepFromCurrent: (_) => true,
              semanticLabel: 'step',
              tooltip: 'step',
              assetFileName: 'ui_icon_production_alloc_increment.png',
            ),
          ),
        );
        await pumpSettleCapped(tester);

        final s = resolveSurface(
          tester,
          find.byType(ProductionAllocationStepButton),
        );
        expect(s.box.width, kProductionAllocationStepButtonSize);
        expect(s.box.height, kProductionAllocationStepButtonSize);
        final decoration = s.surface.decoration as BoxDecoration;
        expect(decoration.gradient, CtGradients.buttonGradient);
        final border = decoration.border as Border;
        expect(border.top.color, EditorialMonoclePalette.border);
        expect(border.top.width, 1.0);
        expect(s.opacity.opacity, 1.0);
      },
    );

    testWidgets(
      'Disabled stepper renders the 26x26 surface at 0.3 opacity',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          harness(
            ProductionAllocationStepButton(
              enabled: false,
              readDesired: () => const <String, int>{},
              tryStepFromCurrent: (_) => true,
              semanticLabel: 'step',
              tooltip: 'step',
              assetFileName: 'ui_icon_production_alloc_decrement.png',
            ),
          ),
        );
        await pumpSettleCapped(tester);

        final s = resolveSurface(
          tester,
          find.byType(ProductionAllocationStepButton),
        );
        expect(s.box.width, kProductionAllocationStepButtonSize);
        expect(s.box.height, kProductionAllocationStepButtonSize);
        expect(
          s.opacity.opacity,
          kProductionAllocationStepButtonDisabledOpacity,
        );
      },
    );

    testWidgets(
      'Enabled action-icon button renders a 26x26 buttonGradient surface '
      'at full opacity',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          harness(
            ProductionAllocationActionIconButton(
              enabled: true,
              readDesired: () => const <String, int>{},
              onPressedFromCurrent: (_) {},
              semanticLabel: 'max',
              tooltip: 'max',
              assetFileName: 'ui_icon_production_alloc_maximize.png',
            ),
          ),
        );
        await pumpSettleCapped(tester);

        final s = resolveSurface(
          tester,
          find.byType(ProductionAllocationActionIconButton),
        );
        expect(s.box.width, kProductionAllocationStepButtonSize);
        expect(s.box.height, kProductionAllocationStepButtonSize);
        final decoration = s.surface.decoration as BoxDecoration;
        expect(decoration.gradient, CtGradients.buttonGradient);
        expect(s.opacity.opacity, 1.0);
      },
    );

    testWidgets(
      'Disabled action-icon button renders the 26x26 surface at 0.3 opacity',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          harness(
            ProductionAllocationActionIconButton(
              enabled: false,
              readDesired: () => const <String, int>{},
              onPressedFromCurrent: (_) {},
              semanticLabel: 'clear',
              tooltip: 'clear',
              assetFileName: 'ui_icon_production_alloc_clear.png',
            ),
          ),
        );
        await pumpSettleCapped(tester);

        final s = resolveSurface(
          tester,
          find.byType(ProductionAllocationActionIconButton),
        );
        expect(
          s.opacity.opacity,
          kProductionAllocationStepButtonDisabledOpacity,
        );
      },
    );
  });
}
