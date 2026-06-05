import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// Refs #2847 § H8-extraction seller feedstock. Single-player fixture: a
// below-quota zero-NW lock-recovery seller that needs its own level-0
// `build_improvement` inputs (`lumber` / `castIron`) and owns an unimproved
// `timber` feedstock tile to extract them from. The seller also owns an
// unimproved `wool` tile (the `peasant_levies` regiment-build-input feedstock)
// so the improvement-cost gate (`regimentBuildInputFeedstockImprovementInputCost`)
// is active — the precondition for the seller improvement-input gate.
const _sellerId = 'gp1';

// The grain tile key is lexicographically smaller than the timber tile key, so
// ordinary build-improvement ordering (equal base score, lexicographic
// tie-break) selects grain; only the active seller feedstock score boost flips
// the Builder onto the timber tile.
const _grainTile = 'oldWorld|p0|0|0';
const _timberTile = 'oldWorld|p0|1|0';
const _woolTile = 'oldWorld|p0|2|0';

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
}) {
  final provinces = List.generate(
    owOwned,
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
      oldWorld: RegionData(provinces: provinces, units: extraUnits),
      newWorld: const RegionData(),
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

PlayerView _sellerBuilderView(Game game) {
  return PlayerView(
    playerId: _sellerId,
    player: game.players.firstWhere((p) => p.id == _sellerId),
    ownUnitsById: {
      'b1': Unit(
        id: 'b1',
        type: kUnitTypeBuilder,
        ownerId: _sellerId,
        locationProvinceId: 'oldWorld|p0',
      ),
    },
    provincesById: const {},
    visibilityByTile: const {},
    prospectedTiles: const {},
    diplomacyByOtherId: const {},
  );
}

void main() {
  group('sellerImprovementInputFeedstockExtractionResourceIds '
      '(Refs #2847 H8-extraction seller feedstock)', () {
    test('active gate returns improvement-input feedstock {timber, iron}', () {
      final game = _belowQuotaSellerGame();
      expect(
        sellerImprovementInputFeedstockExtractionResourceIds(game, _sellerId),
        containsAll(<String>['timber', 'iron']),
      );
    });

    test('returns empty for a player at the conquest quota', () {
      final game = _belowQuotaSellerGame(
        owOwned: kObserverConquestMinOwProvincesPerGp,
      );
      expect(
        sellerImprovementInputFeedstockExtractionResourceIds(game, _sellerId),
        isEmpty,
      );
    });

    test('returns empty when the seller owns a regiment', () {
      final game = _belowQuotaSellerGame(
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
        sellerImprovementInputFeedstockExtractionResourceIds(game, _sellerId),
        isEmpty,
      );
    });

    test(
      'returns empty when the seller already holds both improvement inputs',
      () {
        final game = _belowQuotaSellerGame(
          stockpile: const Stockpile(quantities: {'lumber': 1, 'castIron': 1}),
        );
        expect(
          sellerImprovementInputFeedstockExtractionResourceIds(game, _sellerId),
          isEmpty,
        );
      },
    );

    test(
      'returns empty when the seller owns no unimproved timber/iron tile',
      () {
        // Only wool + grain tiles: the regiment / improvement-cost gates stay
        // active, but the seller owns no feedstock tile for lumber / castIron.
        final game = _belowQuotaSellerGame(
          resourceByTileKey: const {_grainTile: 'grain', _woolTile: 'wool'},
        );
        expect(
          sellerImprovementInputFeedstockExtractionResourceIds(game, _sellerId),
          isEmpty,
        );
      },
    );

    test('returns empty when the only timber tile is already improved', () {
      final game = _belowQuotaSellerGame(
        tileState: TileMapState().setImprovement(_timberTile, 1),
      );
      expect(
        sellerImprovementInputFeedstockExtractionResourceIds(game, _sellerId),
        isEmpty,
      );
    });

    test('evaluation is deterministic', () {
      final game = _belowQuotaSellerGame();
      final a = sellerImprovementInputFeedstockExtractionResourceIds(
        game,
        _sellerId,
      );
      final b = sellerImprovementInputFeedstockExtractionResourceIds(
        game,
        _sellerId,
      );
      expect(a, equals(b));
    });
  });

  group('selectFullAiCivilianWorkOrders seller improvement-input feedstock '
      'extraction (Refs #2847 H8-extraction seller feedstock)', () {
    test('seller Builder prefers timber feedstock tile over grain', () {
      final game = _belowQuotaSellerGame();
      final suggestions = [
        const WorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: _grainTile,
        ),
        const WorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: _timberTile,
        ),
      ];
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: suggestions,
        view: _sellerBuilderView(game),
        game: game,
      );
      expect(r.workOrders, hasLength(1));
      expect(r.workOrders.single.targetTileKey, _timberTile);
    });

    test(
      'seller keeps ordinary ordering when the gate is inactive (at quota)',
      () {
        final game = _belowQuotaSellerGame(
          owOwned: kObserverConquestMinOwProvincesPerGp,
        );
        final suggestions = [
          const WorkOrder(
            unitId: 'b1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: _grainTile,
          ),
          const WorkOrder(
            unitId: 'b1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: _timberTile,
          ),
        ];
        final r = selectFullAiCivilianWorkOrders(
          workSuggestions: suggestions,
          view: _sellerBuilderView(game),
          game: game,
        );
        // No feedstock boost → ordinary deterministic ordering selects the
        // lexicographically smaller grain tile key.
        expect(r.workOrders.single.targetTileKey, _grainTile);
      },
    );

    test('selection is deterministic when the seller gate is active', () {
      final game = _belowQuotaSellerGame();
      final suggestions = [
        const WorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: _grainTile,
        ),
        const WorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: _timberTile,
        ),
      ];
      final view = _sellerBuilderView(game);
      final a = selectFullAiCivilianWorkOrders(
        workSuggestions: suggestions,
        view: view,
        game: game,
      );
      final b = selectFullAiCivilianWorkOrders(
        workSuggestions: suggestions,
        view: view,
        game: game,
      );
      expect(a.workOrders, equals(b.workOrders));
    });
  });
}
