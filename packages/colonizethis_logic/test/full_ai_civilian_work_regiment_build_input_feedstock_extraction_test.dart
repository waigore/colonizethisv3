import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const _playerId = 'gp1';
const _tileGrain = 'oldWorld|p0|0|0';
const _tileWool = 'oldWorld|p0|1|0';

Game _belowQuotaZeroNwSellerGame({
  required int owOwned,
  required int treasury,
  Stockpile stockpile = const Stockpile(),
  List<Unit> extraUnits = const [],
  Map<String, String> resourceByTileKey = const {
    _tileGrain: 'grain',
    _tileWool: 'wool',
  },
  TileMapState? tileState,
}) {
  final provinces = List.generate(
    owOwned,
    (i) => Province(
      id: 'oldWorld|p$i',
      regionId: kRegionOldWorld,
      ownerId: _playerId,
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
        id: _playerId,
        displayName: 'GP',
        isHuman: false,
        treasury: treasury,
        stockpile: stockpile,
      ),
    ],
  );
}

PlayerView _builderView(Game game) {
  return PlayerView(
    playerId: _playerId,
    player: game.players.single,
    ownUnitsById: {
      'b1': Unit(
        id: 'b1',
        type: kUnitTypeBuilder,
        ownerId: _playerId,
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
  group('regimentBuildInputFeedstockExtractionResourceIds (Refs #2847 H8-extraction)', () {
    test('active gate returns wool and cotton feedstock ids', () {
      final game = _belowQuotaZeroNwSellerGame(
        owOwned: 5,
        treasury: cheapestRegimentBuildTreasuryCost(),
      );
      expect(
        regimentBuildInputFeedstockExtractionResourceIds(game, _playerId),
        containsAll(['wool', 'cotton']),
      );
    });

    test('treasury-independent: returns wool/cotton even when broke', () {
      // Refs #2847 H8-extraction: the extraction routing gate is
      // treasury-independent (mirrors the production boost) so the Builder is
      // routed onto the feedstock tile while still broke. The market bids and
      // build order remain treasury-gated at their call sites.
      final game = _belowQuotaZeroNwSellerGame(owOwned: 5, treasury: 0);
      expect(
        regimentBuildInputFeedstockExtractionResourceIds(game, _playerId),
        containsAll(['wool', 'cotton']),
      );
    });

    test('returns empty when GP already owns a regiment', () {
      final game = _belowQuotaZeroNwSellerGame(
        owOwned: 5,
        treasury: cheapestRegimentBuildTreasuryCost(),
        extraUnits: [
          Unit(
            id: 'r1',
            type: 'peasant_levies',
            ownerId: _playerId,
            locationProvinceId: 'oldWorld|p0',
          ),
        ],
      );
      expect(
        regimentBuildInputFeedstockExtractionResourceIds(game, _playerId),
        isEmpty,
      );
    });

    test('returns empty when fabric build input is already on hand', () {
      final game = _belowQuotaZeroNwSellerGame(
        owOwned: 5,
        treasury: cheapestRegimentBuildTreasuryCost(),
        stockpile: const Stockpile(quantities: {'fabric': 1}),
      );
      expect(
        regimentBuildInputFeedstockExtractionResourceIds(game, _playerId),
        isEmpty,
      );
    });

    test('returns empty when GP is at or above the conquest quota', () {
      final game = _belowQuotaZeroNwSellerGame(
        owOwned: kObserverConquestMinOwProvincesPerGp,
        treasury: cheapestRegimentBuildTreasuryCost(),
      );
      expect(
        regimentBuildInputFeedstockExtractionResourceIds(game, _playerId),
        isEmpty,
      );
    });

    test('gate evaluation is deterministic', () {
      final game = _belowQuotaZeroNwSellerGame(
        owOwned: 5,
        treasury: cheapestRegimentBuildTreasuryCost(),
      );
      final a = regimentBuildInputFeedstockExtractionResourceIds(game, _playerId);
      final b = regimentBuildInputFeedstockExtractionResourceIds(game, _playerId);
      expect(a, equals(b));
    });
  });

  group('regimentBuildInputFeedstockImprovementInputCost (Refs #2847 H8-extraction)', () {
    test('active gate + owned unimproved feedstock tile returns level-0 cost', () {
      final game = _belowQuotaZeroNwSellerGame(
        owOwned: 5,
        treasury: cheapestRegimentBuildTreasuryCost(),
      );
      expect(
        regimentBuildInputFeedstockImprovementInputCost(game, _playerId),
        equals(workOrderCostBuildImprovement(0)),
      );
    });

    test('returns empty when no feedstock resource tile is owned', () {
      final game = _belowQuotaZeroNwSellerGame(
        owOwned: 5,
        treasury: cheapestRegimentBuildTreasuryCost(),
        resourceByTileKey: const {_tileGrain: 'grain'},
      );
      expect(
        regimentBuildInputFeedstockImprovementInputCost(game, _playerId),
        isEmpty,
      );
    });

    test('returns empty when the feedstock tile is already improved', () {
      final game = _belowQuotaZeroNwSellerGame(
        owOwned: 5,
        treasury: cheapestRegimentBuildTreasuryCost(),
        tileState: TileMapState().setImprovement(_tileWool, 1),
      );
      expect(
        regimentBuildInputFeedstockImprovementInputCost(game, _playerId),
        isEmpty,
      );
    });

    test('treasury-independent: returns level-0 cost even when broke', () {
      // Refs #2847 H8-extraction: the underlying extraction gate is
      // treasury-independent, so the improvement-input cost surfaces while
      // broke. The actual bid stays treasury-gated in treasury_planner.dart
      // (§ Lock-recovery seller regiment build-input bootstrap).
      final game = _belowQuotaZeroNwSellerGame(owOwned: 5, treasury: 0);
      expect(
        regimentBuildInputFeedstockImprovementInputCost(game, _playerId),
        equals(workOrderCostBuildImprovement(0)),
      );
    });

    test('returns empty when GP already owns a regiment', () {
      final game = _belowQuotaZeroNwSellerGame(
        owOwned: 5,
        treasury: cheapestRegimentBuildTreasuryCost(),
        extraUnits: [
          Unit(
            id: 'r1',
            type: 'peasant_levies',
            ownerId: _playerId,
            locationProvinceId: 'oldWorld|p0',
          ),
        ],
      );
      expect(
        regimentBuildInputFeedstockImprovementInputCost(game, _playerId),
        isEmpty,
      );
    });

    test('returns empty when GP is at or above the conquest quota', () {
      final game = _belowQuotaZeroNwSellerGame(
        owOwned: kObserverConquestMinOwProvincesPerGp,
        treasury: cheapestRegimentBuildTreasuryCost(),
      );
      expect(
        regimentBuildInputFeedstockImprovementInputCost(game, _playerId),
        isEmpty,
      );
    });

    test('evaluation is deterministic', () {
      final game = _belowQuotaZeroNwSellerGame(
        owOwned: 5,
        treasury: cheapestRegimentBuildTreasuryCost(),
      );
      expect(
        regimentBuildInputFeedstockImprovementInputCost(game, _playerId),
        equals(regimentBuildInputFeedstockImprovementInputCost(game, _playerId)),
      );
    });
  });

  group('selectFullAiCivilianWorkOrders feedstock extraction (Refs #2847 H8-extraction)', () {
    test('Builder prefers wool feedstock tile over lexicographically smaller grain', () {
      final game = _belowQuotaZeroNwSellerGame(
        owOwned: 5,
        treasury: cheapestRegimentBuildTreasuryCost(),
      );
      final suggestions = [
        const WorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: _tileGrain,
        ),
        const WorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: _tileWool,
        ),
      ];
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: suggestions,
        view: _builderView(game),
        game: game,
      );
      expect(r.workOrders, hasLength(1));
      expect(r.workOrders.single.targetTileKey, _tileWool);
    });

    test('broke below-quota seller still routes Builder to wool feedstock tile', () {
      // Refs #2847 H8-extraction: treasury-independent routing — a broke seller
      // (treasury 0, below the cheapest regiment cost) is still routed onto the
      // feedstock tile so the input can stage ahead of treasury recovery.
      final game = _belowQuotaZeroNwSellerGame(owOwned: 5, treasury: 0);
      final suggestions = [
        const WorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: _tileGrain,
        ),
        const WorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: _tileWool,
        ),
      ];
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: suggestions,
        view: _builderView(game),
        game: game,
      );
      expect(r.workOrders, hasLength(1));
      expect(r.workOrders.single.targetTileKey, _tileWool);
    });

    test('at-quota GP keeps ordinary build-improvement ordering without feedstock boost', () {
      final game = _belowQuotaZeroNwSellerGame(
        owOwned: kObserverConquestMinOwProvincesPerGp,
        treasury: cheapestRegimentBuildTreasuryCost(),
      );
      final suggestions = [
        const WorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: _tileGrain,
        ),
        const WorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: _tileWool,
        ),
      ];
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: suggestions,
        view: _builderView(game),
        game: game,
      );
      expect(r.workOrders.single.targetTileKey, _tileGrain);
    });

    test('selection is deterministic when feedstock gate is active', () {
      final game = _belowQuotaZeroNwSellerGame(
        owOwned: 5,
        treasury: cheapestRegimentBuildTreasuryCost(),
      );
      final suggestions = [
        const WorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: _tileGrain,
        ),
        const WorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: _tileWool,
        ),
      ];
      final view = _builderView(game);
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
