import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Builder `upgrade_town` civilian-work scoring (Refs #3794 § Builder,
/// AC18..AC22).
///
/// Verifies the unified Builder pool scores `build_improvement` and
/// `upgrade_town` together: a high-value town upgrade beats a degenerate
/// improvement, a genuine resource improvement still beats a bare town upgrade,
/// context bonuses steer between town candidates, ties break by province id (not
/// alphabetically), and the GA tunables are registered.
void main() {
  const playerId = 'gp1';

  Game gameWith({
    Map<String, String> resourceByTileKey = const {},
    Map<String, int> improvementByTile = const {},
  }) => Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
      resourceByTileKey: resourceByTileKey,
      tileState: TileMapState(improvementByTile: improvementByTile),
    ),
    players: [
      Player(id: playerId, displayName: 'GP', isHuman: false),
    ],
  );

  PlayerView builderViewFor(Game game) => PlayerView(
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

  WorkOrder town(String tileKey) => WorkOrder(
    unitId: 'b1',
    target: kWorkTargetUpgradeTown,
    targetTileKey: tileKey,
  );

  WorkOrder improvement(String tileKey) => WorkOrder(
    unitId: 'b1',
    target: kWorkTargetBuildImprovement,
    targetTileKey: tileKey,
  );

  group('Builder unified build_improvement + upgrade_town scoring', () {
    test('AC18: high-value town upgrade beats degenerate build_improvement', () {
      const townTile = 'oldWorld|p1|2|0';
      const improvedTile = 'oldWorld|p1|0|0';
      // build_improvement on an already-improved tile scores the sentinel 1;
      // the resource-carrying upgrade_town scores far higher.
      final game = gameWith(
        resourceByTileKey: const {townTile: 'coal'},
        improvementByTile: const {improvedTile: 1},
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [improvement(improvedTile), town(townTile)],
        view: builderViewFor(game),
        game: game,
      );
      expect(r.workOrders, hasLength(1));
      expect(r.workOrders.single.target, kWorkTargetUpgradeTown);
      expect(r.workOrders.single.targetTileKey, townTile);
      expect(r.idleEvents, isEmpty);
    });

    test('AC19: genuine resource improvement still outranks bare town upgrade', () {
      const resourceTile = 'oldWorld|p1|0|0';
      const townTile = 'oldWorld|p1|2|0';
      // upgrade_town is baseline-only (no resource, OW, already-developed tile);
      // build_improvement on an unimproved resource tile scores 580.
      final game = gameWith(
        resourceByTileKey: const {resourceTile: 'grain'},
        improvementByTile: const {townTile: 1},
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [town(townTile), improvement(resourceTile)],
        view: builderViewFor(game),
        game: game,
      );
      expect(r.workOrders.single.target, kWorkTargetBuildImprovement);
      expect(r.workOrders.single.targetTileKey, resourceTile);
    });

    test('AC20: prefers the resource-carrying town tile', () {
      const tileResource = 'oldWorld|p1|1|0';
      const tilePlain = 'oldWorld|p1|0|0';
      final game = gameWith(resourceByTileKey: const {tileResource: 'iron'});
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [town(tilePlain), town(tileResource)],
        view: builderViewFor(game),
        game: game,
      );
      expect(r.workOrders.single.target, kWorkTargetUpgradeTown);
      expect(r.workOrders.single.targetTileKey, tileResource);
    });

    test('AC21: equal scores break by province id (p1 before p2), not order', () {
      const tileP2 = 'oldWorld|p2|0|0';
      const tileP1 = 'oldWorld|p1|0|0';
      final game = gameWith();
      final first = selectFullAiCivilianWorkOrders(
        workSuggestions: [town(tileP2), town(tileP1)],
        view: builderViewFor(game),
        game: game,
      );
      final second = selectFullAiCivilianWorkOrders(
        workSuggestions: [town(tileP1), town(tileP2)],
        view: builderViewFor(game),
        game: game,
      );
      expect(first.workOrders.single.targetTileKey, tileP1);
      expect(second.workOrders.single.targetTileKey, tileP1);
    });

    test('single plain town candidate is selected (non-zero baseline)', () {
      const tile = 'oldWorld|p1|0|0';
      final game = gameWith();
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [town(tile)],
        view: builderViewFor(game),
        game: game,
      );
      expect(r.workOrders.single.target, kWorkTargetUpgradeTown);
      expect(r.workOrders.single.targetTileKey, tile);
      expect(r.idleEvents, isEmpty);
    });

    test('build_improvement-only selection is unchanged (no regression)', () {
      const resourceTile = 'oldWorld|p1|1|0';
      const plainTile = 'oldWorld|p1|0|0';
      final game = gameWith(resourceByTileKey: const {resourceTile: 'grain'});
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [improvement(plainTile), improvement(resourceTile)],
        view: builderViewFor(game),
        game: game,
      );
      expect(r.workOrders.single.target, kWorkTargetBuildImprovement);
      expect(r.workOrders.single.targetTileKey, resourceTile);
    });
  });

  group('Builder upgrade_town GA tunability (AC22)', () {
    test('all upgrade_town scoring constants are registered', () {
      for (final name in const [
        'kUpgradeTownBaseWorkScore',
        'kUpgradeTownResourceValueBonus',
        'kUpgradeTownFrontlineBonus',
        'kUpgradeTownLowDevBonus',
      ]) {
        final param = AiParameterRegistry.byName(name);
        expect(param, isNotNull, reason: name);
        expect(param!.category, AiParameterCategory.victoryConfig, reason: name);
      }
    });
  });
}
