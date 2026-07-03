import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Rail Builder civilian-work scoring (Refs #3794 § Rail Builder, AC-RAIL-1..8).
///
/// Verifies the unified `build_rail` scored pool replaces the lexicographic
/// fallback: resource output, capital-connector, and New World bonuses each
/// steer selection, ties break by province id (not alphabetically), and the
/// other per-type paths are unaffected.
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

  PlayerView railViewFor(Game game, {String locationProvinceId = 'oldWorld|p1'}) =>
      PlayerView(
        playerId: playerId,
        player: game.players.single,
        ownUnitsById: {
          'r1': Unit(
            id: 'r1',
            type: kUnitTypeRailBuilder,
            ownerId: playerId,
            locationProvinceId: locationProvinceId,
          ),
        },
        provincesById: const {},
        visibilityByTile: const {},
        prospectedTiles: const {},
        diplomacyByOtherId: const {},
      );

  WorkOrder rail(String tileKey) =>
      WorkOrder(unitId: 'r1', target: kWorkTargetBuildRail, targetTileKey: tileKey);

  group('Rail Builder build_rail scoring', () {
    test('AC-RAIL-1: prefers the resource-carrying road tile', () {
      const tileA = 'oldWorld|p1|1|0';
      const tileB = 'oldWorld|p1|0|0';
      final game = gameWith(resourceByTileKey: const {tileA: 'coal'});
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [rail(tileA), rail(tileB)],
        view: railViewFor(game),
        game: game,
      );
      expect(r.workOrders, hasLength(1));
      expect(r.workOrders.single.target, kWorkTargetBuildRail);
      expect(r.workOrders.single.targetTileKey, tileA);
      expect(r.idleEvents, isEmpty);
    });

    test('AC-RAIL-2: prefers the capital-province road tile', () {
      const tileCapital = 'oldWorld|cap|1|0';
      const tileOther = 'oldWorld|p1|0|0';
      final game = gameWith(capitalProvinceId: 'oldWorld|cap');
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [rail(tileCapital), rail(tileOther)],
        view: railViewFor(game),
        game: game,
      );
      expect(r.workOrders.single.targetTileKey, tileCapital);
    });

    test('AC-RAIL-3: prefers the New World road tile', () {
      const tileNw = 'newWorld|nw1|0|0';
      const tileOw = 'oldWorld|p1|0|0';
      final game = gameWith();
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [rail(tileNw), rail(tileOw)],
        view: railViewFor(game),
        game: game,
      );
      expect(r.workOrders.single.targetTileKey, tileNw);
    });

    test('AC-RAIL-4: single plain candidate is selected (non-zero baseline)', () {
      const tile = 'oldWorld|p1|0|0';
      final game = gameWith();
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [rail(tile)],
        view: railViewFor(game),
        game: game,
      );
      expect(r.workOrders.single.targetTileKey, tile);
      expect(r.idleEvents, isEmpty);
    });

    test(
      'AC-RAIL-5: equal scores break by province id (p1 before p2), not target',
      () {
        const tileP2 = 'oldWorld|p2|0|0';
        const tileP1 = 'oldWorld|p1|0|0';
        final game = gameWith();
        final first = selectFullAiCivilianWorkOrders(
          workSuggestions: [rail(tileP2), rail(tileP1)],
          view: railViewFor(game),
          game: game,
        );
        final second = selectFullAiCivilianWorkOrders(
          workSuggestions: [rail(tileP1), rail(tileP2)],
          view: railViewFor(game),
          game: game,
        );
        expect(first.workOrders.single.targetTileKey, tileP1);
        expect(second.workOrders.single.targetTileKey, tileP1);
      },
    );

    test('AC-RAIL-6: idle Rail Builder with no candidates logs no_suggestions', () {
      final game = gameWith();
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: const [],
        view: railViewFor(game),
        game: game,
      );
      expect(r.workOrders, isEmpty);
      expect(r.idleEvents, hasLength(1));
      expect(r.idleEvents.single.unitId, 'r1');
      expect(r.idleEvents.single.reason, 'no_suggestions');
    });

    test('AC-RAIL-7: Builder build_improvement path is unaffected', () {
      const resourceTile = 'oldWorld|p1|1|0';
      const roadTile = 'oldWorld|p1|0|0';
      final game = gameWith(resourceByTileKey: const {resourceTile: 'grain'});
      final view = PlayerView(
        playerId: playerId,
        player: game.players.single,
        ownUnitsById: {
          'b1': Unit(
            id: 'b1',
            type: kUnitTypeBuilder,
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
            unitId: 'b1',
            target: kWorkTargetBuildRoad,
            targetTileKey: roadTile,
          ),
          WorkOrder(
            unitId: 'b1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: resourceTile,
          ),
        ],
        view: view,
        game: game,
      );
      expect(r.workOrders.single.target, kWorkTargetBuildImprovement);
      expect(r.workOrders.single.targetTileKey, resourceTile);
    });
  });

  group('Rail Builder GA tunability (AC-RAIL-8)', () {
    test('all rail scoring constants are registered in the parameter registry', () {
      for (final name in const [
        'kBuildRailBaseWorkScore',
        'kBuildRailResourceOutputBonus',
        'kBuildRailCapitalConnectorBonus',
        'kBuildRailNewWorldBonus',
      ]) {
        expect(AiParameterRegistry.byName(name), isNotNull, reason: name);
      }
    });
  });
}
