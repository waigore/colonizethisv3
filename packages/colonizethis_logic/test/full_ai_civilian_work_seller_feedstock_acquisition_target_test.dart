import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// Refs #2847 § H8-extraction seller feedstock-tile acquisition target selection.
// Builds the same below-quota zero-NW lock-recovery seller fixture the detection
// test uses (gp1 owns an unimproved `wool` regiment-build-input feedstock tile,
// so the improvement-input gate is active and it needs `lumber` / `castIron`),
// then adds non-seller-owned provinces hosting `timber` / `iron` feedstock so the
// selection contract has acquisition candidates to enumerate.
const _sellerId = 'gp1';

const _grainTile = 'oldWorld|p0|0|0';
const _woolTile = 'oldWorld|p0|2|0';

Game _flaggedSellerGame({
  Map<String, String> resourceByTileKey = const {
    _grainTile: 'grain',
    _woolTile: 'wool',
  },
  List<Province> extraOldWorld = const [],
  List<Province> extraNewWorld = const [],
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
      newWorld: RegionData(provinces: extraNewWorld),
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

Province _tribeProvince(String id, {String region = kRegionOldWorld}) =>
    Province(id: id, regionId: region, ownerId: 'tribe1');

void main() {
  group(
    'sellerFeedstockTileAcquisitionTargetProvinceIdsSorted '
    '(Refs #2847 H8-extraction seller feedstock-tile acquisition target)',
    () {
      test(
        'returns the single acquirable Old World province hosting timber '
        'feedstock when the seller is flagged',
        () {
          final game = _flaggedSellerGame(
            resourceByTileKey: const {
              _grainTile: 'grain',
              _woolTile: 'wool',
              'oldWorld|t1|0|0': 'timber',
            },
            extraOldWorld: [_tribeProvince('oldWorld|t1')],
          );
          // Precondition: the acquisition residual is active.
          expect(
            sellerNeedsImprovementInputFeedstockTileAcquisition(game, _sellerId),
            isTrue,
          );
          expect(
            sellerFeedstockTileAcquisitionTargetProvinceIdsSorted(
              game,
              _sellerId,
            ),
            equals(<String>['oldWorld|t1']),
          );
        },
      );

      test(
        'returns every feedstock-bearing acquirable province sorted ascending '
        'by province id',
        () {
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
            sellerFeedstockTileAcquisitionTargetProvinceIdsSorted(
              game,
              _sellerId,
            ),
            equals(<String>['oldWorld|t1', 'oldWorld|t2']),
          );
        },
      );

      test(
        'returns empty when the acquisition residual is inactive (seller owns '
        'an unimproved timber tile)',
        () {
          final game = _flaggedSellerGame(
            resourceByTileKey: const {
              _grainTile: 'grain',
              _woolTile: 'wool',
              'oldWorld|p0|1|0': 'timber',
              'oldWorld|t1|0|0': 'timber',
            },
            extraOldWorld: [_tribeProvince('oldWorld|t1')],
          );
          // The routing gate covers the seller's own unimproved timber tile, so
          // the detector is false and no acquisition target is offered.
          expect(
            sellerNeedsImprovementInputFeedstockTileAcquisition(game, _sellerId),
            isFalse,
          );
          expect(
            sellerFeedstockTileAcquisitionTargetProvinceIdsSorted(
              game,
              _sellerId,
            ),
            isEmpty,
          );
        },
      );

      test(
        'excludes New World feedstock provinces (cannot close the Old World '
        'turn-100 gate)',
        () {
          final game = _flaggedSellerGame(
            resourceByTileKey: const {
              _grainTile: 'grain',
              _woolTile: 'wool',
              'newWorld|n1|0|0': 'timber',
            },
            extraNewWorld: [
              _tribeProvince('newWorld|n1', region: kRegionNewWorld),
            ],
          );
          expect(
            sellerNeedsImprovementInputFeedstockTileAcquisition(game, _sellerId),
            isTrue,
          );
          expect(
            sellerFeedstockTileAcquisitionTargetProvinceIdsSorted(
              game,
              _sellerId,
            ),
            isEmpty,
          );
        },
      );

      test(
        'excludes acquirable provinces that host only non-feedstock resources',
        () {
          final game = _flaggedSellerGame(
            resourceByTileKey: const {
              _grainTile: 'grain',
              _woolTile: 'wool',
              'oldWorld|t1|0|0': 'grain',
            },
            extraOldWorld: [_tribeProvince('oldWorld|t1')],
          );
          expect(
            sellerNeedsImprovementInputFeedstockTileAcquisition(game, _sellerId),
            isTrue,
          );
          expect(
            sellerFeedstockTileAcquisitionTargetProvinceIdsSorted(
              game,
              _sellerId,
            ),
            isEmpty,
          );
        },
      );

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
        final a = sellerFeedstockTileAcquisitionTargetProvinceIdsSorted(
          game,
          _sellerId,
        );
        final b = sellerFeedstockTileAcquisitionTargetProvinceIdsSorted(
          game,
          _sellerId,
        );
        expect(a, equals(b));
      });
    },
  );
}
