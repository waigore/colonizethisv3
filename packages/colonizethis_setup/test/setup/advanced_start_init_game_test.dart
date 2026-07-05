import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'init_game_orchestrator_test_support.dart';

int _countUnitsOfType(Game game, String ownerId, String type) {
  return allUnitsFromWorld(game.worldState)
      .where((u) => u.ownerId == ownerId && u.type == type)
      .length;
}

int _countMilitaryRegiments(Game game, String ownerId) {
  return allUnitsFromWorld(game.worldState)
      .where((u) => u.ownerId == ownerId && isMilitaryUnit(u.type))
      .length;
}

void main() {
  group('runInitGame advanced start units slice', () {
    test('turns50 locked profile applies tier civilians regiments and galleon', () {
      final result = runInitGame(
        config: GameSetupConfig(
          advancedStart: AdvancedStartType.turns50,
        ),
        options: defaultInitOptions,
      );
      final game = result.game;
      expect(game.advancedStartType, AdvancedStartType.turns50);
      expect(game.worldState.turnState.turnNumber, 50);

      for (final player in game.players) {
        expect(_countUnitsOfType(game, player.id, kUnitTypeExplorer), 3);
        expect(_countUnitsOfType(game, player.id, kUnitTypeBuilder), 3);
        expect(_countUnitsOfType(game, player.id, kUnitTypeEngineer), 2);
        expect(_countUnitsOfType(game, player.id, kUnitTypeSpy), 1);
        expect(_countUnitsOfType(game, player.id, kUnitTypeMerchant), 1);
        expect(_countMilitaryRegiments(game, player.id), 6);
        final homeFleet = game.worldState.fleets
            .where((f) => f.id == homeFleetIdFor(player.id))
            .singleOrNull;
        expect(homeFleet, isNotNull);
        expect(
          homeFleet!.ships.where((s) => s.typeId == kAdvancedStartCargoShipTypeId),
          hasLength(1),
        );
      }
    });

    test('turns100 locked profile applies rail builder and six galleons', () {
      final result = runInitGame(
        config: GameSetupConfig(
          advancedStart: AdvancedStartType.turns100,
        ),
        options: defaultInitOptions,
      );
      final game = result.game;
      expect(game.advancedStartType, AdvancedStartType.turns100);

      for (final player in game.players) {
        expect(_countUnitsOfType(game, player.id, kUnitTypeRailBuilder), 1);
        expect(_countMilitaryRegiments(game, player.id), 12);
        final homeFleet = game.worldState.fleets
            .where((f) => f.id == homeFleetIdFor(player.id))
            .singleOrNull;
        expect(homeFleet!.ships, hasLength(6));
      }
    });
  });
}
