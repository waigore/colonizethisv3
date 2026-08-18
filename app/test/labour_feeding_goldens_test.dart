// Widget golden coverage for shell labour/feeding indicator (Refs #4506).
//
// Pins colour tiers and details panel copy per SPEC/ui/empire-overview.md
// § Labour and feeding indicator.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kLabourFeedingIndicatorKey;
import 'package:colonizethis_app/features/game/widgets/shell/game_tab_bar.dart';
import 'package:colonizethis_app/features/game/widgets/shell/game_tab_bar_indicators.dart';
import 'package:colonizethis_app/features/game/widgets/shell/labour_feeding_indicator_support.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';
import 'widget_test_pumps.dart';

const Size _indicatorViewport = Size(160, 48);

TextStyle _monoLabelStyle(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  return (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
    fontFamily: 'monospace',
    fontSize: 11,
    height: 1.0,
  );
}

Future<void> _pumpLabourIndicatorGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required LabourReadinessSnapshot labourReadiness,
  required ForceFeedingSnapshot forcesFeeding,
  required String label,
}) async {
  final Color numericColor = labourFeedingNumericColor(
    labourReadiness: labourReadiness,
    forcesFeeding: forcesFeeding,
    notDefined: false,
  );
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: _indicatorViewport,
    includeLocalizations: true,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    center: false,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: EditorialMonoclePalette.surface,
        border: Border(
          bottom: BorderSide(color: EditorialMonoclePalette.border),
        ),
      ),
      child: SizedBox(
        height: GameTabBar.height,
        child: Builder(
          builder: (BuildContext context) {
            return GameTabBarLabourFeedingIndicator(
              labourFeedingLabel: label,
              labelStyle: _monoLabelStyle(context),
              numericColor: numericColor,
            );
          },
        ),
      ),
    ),
  );
  await pumpSettleCapped(tester);
}

void main() {
  suppressLogsForTests();

  testWidgets('golden: labour full capacity muted tier (Refs #4506)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>(
      'labour_feeding_indicator_full_golden',
    );
    await _pumpLabourIndicatorGolden(
      tester,
      boundaryKey: boundaryKey,
      labourReadiness: const LabourReadinessSnapshot(
        effectiveLabour: 20,
        fullCapacity: 20,
        tierStatuses: [],
      ),
      forcesFeeding: const ForceFeedingSnapshot(
        totalRegiments: 0,
        fullyFedRegiments: 0,
        totalShips: 0,
        fullyFedShips: 0,
        landCombatTier: ForceFeedingCombatTier.full,
        navalCombatTier: ForceFeedingCombatTier.full,
        forcesFoodDemand: 0,
      ),
      label: '20/20',
    );

    expect(tester.takeException(), isNull);
    expect(find.text('20/20'), findsOneWidget);
    expectEditorialMonocleDarkChrome(tester);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/labour_feeding_indicator_full.png'),
    );
  });

  testWidgets('golden: reduced labour accent tier (Refs #4506)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>(
      'labour_feeding_indicator_reduced_golden',
    );
    await _pumpLabourIndicatorGolden(
      tester,
      boundaryKey: boundaryKey,
      labourReadiness: const LabourReadinessSnapshot(
        effectiveLabour: 12,
        fullCapacity: 20,
        tierStatuses: [],
        primaryCauseKind: LabourReadinessCauseKind.food,
      ),
      forcesFeeding: const ForceFeedingSnapshot(
        totalRegiments: 0,
        fullyFedRegiments: 0,
        totalShips: 0,
        fullyFedShips: 0,
        landCombatTier: ForceFeedingCombatTier.full,
        navalCombatTier: ForceFeedingCombatTier.full,
        forcesFoodDemand: 0,
      ),
      label: '12/20',
    );

    expect(tester.takeException(), isNull);
    expect(find.text('12/20'), findsOneWidget);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/labour_feeding_indicator_reduced.png'),
    );
  });

  testWidgets('golden: underfed forces danger tier (Refs #4506)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>(
      'labour_feeding_indicator_underfed_golden',
    );
    await _pumpLabourIndicatorGolden(
      tester,
      boundaryKey: boundaryKey,
      labourReadiness: const LabourReadinessSnapshot(
        effectiveLabour: 20,
        fullCapacity: 20,
        tierStatuses: [],
      ),
      forcesFeeding: const ForceFeedingSnapshot(
        totalRegiments: 4,
        fullyFedRegiments: 1,
        totalShips: 0,
        fullyFedShips: 0,
        landCombatTier: ForceFeedingCombatTier.severe,
        navalCombatTier: ForceFeedingCombatTier.full,
        forcesFoodDemand: 8,
      ),
      label: '20/20',
    );

    expect(tester.takeException(), isNull);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/labour_feeding_indicator_underfed.png'),
    );
  });

  testWidgets('golden: empty pool muted 0/0 (Refs #4506)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>(
      'labour_feeding_indicator_empty_pool_golden',
    );
    await _pumpLabourIndicatorGolden(
      tester,
      boundaryKey: boundaryKey,
      labourReadiness: const LabourReadinessSnapshot(
        effectiveLabour: 0,
        fullCapacity: 0,
        tierStatuses: [],
      ),
      forcesFeeding: const ForceFeedingSnapshot(
        totalRegiments: 0,
        fullyFedRegiments: 0,
        totalShips: 0,
        fullyFedShips: 0,
        landCombatTier: ForceFeedingCombatTier.full,
        navalCombatTier: ForceFeedingCombatTier.full,
        forcesFoodDemand: 0,
      ),
      label: '0/0',
    );

    expect(tester.takeException(), isNull);
    expect(find.text('0/0'), findsOneWidget);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/labour_feeding_indicator_empty_pool.png'),
    );
  });
}
