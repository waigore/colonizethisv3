import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// Refs #2847 § H8-extraction seller feedstock-tile acquisition primary target
// pick. Reuses the below-quota zero-NW lock-recovery seller fixture from the
// selection / intersection tests (gp1 owns an unimproved `wool`
// regiment-build-input feedstock tile, so the improvement-input gate is active
// and it needs `lumber` / `castIron`), then exercises the final single-target
// pick over a caller-supplied acquirable province set.
const _sellerId = 'gp1';

const _grainTile = 'oldWorld|p0|0|0';
const _woolTile = 'oldWorld|p0|2|0';

Game _flaggedSellerGame({
  Map<String, String> resourceByTileKey = const {
    _grainTile: 'grain',
    _woolTile: 'wool',
  },
  List<Province> extraOldWorld = const [],
  TileMapState? tileState,
}) {
  final sellerProvinces = List.generate(
    5,
    (i) => Province(
      id: 'oldWorld|p$i',
      regionId: kRegionOldWorld,
      ownerId: _sellerId,
    ),
  );
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: [...sellerProvinces, ...extraOldWorld]),
      newWorld: const RegionData(provinces: []),
      resourceByTileKey: resourceByTileKey,
      tileState: tileState ?? TileMapState(),
    ),
    players: [
      Player(
        id: _sellerId,
        displayName: 'Seller',
        isHuman: false,
        treasury: cheapestRegimentBuildTreasuryCost(),
        stockpile: const Stockpile(),
      ),
    ],
  );
}

Province _tribeProvince(String id) =>
    Province(id: id, regionId: kRegionOldWorld, ownerId: 'tribe1');

void main() {
  group(
    'sellerFeedstockTileAcquisitionTarget '
    '(Refs #2847 H8-extraction seller feedstock-tile acquisition primary pick)',
    () {
      test('returns the lowest acquirable feedstock province id', () {
        final game = _flaggedSellerGame(
          resourceByTileKey: const {
            _grainTile: 'grain',
            _woolTile: 'wool',
            'oldWorld|t1|0|0': 'timber',
            'oldWorld|t2|0|0': 'iron',
            'oldWorld|t3|0|0': 'timber',
          },
          extraOldWorld: [
            _tribeProvince('oldWorld|t1'),
            _tribeProvince('oldWorld|t2'),
            _tribeProvince('oldWorld|t3'),
          ],
        );
        // Precondition: t2 and t3 are the acquirable feedstock candidates.
        expect(
          sellerFeedstockTileAcquisitionTargetsAmongAcquirable(
            game,
            _sellerId,
            const {'oldWorld|t2', 'oldWorld|t3', 'oldWorld|t9'},
          ),
          equals(<String>['oldWorld|t2', 'oldWorld|t3']),
        );
        expect(
          sellerFeedstockTileAcquisitionTarget(game, _sellerId, const {
            'oldWorld|t2',
            'oldWorld|t3',
            'oldWorld|t9',
          }),
          equals('oldWorld|t2'),
        );
      });

      test('returns the lowest province id regardless of acquirable-set '
          'iteration order', () {
        final game = _flaggedSellerGame(
          resourceByTileKey: const {
            _grainTile: 'grain',
            _woolTile: 'wool',
            'oldWorld|t2|0|0': 'timber',
            'oldWorld|t1|0|0': 'iron',
          },
          extraOldWorld: [
            _tribeProvince('oldWorld|t2'),
            _tribeProvince('oldWorld|t1'),
          ],
        );
        expect(
          sellerFeedstockTileAcquisitionTarget(
            game,
            _sellerId,
            // Insertion order deliberately descending.
            const {'oldWorld|t2', 'oldWorld|t1'},
          ),
          equals('oldWorld|t1'),
        );
      });

      test(
        'returns null when the acquirable set is disjoint from candidates',
        () {
          final game = _flaggedSellerGame(
            resourceByTileKey: const {
              _grainTile: 'grain',
              _woolTile: 'wool',
              'oldWorld|t1|0|0': 'timber',
            },
            extraOldWorld: [_tribeProvince('oldWorld|t1')],
          );
          expect(
            sellerFeedstockTileAcquisitionTarget(game, _sellerId, const {
              'oldWorld|t9',
              'oldWorld|t8',
            }),
            isNull,
          );
        },
      );

      test('returns null when the acquirable set is empty', () {
        final game = _flaggedSellerGame(
          resourceByTileKey: const {
            _grainTile: 'grain',
            _woolTile: 'wool',
            'oldWorld|t1|0|0': 'timber',
          },
          extraOldWorld: [_tribeProvince('oldWorld|t1')],
        );
        expect(
          sellerFeedstockTileAcquisitionTarget(
            game,
            _sellerId,
            const <String>{},
          ),
          isNull,
        );
      });

      test('returns null when the acquisition residual is inactive even though '
          'the acquirable set contains a feedstock province', () {
        // Seller owns an unimproved timber tile (oldWorld|p0|1|0), so the
        // routing gate covers it and the detector is false.
        final game = _flaggedSellerGame(
          resourceByTileKey: const {
            _grainTile: 'grain',
            _woolTile: 'wool',
            'oldWorld|p0|1|0': 'timber',
            'oldWorld|t1|0|0': 'timber',
          },
          extraOldWorld: [_tribeProvince('oldWorld|t1')],
        );
        expect(
          sellerNeedsImprovementInputFeedstockTileAcquisition(game, _sellerId),
          isFalse,
        );
        expect(
          sellerFeedstockTileAcquisitionTarget(game, _sellerId, const {
            'oldWorld|t1',
          }),
          isNull,
        );
      });

      test('evaluation is deterministic', () {
        final game = _flaggedSellerGame(
          resourceByTileKey: const {
            _grainTile: 'grain',
            _woolTile: 'wool',
            'oldWorld|t2|0|0': 'timber',
            'oldWorld|t1|0|0': 'iron',
          },
          extraOldWorld: [
            _tribeProvince('oldWorld|t2'),
            _tribeProvince('oldWorld|t1'),
          ],
        );
        const acquirable = {'oldWorld|t1', 'oldWorld|t2'};
        final a = sellerFeedstockTileAcquisitionTarget(
          game,
          _sellerId,
          acquirable,
        );
        final b = sellerFeedstockTileAcquisitionTarget(
          game,
          _sellerId,
          acquirable,
        );
        expect(a, equals(b));
        expect(a, equals('oldWorld|t1'));
      });
    },
  );
}
