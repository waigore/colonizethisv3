import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';

import 'support/h8_flagged_seller_game.dart';

// Refs #2847 § H8-extraction seller feedstock-tile acquisition target selection.
// Builds the same below-quota zero-NW lock-recovery seller fixture the detection
// test uses (gp1 owns an unimproved `wool` regiment-build-input feedstock tile,
// so the improvement-input gate is active and it needs `lumber` / `castIron`),
// then adds non-seller-owned provinces hosting `timber` / `iron` feedstock so the
// selection contract has acquisition candidates to enumerate.

void main() {
  group(
    'sellerFeedstockTileAcquisitionTargetProvinceIdsSorted '
    '(Refs #2847 H8-extraction seller feedstock-tile acquisition target)',
    () {
      test(
        'returns the single acquirable Old World province hosting timber '
        'feedstock when the seller is flagged',
        () {
          final game = flaggedSellerGame(
            resourceByTileKey: const {
              h8FlaggedSellerGrainTile: 'grain',
              h8FlaggedSellerWoolTile: 'wool',
              'oldWorld|t1|0|0': 'timber',
            },
            extraOldWorld: [h8TribeProvince('oldWorld|t1')],
          );
          // Precondition: the acquisition residual is active.
          expect(
            sellerNeedsImprovementInputFeedstockTileAcquisition(
              game,
              h8FlaggedSellerId,
            ),
            isTrue,
          );
          expect(
            sellerFeedstockTileAcquisitionTargetProvinceIdsSorted(
              game,
              h8FlaggedSellerId,
            ),
            equals(<String>['oldWorld|t1']),
          );
        },
      );

      test(
        'returns every feedstock-bearing acquirable province sorted ascending '
        'by province id',
        () {
          final game = flaggedSellerGame(
            resourceByTileKey: const {
              h8FlaggedSellerGrainTile: 'grain',
              h8FlaggedSellerWoolTile: 'wool',
              'oldWorld|t2|0|0': 'timber',
              'oldWorld|t1|0|0': 'iron',
            },
            extraOldWorld: [
              h8TribeProvince('oldWorld|t2'),
              h8TribeProvince('oldWorld|t1'),
            ],
          );
          expect(
            sellerFeedstockTileAcquisitionTargetProvinceIdsSorted(
              game,
              h8FlaggedSellerId,
            ),
            equals(<String>['oldWorld|t1', 'oldWorld|t2']),
          );
        },
      );

      test(
        'returns empty when the acquisition residual is inactive (seller owns '
        'an unimproved timber tile)',
        () {
          final game = flaggedSellerGame(
            resourceByTileKey: const {
              h8FlaggedSellerGrainTile: 'grain',
              h8FlaggedSellerWoolTile: 'wool',
              'oldWorld|p0|1|0': 'timber',
              'oldWorld|t1|0|0': 'timber',
            },
            extraOldWorld: [h8TribeProvince('oldWorld|t1')],
          );
          // The routing gate covers the seller's own unimproved timber tile, so
          // the detector is false and no acquisition target is offered.
          expect(
            sellerNeedsImprovementInputFeedstockTileAcquisition(
              game,
              h8FlaggedSellerId,
            ),
            isFalse,
          );
          expect(
            sellerFeedstockTileAcquisitionTargetProvinceIdsSorted(
              game,
              h8FlaggedSellerId,
            ),
            isEmpty,
          );
        },
      );

      test(
        'excludes New World feedstock provinces (cannot close the Old World '
        'turn-100 gate)',
        () {
          final game = flaggedSellerGame(
            resourceByTileKey: const {
              h8FlaggedSellerGrainTile: 'grain',
              h8FlaggedSellerWoolTile: 'wool',
              'newWorld|n1|0|0': 'timber',
            },
            extraNewWorld: [
              h8TribeProvince('newWorld|n1', region: kRegionNewWorld),
            ],
          );
          expect(
            sellerNeedsImprovementInputFeedstockTileAcquisition(
              game,
              h8FlaggedSellerId,
            ),
            isTrue,
          );
          expect(
            sellerFeedstockTileAcquisitionTargetProvinceIdsSorted(
              game,
              h8FlaggedSellerId,
            ),
            isEmpty,
          );
        },
      );

      test(
        'excludes acquirable provinces that host only non-feedstock resources',
        () {
          final game = flaggedSellerGame(
            resourceByTileKey: const {
              h8FlaggedSellerGrainTile: 'grain',
              h8FlaggedSellerWoolTile: 'wool',
              'oldWorld|t1|0|0': 'grain',
            },
            extraOldWorld: [h8TribeProvince('oldWorld|t1')],
          );
          expect(
            sellerNeedsImprovementInputFeedstockTileAcquisition(
              game,
              h8FlaggedSellerId,
            ),
            isTrue,
          );
          expect(
            sellerFeedstockTileAcquisitionTargetProvinceIdsSorted(
              game,
              h8FlaggedSellerId,
            ),
            isEmpty,
          );
        },
      );

      test('evaluation is deterministic', () {
        final game = flaggedSellerGame(
          resourceByTileKey: const {
            h8FlaggedSellerGrainTile: 'grain',
            h8FlaggedSellerWoolTile: 'wool',
            'oldWorld|t2|0|0': 'timber',
            'oldWorld|t1|0|0': 'iron',
          },
          extraOldWorld: [
            h8TribeProvince('oldWorld|t2'),
            h8TribeProvince('oldWorld|t1'),
          ],
        );
        final a = sellerFeedstockTileAcquisitionTargetProvinceIdsSorted(
          game,
          h8FlaggedSellerId,
        );
        final b = sellerFeedstockTileAcquisitionTargetProvinceIdsSorted(
          game,
          h8FlaggedSellerId,
        );
        expect(a, equals(b));
      });
    },
  );
}
