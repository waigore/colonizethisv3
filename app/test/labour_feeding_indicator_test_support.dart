// Shared labour/feeding indicator fixtures for widget tests (Refs #4506).

import 'package:colonizethis_app/features/game/widgets/shell/game_tab_bar.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:flutter/material.dart';

import 'app_shell_harness.dart';

const LabourReadinessSnapshot labourFeedingFullLabour = LabourReadinessSnapshot(
  effectiveLabour: 20,
  fullCapacity: 20,
  tierStatuses: [],
);

const LabourReadinessSnapshot labourFeedingReducedLabour =
    LabourReadinessSnapshot(
      effectiveLabour: 12,
      fullCapacity: 20,
      tierStatuses: [],
      primaryCauseKind: LabourReadinessCauseKind.food,
    );

const LabourReadinessSnapshot labourFeedingZeroLabour = LabourReadinessSnapshot(
  effectiveLabour: 0,
  fullCapacity: 20,
  tierStatuses: [],
  primaryCauseKind: LabourReadinessCauseKind.food,
);

const LabourReadinessSnapshot labourFeedingEmptyPoolLabour =
    LabourReadinessSnapshot(
      effectiveLabour: 0,
      fullCapacity: 0,
      tierStatuses: [],
    );

const ForceFeedingSnapshot labourFeedingFullyFedForces = ForceFeedingSnapshot(
  totalRegiments: 0,
  fullyFedRegiments: 0,
  totalShips: 0,
  fullyFedShips: 0,
  landCombatTier: ForceFeedingCombatTier.full,
  navalCombatTier: ForceFeedingCombatTier.full,
  forcesFoodDemand: 0,
);

const ForceFeedingSnapshot labourFeedingUnderfedLandForces =
    ForceFeedingSnapshot(
      totalRegiments: 4,
      fullyFedRegiments: 1,
      totalShips: 0,
      fullyFedShips: 0,
      landCombatTier: ForceFeedingCombatTier.severe,
      navalCombatTier: ForceFeedingCombatTier.full,
      forcesFoodDemand: 8,
    );

Widget labourFeedingHost({
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
