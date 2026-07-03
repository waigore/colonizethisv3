import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Engineer civilian-work scoring (Refs #3794 § Engineer, AC11..AC17).
///
/// Verifies the unified Engineer scored pool (`build_road` / `build_port` /
/// `build_fort`) replaces the lexicographic fallback (which always picked
/// `build_fort` first alphabetically): per-target base weights plus contextual
/// bonuses steer selection, ties break by province id, and the other per-type
/// paths are unaffected.
void main() {
  const playerId = 'gp1';

  Game gameWith({
    Map<String, String> resourceByTileKey = const {},
    String? capitalProvinceId,
  }) => Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
      resourceByTileKey: resourceByTileKey,
    ),
    players: [
      Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        capitalProvinceId: capitalProvinceId,
      ),
    ],
  );

  PlayerView engineerViewFor(
    Game game, {
    String locationProvinceId = 'oldWorld|p1',
  }) => PlayerView(
    playerId: playerId,
    player: game.players.single,
    ownUnitsById: {
      'e1': Unit(
        id: 'e1',
        type: kUnitTypeEngineer,
        ownerId: playerId,
        locationProvinceId: locationProvinceId,
      ),
    },
    provincesById: const {},
    visibilityByTile: const {},
    prospectedTiles: const {},
    diplomacyByOtherId: const {},
  );

  WorkOrder eng(String target, String tileKey) =>
      WorkOrder(unitId: 'e1', target: target, targetTileKey: tileKey);

  group('Engineer unified build scoring', () {
    test('AC11: resource road beats alphabetically-first plain fort', () {
      const roadTile = 'oldWorld|p1|1|0';
      const fortTile = 'oldWorld|p1|0|0';
      final game = gameWith(resourceByTileKey: const {roadTile: 'coal'});
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          eng(kWorkTargetBuildFort, fortTile),
          eng(kWorkTargetBuildRoad, roadTile),
        ],
        view: engineerViewFor(game),
        game: game,
      );
      expect(r.workOrders, hasLength(1));
      expect(r.workOrders.single.target, kWorkTargetBuildRoad);
      expect(r.workOrders.single.targetTileKey, roadTile);
      expect(r.idleEvents, isEmpty);
    });

    test('AC12: resource-carrying port beats plain port', () {
      const portResource = 'oldWorld|p1|1|0';
      const portPlain = 'oldWorld|p1|0|0';
      final game = gameWith(resourceByTileKey: const {portResource: 'iron'});
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          eng(kWorkTargetBuildPort, portPlain),
          eng(kWorkTargetBuildPort, portResource),
        ],
        view: engineerViewFor(game),
        game: game,
      );
      expect(r.workOrders.single.target, kWorkTargetBuildPort);
      expect(r.workOrders.single.targetTileKey, portResource);
    });

    test('AC13: capital-province fort beats non-capital fort', () {
      const fortCapital = 'oldWorld|cap|0|0';
      const fortOther = 'oldWorld|p1|0|0';
      final game = gameWith(capitalProvinceId: 'oldWorld|cap');
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          eng(kWorkTargetBuildFort, fortOther),
          eng(kWorkTargetBuildFort, fortCapital),
        ],
        view: engineerViewFor(game),
        game: game,
      );
      expect(r.workOrders.single.target, kWorkTargetBuildFort);
      expect(r.workOrders.single.targetTileKey, fortCapital);
    });

    test('AC14: single plain fort candidate is selected (non-zero baseline)', () {
      const tile = 'oldWorld|p1|0|0';
      final game = gameWith();
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [eng(kWorkTargetBuildFort, tile)],
        view: engineerViewFor(game),
        game: game,
      );
      expect(r.workOrders.single.target, kWorkTargetBuildFort);
      expect(r.workOrders.single.targetTileKey, tile);
      expect(r.idleEvents, isEmpty);
    });

    test('AC15: idle Engineer with no candidates logs no_suggestions', () {
      final game = gameWith();
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: const [],
        view: engineerViewFor(game),
        game: game,
      );
      expect(r.workOrders, isEmpty);
      expect(r.idleEvents, hasLength(1));
      expect(r.idleEvents.single.unitId, 'e1');
      expect(r.idleEvents.single.reason, 'no_suggestions');
    });

    test('AC16: equal scores break by province id (p1 before p2)', () {
      const tileP2 = 'oldWorld|p2|0|0';
      const tileP1 = 'oldWorld|p1|0|0';
      final game = gameWith();
      final first = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          eng(kWorkTargetBuildRoad, tileP2),
          eng(kWorkTargetBuildRoad, tileP1),
        ],
        view: engineerViewFor(game),
        game: game,
      );
      final second = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          eng(kWorkTargetBuildRoad, tileP1),
          eng(kWorkTargetBuildRoad, tileP2),
        ],
        view: engineerViewFor(game),
        game: game,
      );
      expect(first.workOrders.single.targetTileKey, tileP1);
      expect(second.workOrders.single.targetTileKey, tileP1);
    });

    test('Rail Builder path is unaffected by the Engineer scorer', () {
      const railResource = 'oldWorld|p1|1|0';
      const railPlain = 'oldWorld|p1|0|0';
      final game = gameWith(resourceByTileKey: const {railResource: 'coal'});
      final view = PlayerView(
        playerId: playerId,
        player: game.players.single,
        ownUnitsById: {
          'r1': Unit(
            id: 'r1',
            type: kUnitTypeRailBuilder,
            ownerId: playerId,
            locationProvinceId: 'oldWorld|p1',
          ),
        },
        provincesById: const {},
        visibilityByTile: const {},
        prospectedTiles: const {},
        diplomacyByOtherId: const {},
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: const [
          WorkOrder(
            unitId: 'r1',
            target: kWorkTargetBuildRail,
            targetTileKey: railPlain,
          ),
          WorkOrder(
            unitId: 'r1',
            target: kWorkTargetBuildRail,
            targetTileKey: railResource,
          ),
        ],
        view: view,
        game: game,
      );
      expect(r.workOrders.single.target, kWorkTargetBuildRail);
      expect(r.workOrders.single.targetTileKey, railResource);
    });
  });

  group('Engineer GA tunability (AC17)', () {
    test('all engineer scoring constants are registered in the registry', () {
      for (final name in const [
        'kEngineerBuildRoadBaseWorkScore',
        'kEngineerBuildPortBaseWorkScore',
        'kEngineerBuildFortBaseWorkScore',
        'kEngineerRoadResourceConnectivityBonus',
        'kEngineerRoadCapitalLogisticsBonus',
        'kEngineerPortResourceExtractionBonus',
        'kEngineerPortNewWorldCoastalBonus',
        'kEngineerFortCapitalDefenseBonus',
        'kEngineerFortNewWorldBorderBonus',
      ]) {
        final p = AiParameterRegistry.byName(name);
        expect(p, isNotNull, reason: name);
        expect(p!.category, AiParameterCategory.victoryConfig, reason: name);
      }
    });
  });
}
