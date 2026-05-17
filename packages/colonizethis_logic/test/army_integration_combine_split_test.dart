import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  suppressLogsForTests();

  group('applyArmyCombine and applyArmySplit', () {
    test('combine merges two armies in same province', () {
      const p = 'oldWorld|p1';
      const playerId = 'gp1';
      var game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: p, regionId: 'oldWorld', ownerId: playerId),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
          armies: [
            Army(
              id: 'a1',
              ownerId: playerId,
              regionId: 'oldWorld',
              stationedProvinceId: p,
              regimentUnitIds: const ['u1'],
              isHomeArmy: false,
            ),
            Army(
              id: 'a2',
              ownerId: playerId,
              regionId: 'oldWorld',
              stationedProvinceId: p,
              regimentUnitIds: const ['u2'],
              isHomeArmy: false,
            ),
          ],
        ),
        players: [
          Player(
            id: playerId,
            displayName: 'P',
            capitalProvinceId: p,
            isHuman: true,
          ),
        ],
      );

      game = applyArmyCombine(
        game: game,
        playerId: playerId,
        armyIds: const ['a1', 'a2'],
      );

      expect(game.worldState.armies.length, 1);
      expect(game.worldState.armies.single.regimentUnitIds, ['u1', 'u2']);
    });

    test('split moves subset to new army', () {
      const p = 'oldWorld|p1';
      const playerId = 'gp1';
      var game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          armies: [
            Army(
              id: 'src',
              ownerId: playerId,
              regionId: 'oldWorld',
              stationedProvinceId: p,
              regimentUnitIds: const ['u1', 'u2', 'u3'],
              isHomeArmy: false,
            ),
          ],
          nextArmySeq: 5,
        ),
        players: [
          Player(
            id: playerId,
            displayName: 'P',
            capitalProvinceId: p,
            isHuman: true,
          ),
        ],
      );

      game = applyArmySplit(
        game: game,
        playerId: playerId,
        sourceArmyId: 'src',
        unitIdsToMove: const ['u2'],
      );

      expect(game.worldState.armies.length, 2);
      final src = game.worldState.armies.where((a) => a.id == 'src').single;
      final spun = game.worldState.armies.where((a) => a.id != 'src').single;
      expect(src.regimentUnitIds, ['u1', 'u3']);
      expect(spun.regimentUnitIds, ['u2']);
      expect(spun.stationedProvinceId, p);
    });

    test('split from home army moves all regiments to new army', () {
      const p = 'oldWorld|p1';
      const playerId = 'gp1';
      var game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          armies: [
            Army(
              id: 'home_army',
              ownerId: playerId,
              regionId: 'oldWorld',
              stationedProvinceId: p,
              regimentUnitIds: const ['u1', 'u2'],
              isHomeArmy: true,
            ),
          ],
          nextArmySeq: 5,
        ),
        players: [
          Player(
            id: playerId,
            displayName: 'P',
            capitalProvinceId: p,
            isHuman: true,
          ),
        ],
      );

      game = applyArmySplit(
        game: game,
        playerId: playerId,
        sourceArmyId: 'home_army',
        unitIdsToMove: const ['u1', 'u2'],
      );

      expect(game.worldState.armies.length, 2);
      final home = game.worldState.armies.where((a) => a.isHomeArmy).single;
      final spun = game.worldState.armies.where((a) => !a.isHomeArmy).single;
      expect(home.regimentUnitIds, isEmpty);
      expect(spun.regimentUnitIds, ['u1', 'u2']);
      expect(spun.id, 'army_5');
      expect(spun.stationedProvinceId, p);
    });

    test('split non-home with all regiments leaves state unchanged', () {
      const p = 'oldWorld|p1';
      const playerId = 'gp1';
      var game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          armies: [
            Army(
              id: 'src',
              ownerId: playerId,
              regionId: 'oldWorld',
              stationedProvinceId: p,
              regimentUnitIds: const ['u1', 'u2'],
              isHomeArmy: false,
            ),
          ],
          nextArmySeq: 5,
        ),
        players: [
          Player(
            id: playerId,
            displayName: 'P',
            capitalProvinceId: p,
            isHuman: true,
          ),
        ],
      );

      game = applyArmySplit(
        game: game,
        playerId: playerId,
        sourceArmyId: 'src',
        unitIdsToMove: const ['u1', 'u2'],
      );

      expect(game.worldState.armies.length, 1);
      expect(game.worldState.armies.single.regimentUnitIds, ['u1', 'u2']);
    });
  });
}
