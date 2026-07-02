// Focused unit tests for the extracted fleet-scan helper
// (`scanTradeInterceptionInputs`) split out of `trade_interception.dart`
// per Refs #3615 Cluster 4 file decomposition. These pin the aggregation
// contract (intercept/evasion/escort/merchant counters, blockade flag, and
// the tech-gated privateering multiplier) directly, so the scan stays
// regression-guarded independently of the cargo-reduction apply path.
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  setUp(resetTradeInterceptionScanFleetSeq);

  group('scanTradeInterceptionInputs', () {
    test('no enemy patrol/blockade fleets yields zero intercept score', () {
      final scan = scanTradeInterceptionInputs(
        [
          tradeInterceptionScanFleet(ownerId: 'p1', shipTypeIds: const ['fluyte']),
        ],
        const <String>{'p2'},
        'p1',
        const <String>{},
      );

      expect(scan.interceptScore, 0.0);
      expect(scan.hasBlockade, isFalse);
      expect(scan.playerMerchantShips, 1);
    });

    test('player merchant ships counted; escorts feed escort strength', () {
      final scan = scanTradeInterceptionInputs(
        [
          tradeInterceptionScanFleet(ownerId: 'p1', shipTypeIds: const ['fluyte', 'carrack']),
          tradeInterceptionScanFleet(ownerId: 'p1', shipTypeIds: const ['sloop']),
        ],
        const <String>{'p2'},
        'p1',
        const <String>{},
      );

      expect(scan.playerMerchantShips, 2);
      expect(scan.escortStrength, greaterThan(0.0));
      // Merchant hulls are not in `kMerchantShipTypeIds`-excluded escort set.
      expect(kMerchantShipTypeIds, containsAll(<String>{'fluyte', 'carrack'}));
    });

    test('enemy blockade fleet sets the blockade flag', () {
      final scan = scanTradeInterceptionInputs(
        [
          tradeInterceptionScanFleet(
            ownerId: 'p2',
            shipTypeIds: const ['sloop'],
            mission: FleetMission.blockade,
          ),
        ],
        const <String>{'p2'},
        'p1',
        const <String>{},
      );

      expect(scan.hasBlockade, isTrue);
      expect(scan.interceptScore, greaterThan(0.0));
    });

    test('privateering enemy scales intercept score above the baseline', () {
      List<Fleet> enemyPatrol() => [
        tradeInterceptionScanFleet(ownerId: 'p2', shipTypeIds: const ['sloop']),
      ];

      final baseline = scanTradeInterceptionInputs(
        enemyPatrol(),
        const <String>{'p2'},
        'p1',
        const <String>{},
      );
      final boosted = scanTradeInterceptionInputs(
        enemyPatrol(),
        const <String>{'p2'},
        'p1',
        const <String>{'p2'},
      );

      expect(baseline.interceptScore, greaterThan(0.0));
      expect(
        boosted.interceptScore,
        closeTo(baseline.interceptScore * kPrivateeringTradeRaidBonus, 1e-9),
      );
    });
  });
}
