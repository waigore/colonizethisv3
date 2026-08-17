// Widget tests for map-shell labour/feeding indicator (Refs #4506).
// SPEC: SPEC/ui/empire-overview.md § Labour and feeding indicator.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show
        kGameMapNextTurnButtonKey,
        kLabourFeedingIndicatorKey;
import 'package:colonizethis_app/features/game/widgets/shell/game_tab_bar.dart';
import 'package:colonizethis_app/features/game/widgets/shell/game_top_bar.dart';
import 'package:colonizethis_app/features/game/widgets/shell/labour_feeding_indicator_support.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

const LabourReadinessSnapshot _fullLabour = LabourReadinessSnapshot(
  effectiveLabour: 20,
  fullCapacity: 20,
  tierStatuses: [],
);

const LabourReadinessSnapshot _reducedLabour = LabourReadinessSnapshot(
  effectiveLabour: 12,
  fullCapacity: 20,
  tierStatuses: [],
  primaryCauseKind: LabourReadinessCauseKind.food,
);

const LabourReadinessSnapshot _zeroLabour = LabourReadinessSnapshot(
  effectiveLabour: 0,
  fullCapacity: 20,
  tierStatuses: [],
  primaryCauseKind: LabourReadinessCauseKind.food,
);

const ForceFeedingSnapshot _fullyFedForces = ForceFeedingSnapshot(
  totalRegiments: 0,
  fullyFedRegiments: 0,
  totalShips: 0,
  fullyFedShips: 0,
  landCombatTier: ForceFeedingCombatTier.full,
  navalCombatTier: ForceFeedingCombatTier.full,
  forcesFoodDemand: 0,
);

const ForceFeedingSnapshot _underfedLandForces = ForceFeedingSnapshot(
  totalRegiments: 4,
  fullyFedRegiments: 1,
  totalShips: 0,
  fullyFedShips: 0,
  landCombatTier: ForceFeedingCombatTier.severe,
  navalCombatTier: ForceFeedingCombatTier.full,
  forcesFoodDemand: 8,
);

