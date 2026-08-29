import 'package:colonizethis_ai/src/planning/cast_iron_labour_gate.dart'
    show otherGreatPowerFabricHeld;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void registerCastIronLabourGateMarketFabricCases() {
  group('otherGreatPowerFabricHeld (Refs #2847)', () {
    Game gameWithFabric(Map<String, int> fabricByPlayerId) {
      return Game(
        id: 'g-market-fabric',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 40),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: [
          for (final entry in fabricByPlayerId.entries)
            Player(
              id: entry.key,
              displayName: entry.key,
              isHuman: false,
              stockpile: Stockpile.empty.applyDelta(
                CommodityCatalog.fabric.id,
                entry.value,
              ),
            ),
        ],
      );
    }

    test('positive: sums fabric across all other great powers', () {
      final game = gameWithFabric({'gp5': 0, 'gp1': 3, 'gp2': 4});
      expect(otherGreatPowerFabricHeld(game, 'gp5'), 7);
    });

    test('negative: zero when no other great power holds any fabric', () {
      final game = gameWithFabric({'gp5': 0, 'gp1': 0, 'gp2': 0});
      expect(otherGreatPowerFabricHeld(game, 'gp5'), 0);
    });

    test('excludes the queried seller\'s own fabric holdings', () {
      final game = gameWithFabric({'gp5': 9, 'gp1': 0});
      expect(otherGreatPowerFabricHeld(game, 'gp5'), 0);
    });
  });
}
