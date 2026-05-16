import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/src/planning/army_conquest_prep.dart';
import 'package:colonizethis_ai/src/planning/goal_manager.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('prepareConquestFieldArmy', () {
    test('splits regiments from home army when pursuing conquer', () {
      const cap = 'oldWorld|cap';
      var game = Game(
        id: 'g_prep',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: cap,
                regionId: 'oldWorld',
                ownerId: 'gp1',
                townTileKey: 'oldWorld|cap|0|0',
              ),
            ],
          ),
          newWorld: const RegionData(provinces: [], units: []),
          armies: [
            Army(
              id: homeArmyIdFor('gp1'),
              ownerId: 'gp1',
              regionId: 'oldWorld',
              stationedProvinceId: cap,
              regimentUnitIds: const ['u1', 'u2', 'u3'],
              isHomeArmy: true,
            ),
          ],
          nextArmySeq: 2,
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'GP',
            isHuman: false,
            leaderKey: 'napoleon',
            capitalProvinceId: cap,
          ),
        ],
      );

      game = prepareConquestFieldArmy(
        game: game,
        nationId: 'gp1',
        provincesToVictory: 24,
        primaryGoal: StrategicGoal.conquer,
      );

      final home = game.worldState.armies
          .singleWhere((a) => a.id == homeArmyIdFor('gp1'));
      final field = game.worldState.armies
          .where((a) => a.ownerId == 'gp1' && !a.isHomeArmy)
          .toList();
      expect(home.regimentUnitIds.length, 2);
      expect(field.length, 1);
      expect(field.single.regimentUnitIds.length, 1);
      expect(field.single.isHomeArmy, isFalse);
    });

    test('no-op when field army already has regiments at capital', () {
      const cap = 'oldWorld|cap';
      final game = Game(
        id: 'g_prep2',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: cap,
                regionId: 'oldWorld',
                ownerId: 'gp1',
                townTileKey: 'oldWorld|cap|0|0',
              ),
            ],
          ),
          newWorld: const RegionData(provinces: [], units: []),
          armies: [
            Army(
              id: homeArmyIdFor('gp1'),
              ownerId: 'gp1',
              regionId: 'oldWorld',
              stationedProvinceId: cap,
              regimentUnitIds: const ['u1', 'u2', 'u3'],
              isHomeArmy: true,
            ),
            Army(
              id: 'army_field',
              ownerId: 'gp1',
              regionId: 'oldWorld',
              stationedProvinceId: cap,
              regimentUnitIds: const ['u4'],
              isHomeArmy: false,
            ),
          ],
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'GP',
            isHuman: false,
            leaderKey: 'napoleon',
            capitalProvinceId: cap,
          ),
        ],
      );

      final after = prepareConquestFieldArmy(
        game: game,
        nationId: 'gp1',
        provincesToVictory: 24,
        primaryGoal: StrategicGoal.conquer,
      );

      expect(after.worldState.armies.length, game.worldState.armies.length);
    });
  });
}
