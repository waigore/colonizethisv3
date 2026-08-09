import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';

import 'support/h8_flagged_seller_game.dart';

// Refs #2847 § H8-extraction seller feedstock-tile acquisition primary target
// pick. Reuses the below-quota zero-NW lock-recovery seller fixture from the
// selection / intersection tests (gp1 owns an unimproved `wool`
// regiment-build-input feedstock tile, so the improvement-input gate is active
// and it needs `lumber` / `castIron`), then exercises the final single-target
// pick over a caller-supplied acquirable province set.

void main() {
  group(
    'sellerFeedstockTileAcquisitionTarget '
    '(Refs #2847 H8-extraction seller feedstock-tile acquisition primary pick)',
    () {
      test('returns the lowest acquirable feedstock province id', () {
        final game = flaggedSellerGame(
          resourceByTileKey: const {
            h8FlaggedSellerGrainTile: 'grain',
            h8FlaggedSellerWoolTile: 'wool',
            'oldWorld|t1|0|0': 'timber',
            'oldWorld|t2|0|0': 'iron',
            'oldWorld|t3|0|0': 'timber',
          },
          extraOldWorld: [
            h8TribeProvince('oldWorld|t1'),
            h8TribeProvince('oldWorld|t2'),
            h8TribeProvince('oldWorld|t3'),
          ],
        );
        // Precondition: t2 and t3 are the acquirable feedstock candidates.
        expect(
          sellerFeedstockTileAcquisitionTargetsAmongAcquirable(
            game,
            h8FlaggedSellerId,
            const {'oldWorld|t2', 'oldWorld|t3', 'oldWorld|t9'},
          ),
          equals(<String>['oldWorld|t2', 'oldWorld|t3']),
        );
        expect(
          sellerFeedstockTileAcquisitionTarget(game, h8FlaggedSellerId, const {
            'oldWorld|t2',
            'oldWorld|t3',
            'oldWorld|t9',
          }),
          equals('oldWorld|t2'),
        );
      });

      test('returns the lowest province id regardless of acquirable-set '
          'iteration order', () {
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
          sellerFeedstockTileAcquisitionTarget(
            game,
            h8FlaggedSellerId,
            // Insertion order deliberately descending.
            const {'oldWorld|t2', 'oldWorld|t1'},
          ),
          equals('oldWorld|t1'),
        );
      });

      test(
        'returns null when the acquirable set is disjoint from candidates',
        () {
          final game = flaggedSellerGame(
            resourceByTileKey: const {
              h8FlaggedSellerGrainTile: 'grain',
              h8FlaggedSellerWoolTile: 'wool',
              'oldWorld|t1|0|0': 'timber',
            },
            extraOldWorld: [h8TribeProvince('oldWorld|t1')],
          );
          expect(
            sellerFeedstockTileAcquisitionTarget(game, h8FlaggedSellerId, const {
              'oldWorld|t9',
              'oldWorld|t8',
            }),
            isNull,
          );
        },
      );

      test('returns null when the acquirable set is empty', () {
        final game = flaggedSellerGame(
          resourceByTileKey: const {
            h8FlaggedSellerGrainTile: 'grain',
            h8FlaggedSellerWoolTile: 'wool',
            'oldWorld|t1|0|0': 'timber',
          },
          extraOldWorld: [h8TribeProvince('oldWorld|t1')],
        );
        expect(
          sellerFeedstockTileAcquisitionTarget(
            game,
            h8FlaggedSellerId,
            const <String>{},
          ),
          isNull,
        );
      });

      test('returns null when the acquisition residual is inactive even though '
          'the acquirable set contains a feedstock province', () {
        // Seller owns an unimproved timber tile (oldWorld|p0|1|0), so the
        // routing gate covers it and the detector is false.
        final game = flaggedSellerGame(
          resourceByTileKey: const {
            h8FlaggedSellerGrainTile: 'grain',
            h8FlaggedSellerWoolTile: 'wool',
            'oldWorld|p0|1|0': 'timber',
            'oldWorld|t1|0|0': 'timber',
          },
          extraOldWorld: [h8TribeProvince('oldWorld|t1')],
        );
        expect(
          sellerNeedsImprovementInputFeedstockTileAcquisition(
            game,
            h8FlaggedSellerId,
          ),
          isFalse,
        );
        expect(
          sellerFeedstockTileAcquisitionTarget(game, h8FlaggedSellerId, const {
            'oldWorld|t1',
          }),
          isNull,
        );
      });

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
        const acquirable = {'oldWorld|t1', 'oldWorld|t2'};
        final a = sellerFeedstockTileAcquisitionTarget(
          game,
          h8FlaggedSellerId,
          acquirable,
        );
        final b = sellerFeedstockTileAcquisitionTarget(
          game,
          h8FlaggedSellerId,
          acquirable,
        );
        expect(a, equals(b));
        expect(a, equals('oldWorld|t1'));
      });
    },
  );
}
