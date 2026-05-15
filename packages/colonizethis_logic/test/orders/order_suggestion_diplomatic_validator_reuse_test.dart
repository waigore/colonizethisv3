import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Two GPs at peace: each target's non-economic pass accepts [alliance]; the
/// economic pass must rebind via [forBasePrefix], not rebuild validators.
Game _twoGpPeaceGame() {
  return Game(
    id: 'g_diplomatic_validator_reuse',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'GP1', isHuman: false),
      Player(id: 'gp2', displayName: 'GP2', isHuman: false),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
        state: RelationState.atPeace,
        level: RelationLevel.neutral,
      ),
    ],
  );
}

void main() {
  suppressLogsForTests();

  group('suggestDiplomaticOrders validator reuse (Refs #2394)', () {
    test(
      'builds one pass-level validator across multiple diplomatic targets',
      () {
        const topology = MapTopology(nodes: [], edges: []);
        final game = _twoGpPeaceGame();
        final view = buildPlayerView(game, topology, 'gp1');

        resetIncrementalCandidateValidatorBuildCountForTests();
        final suggestions = suggestDiplomaticOrders(
          view,
          game,
          topology,
          const Orders(),
        );

        expect(
          suggestions.where((o) => o.targetFactionId == 'gp2'),
          hasLength(1),
        );
        expect(suggestions.single.type, DiplomaticOrderType.alliance);
        expect(
          incrementalCandidateValidatorBuildCountForTests,
          1,
          reason:
              'one pass-level build; must not call buildIncrementalCandidateValidator '
              'per target for the economic pass (Refs #2394)',
        );
      },
    );

    test(
      'rebinds pass validator to workingOrders after each target',
      () {
        const topology = MapTopology(nodes: [], edges: []);
        final game = Game(
          id: 'g_diplomatic_rebind',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'GP1', isHuman: false),
            Player(id: 'gp2', displayName: 'GP2', isHuman: false),
            Player(id: 'gp3', displayName: 'GP3', isHuman: false),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp2',
              state: RelationState.atPeace,
              level: RelationLevel.neutral,
            ),
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp3',
              state: RelationState.atPeace,
              level: RelationLevel.neutral,
            ),
          ],
        );
        final view = buildPlayerView(game, topology, 'gp1');

        resetIncrementalCandidateValidatorBuildCountForTests();
        final suggestions = suggestDiplomaticOrders(
          view,
          game,
          topology,
          const Orders(),
        );

        expect(suggestions, hasLength(2));
        expect(
          suggestions.map((o) => o.targetFactionId).toSet(),
          {'gp2', 'gp3'},
        );
        expect(
          incrementalCandidateValidatorBuildCountForTests,
          1,
          reason:
              'one pass-level build across three targets (Refs #2394)',
        );
      },
    );
  });
}
