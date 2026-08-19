// Topical S7-D lock-recovery diagnostic contract (Refs #2924 / #3967).
//
// Pins the Step-0 JSON key surface without re-running the 100-turn campaign.
// The campaign runner remains in `seed42_observer_conquest_s7d_diagnostic_test.dart`.

import 'package:colonizethis_test/test.dart';

import '../support/s7d/diagnostic_json.dart';

void main() {
  group('buildSeed42S7dLockRecoveryDiagnosticJson', () {
    test('positive: emits required Step-0 lock-recovery keys', () {
      final json = buildSeed42S7dLockRecoveryDiagnosticJson(
        gpIds: const ['gp1'],
        tradeOfferCount: const {'gp1': 2},
        tradeUrgentOfferCount: const {'gp1': 1},
        tradeBidCount: const {'gp1': 3},
        dealsAsSeller: const {'gp1': 4},
        dealsAsBuyer: const {'gp1': 5},
        treasuryCredited: const {'gp1': 100},
        treasuryDebited: const {'gp1': 50},
        regimentThresholdCrossingsUp: const {'gp1': 1},
        regimentThresholdFirstReachTurn: const {'gp1': 12},
        treasuryUnderCheapestTurns: const {'gp1': 80},
        treasuryAtTurn99: const {'gp1': 2000},
        cheapestRegimentCost: 2000,
      );

      expect(json['issue'], 2924);
      expect(json['step'], 'Step 0');
      expect(
        Seed42S7dDiagnosticJsonKeys.lockRecovery.every(json.containsKey),
        isTrue,
        reason: 'lock-recovery JSON must expose the Step-0 key contract',
      );
      expect(json['cheapestRegimentBuildTreasuryCost'], 2000);
      expect((json['gpTradeOrdersEmitted'] as Map<String, Object?>)['gp1'], {
        'offers': 2,
        'urgentOffers': 1,
        'bids': 3,
      });
    });

    test('negative: missing GP defaults trade/deal counters to zero', () {
      final json = buildSeed42S7dLockRecoveryDiagnosticJson(
        gpIds: const ['gp9'],
        tradeOfferCount: const {},
        tradeUrgentOfferCount: const {},
        tradeBidCount: const {},
        dealsAsSeller: const {},
        dealsAsBuyer: const {},
        treasuryCredited: const {'gp9': 0},
        treasuryDebited: const {'gp9': 0},
        regimentThresholdCrossingsUp: const {'gp9': 0},
        regimentThresholdFirstReachTurn: const {'gp9': null},
        treasuryUnderCheapestTurns: const {'gp9': 0},
        treasuryAtTurn99: const {'gp9': 0},
        cheapestRegimentCost: 2000,
      );

      expect((json['gpTradeOrdersEmitted'] as Map<String, Object?>)['gp9'], {
        'offers': 0,
        'urgentOffers': 0,
        'bids': 0,
      });
      expect((json['gpDealsMatched'] as Map<String, Object?>)['gp9'], {
        'asSeller': 0,
        'asBuyer': 0,
      });
    });
  });
}