Widget _host({
  required LabourReadinessSnapshot labourReadiness,
  required ForceFeedingSnapshot forcesFeeding,
  bool showLabourFeedingIndicator = true,
  bool labourFeedingNotDefined = false,
  String labourFeedingLabel = '12/20',
  double width = 600,
}) {
  return buildAppShell(
    child: Scaffold(
      body: SizedBox(
        width: width,
        height: 120,
        child: GameTabBar(
          regionIndex: 0,
          onRegionIndexChanged: (_) {},
          oldWorldLabel: 'Old World',
          newWorldLabel: 'New World',
          treasury: 100,
          treasuryDelta: null,
          treasuryNotDefined: false,
          cargoUsed: 3,
          cargoCapacity: 12,
          cargoNotDefined: false,
          isCargoUsedReliable: true,
          cargoHoldLabel: '3/12',
          showLabourFeedingIndicator: showLabourFeedingIndicator,
          labourFeedingLabel: labourFeedingLabel,
          labourFeedingNotDefined: labourFeedingNotDefined,
          labourReadiness: labourReadiness,
          forcesFeeding: forcesFeeding,
          trailing: const SizedBox(width: 32, height: 32),
        ),
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  group('labourFeedingNumericColor (Refs #4506)', () {
    test('full capacity and fully fed forces resolve muted', () {
      expect(
        labourFeedingNumericColor(
          labourReadiness: _fullLabour,
          forcesFeeding: _fullyFedForces,
          notDefined: false,
        ),
        EditorialMonoclePalette.muted,
      );
    });

    test('reduced labour resolves accent', () {
      expect(
        labourFeedingNumericColor(
          labourReadiness: _reducedLabour,
          forcesFeeding: _fullyFedForces,
          notDefined: false,
        ),
        EditorialMonoclePalette.accent,
      );
    });

    test('zero labour with non-empty pool resolves danger', () {
      expect(
        labourFeedingNumericColor(
          labourReadiness: _zeroLabour,
          forcesFeeding: _fullyFedForces,
          notDefined: false,
        ),
        EditorialMonoclePalette.danger,
      );
    });

    test('underfed forces resolve danger even at full labour', () {
      expect(
        labourFeedingNumericColor(
          labourReadiness: _fullLabour,
          forcesFeeding: _underfedLandForces,
          notDefined: false,
        ),
        EditorialMonoclePalette.danger,
      );
    });
  });

  testWidgets('shows labour fraction when indicator enabled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        labourReadiness: _reducedLabour,
        forcesFeeding: _fullyFedForces,
        labourFeedingLabel: '12/20',
      ),
    );
    await tester.pump();

    expect(find.byKey(kLabourFeedingIndicatorKey), findsOneWidget);
    expect(find.text('12/20'), findsOneWidget);
  });

  testWidgets('hides indicator when showLabourFeedingIndicator is false', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        labourReadiness: _fullLabour,
        forcesFeeding: _fullyFedForces,
        showLabourFeedingIndicator: false,
      ),
    );
    await tester.pump();

    expect(find.byKey(kLabourFeedingIndicatorKey), findsNothing);
  });

  testWidgets('tap opens details with primary shortage reason', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        labourReadiness: _reducedLabour,
        forcesFeeding: _fullyFedForces,
        labourFeedingLabel: '12/20',
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(kLabourFeedingIndicatorKey));
    await tester.pumpAndSettle();

    expect(find.byKey(kLabourFeedingDetailsPanelKey), findsOneWidget);
    expect(find.textContaining('Labour this turn: 12 of 20'), findsOneWidget);
    expect(
      find.textContaining('Some workers are not working — food is short'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Armies and fleets eat before workers'),
      findsOneWidget,
    );
  });

  testWidgets('observe not-defined label is not tappable', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        labourReadiness: _fullLabour,
        forcesFeeding: _fullyFedForces,
        labourFeedingNotDefined: true,
        labourFeedingLabel: '—',
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(kLabourFeedingIndicatorKey));
    await tester.pumpAndSettle();

    expect(find.byKey(kLabourFeedingDetailsPanelKey), findsNothing);
  });

  testWidgets('narrow viewport: labour panel leaves Next turn tappable', (
    WidgetTester tester,
  ) async {
    var nextTurnTaps = 0;
    await tester.pumpWidget(
      buildAppShell(
        child: Scaffold(
          body: SizedBox(
            width: kMinViewportWidth,
            height: 120,
            child: Column(
              children: [
                GameTopBar(
                  onToggleSideMenu: () {},
                  onPausePressed: () {},
                  onNextTurn: () async => nextTurnTaps++,
                  nextTurnEnabled: true,
                  turnDisplayText: 'Turn 1',
                  nextTurnText: 'Next turn',
                  menuTooltip: 'Menu',
                  pauseTooltip: 'Pause',
                ),
                GameTabBar(
                  regionIndex: 0,
                  onRegionIndexChanged: (_) {},
                  oldWorldLabel: 'Old World',
                  newWorldLabel: 'New World',
                  treasury: 100,
                  treasuryDelta: null,
                  treasuryNotDefined: false,
                  cargoUsed: 3,
                  cargoCapacity: 12,
                  cargoNotDefined: false,
                  isCargoUsedReliable: true,
                  cargoHoldLabel: '3/12',
                  showLabourFeedingIndicator: true,
                  labourFeedingLabel: '0/20',
                  labourReadiness: _zeroLabour,
                  forcesFeeding: _underfedLandForces,
                  trailing: const SizedBox(width: 24, height: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(kLabourFeedingIndicatorKey));
    await tester.pumpAndSettle();
    expect(find.byKey(kLabourFeedingDetailsPanelKey), findsOneWidget);

    await tester.tap(find.byKey(kGameMapNextTurnButtonKey));
    await tester.pump();
    expect(nextTurnTaps, 1);
  });
}
