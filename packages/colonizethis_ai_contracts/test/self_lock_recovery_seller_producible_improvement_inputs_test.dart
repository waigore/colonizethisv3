import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'support/h8_below_quota_zero_nw_seller_game.dart';

void main() {
  group('selfLockRecoverySellerNeededProducibleImprovementInputs '
      '(Refs #2847 H8-extraction S7-D lumber re-localization)', () {
    test('active gate + short of both lumber and castIron returns both '
        'producible level-0 inputs', () {
      // Default empty stockpile: the seller holds neither lumber nor
      // castIron, and both are producible (lumber from timber; castIron
      // from timber + iron), so both join the seller-side domestic
      // production set.
      final game = belowQuotaZeroNwSellerGame(
        owOwned: 5,
        treasury: cheapestRegimentBuildTreasuryCost(),
      );
      expect(
        selfLockRecoverySellerNeededProducibleImprovementInputs(
          game,
          h8BelowQuotaSellerId,
        ),
        equals({CommodityCatalog.lumber.id, CommodityCatalog.castIron.id}),
      );
    });

    test('an input the seller already holds is excluded (only the binding '
        'lumber remains when castIron is on hand)', () {
      final game = belowQuotaZeroNwSellerGame(
        owOwned: 5,
        treasury: cheapestRegimentBuildTreasuryCost(),
        stockpile: const Stockpile().applyDelta(
          CommodityCatalog.castIron.id,
          1,
        ),
      );
      expect(
        selfLockRecoverySellerNeededProducibleImprovementInputs(
          game,
          h8BelowQuotaSellerId,
        ),
        equals({CommodityCatalog.lumber.id}),
      );
    });

    test('returns empty when the gate is inactive (at conquest quota) — '
        'negative control, +6 baseline GPs unaffected', () {
      final game = belowQuotaZeroNwSellerGame(
        owOwned: kObserverConquestMinOwProvincesPerGp,
        treasury: cheapestRegimentBuildTreasuryCost(),
      );
      expect(
        selfLockRecoverySellerNeededProducibleImprovementInputs(
          game,
          h8BelowQuotaSellerId,
        ),
        isEmpty,
      );
    });

    test('returns empty when the GP already owns a regiment '
        '(negative control)', () {
      final game = belowQuotaZeroNwSellerGame(
        owOwned: 5,
        treasury: cheapestRegimentBuildTreasuryCost(),
        extraUnits: [
          Unit(
            id: 'r1',
            type: 'peasant_levies',
            ownerId: h8BelowQuotaSellerId,
            locationProvinceId: 'oldWorld|p0',
          ),
        ],
      );
      expect(
        selfLockRecoverySellerNeededProducibleImprovementInputs(
          game,
          h8BelowQuotaSellerId,
        ),
        isEmpty,
      );
    });

    test('returns empty for an unknown player id', () {
      final game = belowQuotaZeroNwSellerGame(
        owOwned: 5,
        treasury: cheapestRegimentBuildTreasuryCost(),
      );
      expect(
        selfLockRecoverySellerNeededProducibleImprovementInputs(
          game,
          'no_such_player',
        ),
        isEmpty,
      );
    });
  });
}
