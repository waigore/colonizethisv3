import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'support/h8_below_quota_zero_nw_seller_game.dart';

// Refs #2847 § H8-extraction seller feedstock-tile acquisition. Single-player
// fixture: a below-quota zero-NW lock-recovery seller whose improvement-input
// gate is active (it owns an unimproved `wool` regiment-build-input feedstock
// tile, so `regimentBuildInputFeedstockImprovementInputCost` is non-empty) and
// which needs its own level-0 `build_improvement` inputs (`lumber` / `castIron`).
// The acquisition residual is the case where it owns NO `timber` / `iron`
// feedstock tile at all to produce those inputs from.
const _grainTile = h8BelowQuotaGrainTile;
const _timberTile = 'oldWorld|p0|1|0';
const _woolTile = 'oldWorld|p0|2|0';
const _ironTile = 'oldWorld|p0|3|0';

void main() {
  group(
    'sellerNeedsImprovementInputFeedstockTileAcquisition '
    '(Refs #2847 H8-extraction seller feedstock-tile acquisition)',
    () {
      test(
        'true when the seller needs lumber/castIron but owns no '
        'timber/iron feedstock tile',
        () {
          final game = belowQuotaActiveGateSellerGame(
            resourceByTileKey: const {_grainTile: 'grain', _woolTile: 'wool'},
          );
          expect(
            sellerNeedsImprovementInputFeedstockTileAcquisition(game, h8BelowQuotaSellerId),
            isTrue,
          );
        },
      );

      test(
        'false when the seller owns an unimproved timber tile '
        '(routing gate covers it)',
        () {
          final game = belowQuotaActiveGateSellerGame(
            resourceByTileKey: h8BelowQuotaTimberImprovementInputResources,
          );
          expect(
            sellerNeedsImprovementInputFeedstockTileAcquisition(game, h8BelowQuotaSellerId),
            isFalse,
          );
        },
      );

      test(
        'false when the only timber tile is already improved '
        '(improved-tile residual, not acquisition)',
        () {
          final game = belowQuotaActiveGateSellerGame(
            tileState: TileMapState().setImprovement(_timberTile, 1),
            resourceByTileKey: h8BelowQuotaTimberImprovementInputResources,
          );
          expect(
            sellerNeedsImprovementInputFeedstockTileAcquisition(game, h8BelowQuotaSellerId),
            isFalse,
          );
        },
      );

      test(
        'false when the seller owns an iron feedstock tile but no timber '
        '(owns a feedstock tile — out of acquisition scope)',
        () {
          final game = belowQuotaActiveGateSellerGame(
            resourceByTileKey: const {
              _grainTile: 'grain',
              _woolTile: 'wool',
              _ironTile: 'iron',
            },
          );
          expect(
            sellerNeedsImprovementInputFeedstockTileAcquisition(game, h8BelowQuotaSellerId),
            isFalse,
          );
        },
      );

      test('false for a player at the conquest quota (gate inactive)', () {
        final game = belowQuotaActiveGateSellerGame(
          owOwned: kObserverConquestMinOwProvincesPerGp,
          resourceByTileKey: const {_grainTile: 'grain', _woolTile: 'wool'},
        );
        expect(
          sellerNeedsImprovementInputFeedstockTileAcquisition(game, h8BelowQuotaSellerId),
          isFalse,
        );
      });

      test('false when the seller owns a New World province (gate inactive)', () {
        final game = belowQuotaActiveGateSellerGame(
          newWorldOwned: 1,
          resourceByTileKey: const {_grainTile: 'grain', _woolTile: 'wool'},
        );
        expect(
          sellerNeedsImprovementInputFeedstockTileAcquisition(game, h8BelowQuotaSellerId),
          isFalse,
        );
      });

      test('false when the seller owns a regiment (gate inactive)', () {
        final game = belowQuotaActiveGateSellerGame(
          resourceByTileKey: const {_grainTile: 'grain', _woolTile: 'wool'},
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
          sellerNeedsImprovementInputFeedstockTileAcquisition(game, h8BelowQuotaSellerId),
          isFalse,
        );
      });

      test(
        'false when the seller already holds both improvement inputs',
        () {
          final game = belowQuotaActiveGateSellerGame(
            resourceByTileKey: const {_grainTile: 'grain', _woolTile: 'wool'},
            stockpile: const Stockpile(
              quantities: {'lumber': 1, 'castIron': 1},
            ),
          );
          expect(
            sellerNeedsImprovementInputFeedstockTileAcquisition(game, h8BelowQuotaSellerId),
            isFalse,
          );
        },
      );

      test('evaluation is deterministic', () {
        final game = belowQuotaActiveGateSellerGame(
          resourceByTileKey: const {_grainTile: 'grain', _woolTile: 'wool'},
        );
        final a = sellerNeedsImprovementInputFeedstockTileAcquisition(
          game,
          h8BelowQuotaSellerId,
        );
        final b = sellerNeedsImprovementInputFeedstockTileAcquisition(
          game,
          h8BelowQuotaSellerId,
        );
        expect(a, equals(b));
      });
    },
  );
}
