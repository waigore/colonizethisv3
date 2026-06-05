import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// Refs #2847 § H8-extraction seller feedstock-tile acquisition. Single-player
// fixture: a below-quota zero-NW lock-recovery seller whose improvement-input
// gate is active (it owns an unimproved `wool` regiment-build-input feedstock
// tile, so `regimentBuildInputFeedstockImprovementInputCost` is non-empty) and
// which needs its own level-0 `build_improvement` inputs (`lumber` / `castIron`).
// The acquisition residual is the case where it owns NO `timber` / `iron`
// feedstock tile at all to produce those inputs from.
const _sellerId = 'gp1';

const _grainTile = 'oldWorld|p0|0|0';
const _timberTile = 'oldWorld|p0|1|0';
const _woolTile = 'oldWorld|p0|2|0';
const _ironTile = 'oldWorld|p0|3|0';

Game _belowQuotaSellerGame({
  int owOwned = 5,
  Stockpile stockpile = const Stockpile(),
  Map<String, String> resourceByTileKey = const {
    _grainTile: 'grain',
    _timberTile: 'timber',
    _woolTile: 'wool',
  },
  TileMapState? tileState,
  List<Unit> extraUnits = const [],
  int newWorldOwned = 0,
}) {
  final provinces = List.generate(
    owOwned,
    (i) => Province(
      id: 'oldWorld|p$i',
      regionId: kRegionOldWorld,
      ownerId: _sellerId,
    ),
  );
  final newWorldProvinces = List.generate(
    newWorldOwned,
    (i) => Province(
      id: 'newWorld|n$i',
      regionId: kRegionNewWorld,
      ownerId: _sellerId,
    ),
  );
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: provinces, units: extraUnits),
      newWorld: RegionData(provinces: newWorldProvinces),
      resourceByTileKey: resourceByTileKey,
      tileState: tileState ?? TileMapState(),
    ),
    players: [
      Player(
        id: _sellerId,
        displayName: 'Seller',
        isHuman: false,
        treasury: cheapestRegimentBuildTreasuryCost(),
        stockpile: stockpile,
      ),
    ],
  );
}

void main() {
  group(
    'sellerNeedsImprovementInputFeedstockTileAcquisition '
    '(Refs #2847 H8-extraction seller feedstock-tile acquisition)',
    () {
      test(
        'true when the seller needs lumber/castIron but owns no '
        'timber/iron feedstock tile',
        () {
          final game = _belowQuotaSellerGame(
            resourceByTileKey: const {_grainTile: 'grain', _woolTile: 'wool'},
          );
          expect(
            sellerNeedsImprovementInputFeedstockTileAcquisition(game, _sellerId),
            isTrue,
          );
        },
      );

      test(
        'false when the seller owns an unimproved timber tile '
        '(routing gate covers it)',
        () {
          final game = _belowQuotaSellerGame();
          expect(
            sellerNeedsImprovementInputFeedstockTileAcquisition(game, _sellerId),
            isFalse,
          );
        },
      );

      test(
        'false when the only timber tile is already improved '
        '(improved-tile residual, not acquisition)',
        () {
          final game = _belowQuotaSellerGame(
            tileState: TileMapState().setImprovement(_timberTile, 1),
          );
          expect(
            sellerNeedsImprovementInputFeedstockTileAcquisition(game, _sellerId),
            isFalse,
          );
        },
      );

      test(
        'false when the seller owns an iron feedstock tile but no timber '
        '(owns a feedstock tile — out of acquisition scope)',
        () {
          final game = _belowQuotaSellerGame(
            resourceByTileKey: const {
              _grainTile: 'grain',
              _woolTile: 'wool',
              _ironTile: 'iron',
            },
          );
          expect(
            sellerNeedsImprovementInputFeedstockTileAcquisition(game, _sellerId),
            isFalse,
          );
        },
      );

      test('false for a player at the conquest quota (gate inactive)', () {
        final game = _belowQuotaSellerGame(
          owOwned: kObserverConquestMinOwProvincesPerGp,
          resourceByTileKey: const {_grainTile: 'grain', _woolTile: 'wool'},
        );
        expect(
          sellerNeedsImprovementInputFeedstockTileAcquisition(game, _sellerId),
          isFalse,
        );
      });

      test('false when the seller owns a New World province (gate inactive)', () {
        final game = _belowQuotaSellerGame(
          newWorldOwned: 1,
          resourceByTileKey: const {_grainTile: 'grain', _woolTile: 'wool'},
        );
        expect(
          sellerNeedsImprovementInputFeedstockTileAcquisition(game, _sellerId),
          isFalse,
        );
      });

      test('false when the seller owns a regiment (gate inactive)', () {
        final game = _belowQuotaSellerGame(
          resourceByTileKey: const {_grainTile: 'grain', _woolTile: 'wool'},
          extraUnits: [
            Unit(
              id: 'r1',
              type: 'peasant_levies',
              ownerId: _sellerId,
              locationProvinceId: 'oldWorld|p0',
            ),
          ],
        );
        expect(
          sellerNeedsImprovementInputFeedstockTileAcquisition(game, _sellerId),
          isFalse,
        );
      });

      test(
        'false when the seller already holds both improvement inputs',
        () {
          final game = _belowQuotaSellerGame(
            resourceByTileKey: const {_grainTile: 'grain', _woolTile: 'wool'},
            stockpile: const Stockpile(
              quantities: {'lumber': 1, 'castIron': 1},
            ),
          );
          expect(
            sellerNeedsImprovementInputFeedstockTileAcquisition(game, _sellerId),
            isFalse,
          );
        },
      );

      test('evaluation is deterministic', () {
        final game = _belowQuotaSellerGame(
          resourceByTileKey: const {_grainTile: 'grain', _woolTile: 'wool'},
        );
        final a = sellerNeedsImprovementInputFeedstockTileAcquisition(
          game,
          _sellerId,
        );
        final b = sellerNeedsImprovementInputFeedstockTileAcquisition(
          game,
          _sellerId,
        );
        expect(a, equals(b));
      });
    },
  );
}
