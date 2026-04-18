// Tests for allocation step buttons. SPEC/ui/production-panel.md.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/production_allocation_repeat_timing.dart';
import 'package:colonizethis_app/features/game/widgets/production_allocation_row_buttons.dart';

import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  testWidgets('ProductionAllocationStepButton long-press repeats', (
    WidgetTester tester,
  ) async {
    final map = <String, int>{};
    var last = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ProductionAllocationStepButton(
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
}
