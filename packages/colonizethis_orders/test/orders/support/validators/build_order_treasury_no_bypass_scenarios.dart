// Table-driven build-order treasury no-bypass guard scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'build_order_treasury_no_bypass_fixtures.dart';

void botnbRunCheapestRegimentFixturePin() {
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
}

void botnbRunAiBelowTreasuryRejected() {
  final game = buildOrderTreasuryNoBypassGame(
    treasury: buildOrderTreasuryNoBypassCheapest.buildTreasuryCost - 1,
    isHuman: false,
  );
  final result = validateBuildOrderTreasuryNoBypassRegiment(game);
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, 'Insufficient treasury');
}

void botnbRunAiAtTreasuryAccepted() {
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
}

void botnbRunHumanZeroTreasuryRejected() {
  final game = buildOrderTreasuryNoBypassGame(treasury: 0, isHuman: true);
  final result = validateBuildOrderTreasuryNoBypassRegiment(game);
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, 'Insufficient treasury');
}

void botnbRunPlayerAgnosticZeroTreasury() {
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

/// Canonical scenarios for build-order treasury no-bypass guard.
List<RunnableScenario> buildOrderTreasuryNoBypassScenarios() => [
  RunnableScenario(
    label: 'peasant_levies is the cheapest, tech-free regiment (fixture pin)',
    run: botnbRunCheapestRegimentFixturePin,
    refs: '#2924',
  ),
  RunnableScenario(
    label: 'AI player below cheapest regiment treasury is rejected (no bypass)',
    run: botnbRunAiBelowTreasuryRejected,
    refs: '#2924',
  ),
  RunnableScenario(
    label:
        'AI player at exactly the cheapest treasury is accepted (treasury gate is the sole blocker)',
    run: botnbRunAiAtTreasuryAccepted,
    refs: '#2924',
  ),
  RunnableScenario(
    label: 'human player at zero treasury is rejected (no human waiver)',
    run: botnbRunHumanZeroTreasuryRejected,
    refs: '#2924',
  ),
  RunnableScenario(
    label:
        'affordability gate is player-agnostic at zero treasury (human and AI both rejected)',
    run: botnbRunPlayerAgnosticZeroTreasury,
    refs: '#2924',
  ),
];
