import 'package:colonizethis_app/features/game/widgets/split_army_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/split_entity_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/split_fleet_dialog.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('SplitEntityDialog.canConfirmSplit', () {
    test('non-home: requires >=1 on source and >0 on new side', () {
      expect(
        SplitEntityDialog.canConfirmSplit(
          left: const {'a': 1},
          right: const {'a': 1},
          isHomeEntity: false,
        ),
        isTrue,
      );
    });

    test('non-home: empty source is rejected even when new side has items', () {
      expect(
        SplitEntityDialog.canConfirmSplit(
          left: const {'a': 0},
          right: const {'a': 2},
          isHomeEntity: false,
        ),
        isFalse,
      );
    });

    test('non-home: empty new side is rejected', () {
      expect(
        SplitEntityDialog.canConfirmSplit(
          left: const {'a': 2},
          right: const {},
          isHomeEntity: false,
        ),
        isFalse,
      );
    });

    test('home: may move everything (only new side must be non-empty)', () {
      expect(
        SplitEntityDialog.canConfirmSplit(
          left: const {'a': 0},
          right: const {'a': 1},
          isHomeEntity: true,
        ),
        isTrue,
      );
    });

    test('home: empty new side is still rejected', () {
      expect(
        SplitEntityDialog.canConfirmSplit(
          left: const {'a': 1},
          right: const {},
          isHomeEntity: true,
        ),
        isFalse,
      );
    });
  });

  group('split dialogs share the SplitEntityDialog base', () {
    Game minimalGame() {
      const province = Province(
        id: 'cap',
        regionId: 'oldWorld',
        displayName: 'Lisbon',
      );
      return Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(provinces: [province]),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
        ],
      );
    }

    test('SplitArmyDialog is a SplitEntityDialog', () {
      final dialog = SplitArmyDialog(
        army: const Army(
          id: 'army_1',
          ownerId: 'gp1',
          regionId: 'oldWorld',
          stationedProvinceId: 'oldWorld|cap',
          regimentUnitIds: ['levy_1'],
        ),
        game: minimalGame(),
        humanPlayerId: 'gp1',
        bus: AppEventBus.create(),
        isHomeArmy: false,
      );
      expect(dialog, isA<SplitEntityDialog>());
    });

    test('SplitFleetDialog is a SplitEntityDialog', () {
      final dialog = SplitFleetDialog(
        originalFleet: Fleet(
          id: 'f1',
          ownerId: 'gp1',
          regionId: 'oldWorld',
          seaZoneId: 'oldWorld|s1',
          shipTypeIds: const ['carrack'],
        ),
        game: minimalGame(),
        humanPlayerId: 'gp1',
        bus: AppEventBus.create(),
        isHomeFleet: false,
      );
      expect(dialog, isA<SplitEntityDialog>());
    });
  });
}
