// Trailing-cluster layout ACs for the in-game shell tab bar
// (issue #2861 S2 / #4720 Slice G).

import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kCargoHoldIndicatorKey, kTreasuryIndicatorKey;
import 'package:colonizethis_app/features/game/widgets/shell/game_tab_bar.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'game_tab_bar_test_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets('M1: region tabs start-aligned; treasury -> cargo -> news toggle '
      'end-aligned in order', (WidgetTester tester) async {
    const Key trailingKey = Key('test_trailing');
    await tester.pumpWidget(
      hostGameTabBar(
        treasuryDelta: 250,
        trailing: const SizedBox(key: trailingKey, width: 28, height: 22),
      ),
    );
    await tester.pump();

    final double oldWorldX = tester.getCenter(find.text('Old World')).dx;
    final double treasuryX = tester
        .getCenter(find.byKey(kTreasuryIndicatorKey))
        .dx;
    final double cargoX = tester
        .getCenter(find.byKey(kCargoHoldIndicatorKey))
        .dx;
    final double trailingX = tester.getCenter(find.byKey(trailingKey)).dx;

    expect(
      oldWorldX,
      lessThan(treasuryX),
      reason: 'Region tabs are start-aligned, left of the trailing group.',
    );
    expect(
      treasuryX,
      lessThan(cargoX),
      reason: 'Treasury precedes cargo in the trailing group.',
    );
    expect(
      cargoX,
      lessThan(trailingX),
      reason: 'Cargo precedes the news toggle in the trailing group.',
    );
  });

  testWidgets(
    'M1/M3: news toggle has a 4 dp leading gap from the cargo hold indicator',
    (WidgetTester tester) async {
      const Key trailingKey = Key('test_trailing');
      await tester.pumpWidget(
        hostGameTabBar(
          trailing: const SizedBox(key: trailingKey, width: 28, height: 22),
        ),
      );
      await tester.pump();

      final double cargoRight = tester
          .getTopRight(find.byKey(kCargoHoldIndicatorKey))
          .dx;
      final double trailingLeft = tester.getTopLeft(find.byKey(trailingKey)).dx;
      expect(
        trailingLeft - cargoRight,
        moreOrLessEquals(GameTabBar.clusterTrailingGap, epsilon: 0.5),
      );
    },
  );
}
