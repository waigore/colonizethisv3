import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  suppressLogsForTests();

  group('naval suggestion sharedCandidateValidator (Refs #2394)', () {
    test(
      'suggestNavalMoveOrders and suggestNavalMissionOrders reuse one validator',
      () {
        const topology = MapTopology(nodes: [], edges: []);
        final game = Game(
          id: 'g_naval_validator_reuse',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'f1',
                ownerId: 'gp1',
                seaZoneId: 'sea1',
                regionId: 'oldWorld',
                shipTypeIds: const ['carrack'],
              ),
            ],
          ),
          players: const [
            Player(id: 'gp1', displayName: 'GP1', isHuman: false),
          ],
        );
        final view = buildPlayerView(game, topology, 'gp1');
        const orders = Orders();

        final shared = IncrementalCandidateValidator.forPlayer(
          game: game,
          topology: topology,
          playerId: 'gp1',
          basePrefix: orders,
          view: view,
          unitsById: unitsByIdFromWorld(game.worldState),
        );

        resetIncrementalCandidateValidatorBuildCountForTests();
        suggestNavalMoveOrders(
          view,
          game,
          topology,
          orders,
          sharedCandidateValidator: shared,
        );
        suggestNavalMissionOrders(
          view,
          game,
          topology,
          orders,
          sharedCandidateValidator: shared,
        );

        expect(
          incrementalCandidateValidatorBuildCountForTests,
          0,
          reason:
              'both naval families must reuse the supplied pass validator '
              '(Refs #2394)',
        );
      },
    );
  });
}
