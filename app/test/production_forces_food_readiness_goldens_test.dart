// Visual goldens for Production Available forces-food readiness (#4242).
// SPEC/ui/production-panel.md § Forces food readiness.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_forces_food_readiness_summary.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';
import 'widget_test_pumps.dart';

Future<void> _pumpForcesFoodSummaryGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required ForceFeedingSnapshot snapshot,
  bool expandDetails = false,
  Size physicalSize = const Size(440, 140),
}) async {
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: physicalSize,
    includeLocalizations: true,
    scaffoldBackgroundColor:
        AppThemes.editorialMonocle.scaffoldBackgroundColor,
    child: Builder(
      builder: (context) {
        return ProductionForcesFoodReadinessSummary(
          snapshot: snapshot,
          l10n: appL10n(context),
          theme: Theme.of(context),
        );
      },
    ),
  );
  await pumpSettleCapped(tester);
  if (expandDetails) {
    await tester.tap(
      find.byKey(const ValueKey<String>('production_forces_food_details_toggle')),
    );
    await pumpSettleCapped(tester);
  }
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'golden: armies fully fed strip without weaker copy (Refs #4242)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'production_forces_food_armies_fully_fed_golden',
      );
      final snapshot = previewForceFeeding(
        stockpile: const Stockpile().applyDelta('grain', 20),
        foodCounts: const MilitaryNavyFoodCounts(
          regimentCountsById: {'pikemen': 2},
        ),
      );

      await _pumpForcesFoodSummaryGolden(
        tester,
        boundaryKey: boundaryKey,
        snapshot: snapshot,
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.text('Armies fully fed this turn.'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/production_forces_food_armies_fully_fed.png'),
      );
    },
  );

  testWidgets(
    'golden: armies moderate underfed strip (Refs #4242)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'production_forces_food_armies_moderate_golden',
      );
      final snapshot = previewForceFeeding(
        stockpile: const Stockpile().applyDelta('grain', 4),
        foodCounts: const MilitaryNavyFoodCounts(
          regimentCountsById: {'pikemen': 3},
        ),
      );

      await _pumpForcesFoodSummaryGolden(
        tester,
        boundaryKey: boundaryKey,
        snapshot: snapshot,
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/production_forces_food_armies_moderate_underfed.png',
        ),
      );
    },
  );

  testWidgets(
    'golden: armies severe underfed strip (Refs #4242)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'production_forces_food_armies_severe_golden',
      );
      final snapshot = previewForceFeeding(
        stockpile: const Stockpile().applyDelta('grain', 2),
        foodCounts: const MilitaryNavyFoodCounts(
          regimentCountsById: {'pikemen': 3},
        ),
      );

      await _pumpForcesFoodSummaryGolden(
        tester,
        boundaryKey: boundaryKey,
        snapshot: snapshot,
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/production_forces_food_armies_severe_underfed.png',
        ),
      );
    },
  );

  testWidgets(
    'golden: fleets moderate underfed strip (Refs #4242)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'production_forces_food_fleets_moderate_golden',
      );
      final snapshot = previewForceFeeding(
        stockpile: const Stockpile().applyDelta('grain', 2),
        foodCounts: const MilitaryNavyFoodCounts(
          shipCountsById: {'carrack': 2},
        ),
      );

      await _pumpForcesFoodSummaryGolden(
        tester,
        boundaryKey: boundaryKey,
        snapshot: snapshot,
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/production_forces_food_fleets_moderate_underfed.png',
        ),
      );
    },
  );

  testWidgets(
    'golden: forces food details expanded (Refs #4242)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'production_forces_food_details_expanded_golden',
      );
      final snapshot = previewForceFeeding(
        stockpile: const Stockpile().applyDelta('grain', 4),
        foodCounts: const MilitaryNavyFoodCounts(
          regimentCountsById: {'pikemen': 3},
        ),
      );

      await _pumpForcesFoodSummaryGolden(
        tester,
        boundaryKey: boundaryKey,
        snapshot: snapshot,
        expandDetails: true,
        physicalSize: const Size(440, 260),
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.textContaining('regiments fed'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/production_forces_food_details_expanded.png',
        ),
      );
    },
  );
}
