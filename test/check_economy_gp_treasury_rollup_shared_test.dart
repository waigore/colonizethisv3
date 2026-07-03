import 'package:test/test.dart';

import '../tool/check_economy_gp_treasury_rollup_shared.dart';

void main() {
  group('findEconomyGpTreasuryRollupSharedViolations', () {
    test('passes when both targets reference GpTreasuryCreditRollup', () {
      final violations = findEconomyGpTreasuryRollupSharedViolations(
        sourcesByPath: {
          'packages/colonizethis_economy/lib/src/economy/world_market/first_right_credits.dart':
              'class X { GpTreasuryCreditRollup<double> r; }',
          'packages/colonizethis_economy/lib/src/economy/world_market/purchased_tile_riches.dart':
              'class Y { GpTreasuryCreditRollup<int> r; }',
        },
      );
      expect(violations, isEmpty);
    });

    test('fails when a target omits GpTreasuryCreditRollup', () {
      final violations = findEconomyGpTreasuryRollupSharedViolations(
        sourcesByPath: {
          'packages/colonizethis_economy/lib/src/economy/world_market/first_right_credits.dart':
              'class X {}',
          'packages/colonizethis_economy/lib/src/economy/world_market/purchased_tile_riches.dart':
              'class Y { GpTreasuryCreditRollup<int> r; }',
        },
      );
      expect(violations, hasLength(1));
      expect(violations.single, contains('first_right_credits.dart'));
    });
  });
}
