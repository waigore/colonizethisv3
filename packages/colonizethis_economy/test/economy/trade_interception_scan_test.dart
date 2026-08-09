import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// --- Slice C runners (Refs #4108) ---
// dart format off
TradeInterceptionScan _scan(List<Fleet> fleets, {Set<String> enemiesAtWar = const {'p2'}, Set<String> privateeringOwners = const {}}) => scanTradeInterceptionInputs(fleets, enemiesAtWar, 'p1', privateeringOwners);

void runTradeInterceptionScanExpectation(TradeInterceptionScanTarget target) {
  switch (target) {
    case TradeInterceptionScanTarget.noEnemyPatrol:
      final scan = _scan([
        tradeInterceptionScanFleet(ownerId: 'p1', shipTypeIds: const ['fluyte']),
      ]);
      expect(scan.interceptScore, 0.0);
      expect(scan.hasBlockade, isFalse);
      expect(scan.playerMerchantShips, 1);
    case TradeInterceptionScanTarget.merchantEscortCount:
      final scan = _scan([
        tradeInterceptionScanFleet(ownerId: 'p1', shipTypeIds: const ['fluyte', 'carrack']),
        tradeInterceptionScanFleet(ownerId: 'p1', shipTypeIds: const ['sloop']),
      ]);
      expect(scan.playerMerchantShips, 2);
      expect(scan.escortStrength, greaterThan(0.0));
      expect(kMerchantShipTypeIds, containsAll(<String>{'fluyte', 'carrack'}));
    case TradeInterceptionScanTarget.enemyBlockade:
      final scan = _scan([
        tradeInterceptionScanFleet(ownerId: 'p2', shipTypeIds: const ['sloop'], mission: FleetMission.blockade),
      ]);
      expect(scan.hasBlockade, isTrue);
      expect(scan.interceptScore, greaterThan(0.0));
    case TradeInterceptionScanTarget.privateeringScales:
      List<Fleet> enemyPatrol() => [
        tradeInterceptionScanFleet(ownerId: 'p2', shipTypeIds: const ['sloop']),
      ];
      final baseline = _scan(enemyPatrol());
      final boosted = _scan(enemyPatrol(), privateeringOwners: const {'p2'});
      expect(baseline.interceptScore, greaterThan(0.0));
      expect(boosted.interceptScore, closeTo(baseline.interceptScore * kPrivateeringTradeRaidBonus, 1e-9));
  }
}

void runTradeInterceptionScanScenario(TradeInterceptionScanScenario scenario) {
  runTradeInterceptionScanExpectation(scenario.target);
}
// dart format on

void main() {
  setUp(resetTradeInterceptionScanFleetSeq);

  runLabeledScenarioGroup(
    'scanTradeInterceptionInputs',
    tradeInterceptionScanScenarios(),
    runTradeInterceptionScanScenario,
    labelOf: (s) => s.label,
  );
}
