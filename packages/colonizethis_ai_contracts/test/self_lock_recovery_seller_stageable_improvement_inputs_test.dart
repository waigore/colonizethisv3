import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'support/h8_below_quota_zero_nw_seller_game.dart';

const _tileGrain = h8BelowQuotaGrainTile;
const _tileTimber = 'oldWorld|p0|2|0';

void main() {
  group(
    'selfLockRecoverySellerStageableImprovementInputs '
    '(Refs #2847 H8 production allocation — S7-D castIron, PR #3289)',
    () {
      test(
        'lock-recovery seller short castIron that owns only timber tile does '
        'not stage castIron once the recipe is iron-only (Refs #3858)',
        () {
          final game = belowQuotaActiveGateSellerGame(
            resourceByTileKey: h8BelowQuotaStageableImprovementInputResources,
          );
          expect(
            selfLockRecoverySellerNeededProducibleImprovementInputs(
              game,
              h8BelowQuotaSellerId,
            ),
            isEmpty,
            reason: 'fabric-tile gate inactive: prior helper must be empty',
          );
          expect(
            selfLockRecoverySellerStageableImprovementInputs(game, h8BelowQuotaSellerId),
            isEmpty,
            reason:
                'castIron is single-input; multi-input staging path is inactive',
          );
        },
      );

      test(
        'returns empty when the seller owns no castIron feedstock tile '
        '(negative control — gate-inactive sellers with no tile do not stage)',
        () {
          final game = belowQuotaActiveGateSellerGame(
            resourceByTileKey: const {_tileGrain: 'grain'},
          );
          expect(
            selfLockRecoverySellerStageableImprovementInputs(game, h8BelowQuotaSellerId),
            isEmpty,
          );
        },
      );

      test(
        'returns empty when the seller already holds castIron (short check)',
        () {
          final game = belowQuotaActiveGateSellerGame(
            stockpile: const Stockpile().applyDelta(
              CommodityCatalog.castIron.id,
              1,
            ),
            resourceByTileKey: h8BelowQuotaStageableImprovementInputResources,
          );
          expect(
            selfLockRecoverySellerStageableImprovementInputs(game, h8BelowQuotaSellerId),
            isEmpty,
          );
        },
      );

      test(
        'returns empty when the GP already owns a regiment '
        '(negative control — +6 baseline GPs unaffected)',
        () {
          final game = belowQuotaActiveGateSellerGame(
            extraUnits: [
              Unit(
                id: 'r1',
                type: 'peasant_levies',
                ownerId: h8BelowQuotaSellerId,
                locationProvinceId: 'oldWorld|p0',
              ),
            ],
            resourceByTileKey: h8BelowQuotaStageableImprovementInputResources,
          );
          expect(
            selfLockRecoverySellerStageableImprovementInputs(game, h8BelowQuotaSellerId),
            isEmpty,
          );
        },
      );

      test(
        'returns empty at the conquest quota (negative control)',
        () {
          final game = belowQuotaActiveGateSellerGame(
            owOwned: kObserverConquestMinOwProvincesPerGp,
            resourceByTileKey: h8BelowQuotaStageableImprovementInputResources,
          );
          expect(
            selfLockRecoverySellerStageableImprovementInputs(game, h8BelowQuotaSellerId),
            isEmpty,
          );
        },
      );

      test(
        'returns empty when the seller owns a New World province '
        '(negative control — only zero-NW sellers stage)',
        () {
          final game = belowQuotaActiveGateSellerGame(
            newWorldOwned: 1,
            resourceByTileKey: h8BelowQuotaStageableImprovementInputResources,
          );
          expect(
            selfLockRecoverySellerStageableImprovementInputs(game, h8BelowQuotaSellerId),
            isEmpty,
          );
        },
      );

      test('returns empty for an unknown player id', () {
        final game = belowQuotaActiveGateSellerGame(
            resourceByTileKey: h8BelowQuotaStageableImprovementInputResources,
          );
        expect(
          selfLockRecoverySellerStageableImprovementInputs(
            game,
            'no_such_player',
          ),
          isEmpty,
        );
      });
    },
  );
}
