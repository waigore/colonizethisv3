// Unit tests for general command capacity helpers (#4233).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/units/military/general_command_capacity.dart';

void main() {
  suppressLogsForTests();

  const human = 'gp1';
  const rival = 'gp2';

  Game gameWithGenerals({
    List<General> generals = const [],
    Player? player,
    List<Province> provinces = const [],
    List<ArmyMoveOrder> draftMoves = const [],
  }) {
    return Game(
      id: 'g',
      players: [
        player ??
            Player(
              id: human,
              displayName: 'Human',
              isHuman: true,
              generalCap: 3,
            ),
      ],
      generals: generals,
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: provinces,
          units: const [],
        ),
        newWorld: const RegionData(),
      ),
    );
  }

  group('humanGeneralCountForDisplay', () {
    test('returns roster size when generals exist', () {
      final game = gameWithGenerals(
        generals: const [
          General(id: 'g1', ownerId: human, medals: 0),
          General(id: 'g2', ownerId: human, medals: 2),
        ],
      );
      expect(humanGeneralCountForDisplay(game, human), 2);
    });

    test('falls back to 1 when roster empty but cap positive', () {
      final game = gameWithGenerals(generals: const []);
      expect(humanGeneralCountForDisplay(game, human), 1);
    });
  });

  group('isArmyMoveInvasionDestination', () {
    test('owned province is not invasion', () {
      final game = gameWithGenerals(
        provinces: [
          Province(id: 'oldWorld|own', regionId: 'oldWorld', ownerId: human),
        ],
      );
      expect(
        isArmyMoveInvasionDestination(game, human, 'oldWorld|own'),
        isFalse,
      );
    });

    test('rival-owned province is invasion', () {
      final game = gameWithGenerals(
        provinces: [
          Province(id: 'oldWorld|rival', regionId: 'oldWorld', ownerId: rival),
        ],
      );
      expect(
        isArmyMoveInvasionDestination(game, human, 'oldWorld|rival'),
        isTrue,
      );
    });
  });

  group('stagedInvasionCountForTurn', () {
    test('counts invasion orders excluding preview army then adds preview', () {
      final game = gameWithGenerals(
        provinces: [
          Province(id: 'oldWorld|own', regionId: 'oldWorld', ownerId: human),
          Province(id: 'oldWorld|rival', regionId: 'oldWorld', ownerId: rival),
        ],
      );
      final draft = Orders(
        armyMoveOrdersByPlayerId: {
          human: [
            const ArmyMoveOrder(
              armyId: 'a1',
              destinationProvinceId: 'oldWorld|rival',
            ),
            const ArmyMoveOrder(
              armyId: 'a2',
              destinationProvinceId: 'oldWorld|own',
            ),
          ],
        },
      );
      expect(
        stagedInvasionCountForTurn(
          game: game,
          humanPlayerId: human,
          draftOrders: draft,
          previewArmyId: 'a3',
          previewDestinationProvinceId: 'oldWorld|rival',
        ),
        2,
      );
    });
  });
}
