// Compact build-order treasury no-bypass guard assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'build_order_treasury_no_bypass_fixtures.dart';

/// Pins for [buildOrderTreasuryNoBypassScenarios] rows.
enum BuildOrderTreasuryNoBypassTarget {
  cheapestRegimentFixturePin,
  aiBelowTreasuryRejected,
  aiAtTreasuryAccepted,
  humanZeroTreasuryRejected,
  playerAgnosticZeroTreasury,
}

void runBuildOrderTreasuryNoBypassExpectation(
  BuildOrderTreasuryNoBypassTarget target,
) {
  switch (target) {
    case BuildOrderTreasuryNoBypassTarget.cheapestRegimentFixturePin:
      final cheapest = buildOrderTreasuryNoBypassCheapest;
      expect(cheapest.id, 'peasant_levies');
      expect(cheapest.buildTreasuryCost, cheapestRegimentBuildTreasuryCost());
      expect(
        unlockingTechByRegimentId[cheapest.id],
        isNull,
        reason:
            'peasant_levies must be buildable without tech so treasury is '
            'the sole gate exercised by these guards',
      );

    case BuildOrderTreasuryNoBypassTarget.aiBelowTreasuryRejected:
      final game = buildOrderTreasuryNoBypassGame(
        treasury: buildOrderTreasuryNoBypassCheapest.buildTreasuryCost - 1,
        isHuman: false,
      );
      final result = validateBuildOrderTreasuryNoBypassRegiment(game);
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Insufficient treasury');

    case BuildOrderTreasuryNoBypassTarget.aiAtTreasuryAccepted:
      final game = buildOrderTreasuryNoBypassGame(
        treasury: buildOrderTreasuryNoBypassCheapest.buildTreasuryCost,
        isHuman: false,
      );
      final result = validateBuildOrderTreasuryNoBypassRegiment(game);
      expect(
        result.status,
        OrderValidationStatus.accepted,
        reason:
            'with materials/worker/spawn satisfied, crossing the '
            'treasury threshold must restore the unchanged build pipeline',
      );

    case BuildOrderTreasuryNoBypassTarget.humanZeroTreasuryRejected:
      final game = buildOrderTreasuryNoBypassGame(treasury: 0, isHuman: true);
      final result = validateBuildOrderTreasuryNoBypassRegiment(game);
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Insufficient treasury');

    case BuildOrderTreasuryNoBypassTarget.playerAgnosticZeroTreasury:
      final humanResult = validateBuildOrderTreasuryNoBypassRegiment(
        buildOrderTreasuryNoBypassGame(treasury: 0, isHuman: true),
      );
      final aiResult = validateBuildOrderTreasuryNoBypassRegiment(
        buildOrderTreasuryNoBypassGame(treasury: 0, isHuman: false),
      );
      expect(humanResult.status, OrderValidationStatus.rejected);
      expect(aiResult.status, OrderValidationStatus.rejected);
      expect(humanResult.reason, aiResult.reason);
  }
}
