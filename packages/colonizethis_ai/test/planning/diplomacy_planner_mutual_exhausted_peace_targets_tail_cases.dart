// Tail case bodies for `diplomacy_planner_mutual_exhausted_peace_targets_cases.dart`.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/mutual_exhausted_stalemate_test_support.dart';

void registerMutualExhaustedPeaceTargetsTailCases() {
  group('mutualExhaustedBelowQuotaGpStalematePeaceTargets tail', () {
    test('negative: two GP wars (not sole) returns empty', () {
      final game = mutualExhaustedStalemateGame(
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: kMutualExhaustedStalemateOwnNationId,
            factionId2: kMutualExhaustedStalemateEnemyNationId,
            state: RelationState.atWar,
            score: 20,
          ),
          DiplomacyRelation(
            factionId1: kMutualExhaustedStalemateOwnNationId,
            factionId2: 'gp5',
            state: RelationState.atWar,
            score: 20,
          ),
        ],
        playersOverride: const [
          Player(id: kMutualExhaustedStalemateOwnNationId, displayName: 'GP4', isHuman: false),
          Player(id: kMutualExhaustedStalemateEnemyNationId, displayName: 'GP3', isHuman: false),
          Player(id: 'gp5', displayName: 'GP5', isHuman: false),
        ],
      );
      final snapshot = mutualExhaustedStalemateSnapshotForOwn(
        atWarWith: const [kMutualExhaustedStalemateEnemyNationId, 'gp5'],
      );

      final targets = mutualExhaustedBelowQuotaGpStalematePeaceTargets(
        game: game,
        snapshot: snapshot,
      );

      expect(targets, isEmpty);
    });

    test('negative: gap > 1 OW province returns empty', () {
      final fullGame = mutualExhaustedStalemateGame();
      final droppedIds = <String>{
        kMutualExhaustedStalemateEnemyOwProvinces[7],
        kMutualExhaustedStalemateEnemyOwProvinces[8],
        kMutualExhaustedStalemateEnemyOwProvinces[6],
      };
      final reducedGame = Game(
        id: 'g-2509-mutual-exhausted-stalemate-gap',
        worldState: WorldState(
          turnState: fullGame.worldState.turnState,
          oldWorld: RegionData(
            provinces: [
              for (final p in fullGame.worldState.oldWorld.provinces)
                if (!droppedIds.contains(p.id)) p,
            ],
          ),
          newWorld: const RegionData(),
          armies: fullGame.worldState.armies,
        ),
        players: fullGame.players,
        diplomacyRelations: fullGame.diplomacyRelations,
      );
      final snapshot = mutualExhaustedStalemateSnapshotForOwn();

      final targets = mutualExhaustedBelowQuotaGpStalematePeaceTargets(
        game: reducedGame,
        snapshot: snapshot,
      );

      expect(targets, isEmpty);
    });

    test('determinism: repeated calls return identical results (must-have #7)',
        () {
      final game = mutualExhaustedStalemateGame();
      final snapshot = mutualExhaustedStalemateSnapshotForOwn();

      final a = mutualExhaustedBelowQuotaGpStalematePeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final b = mutualExhaustedBelowQuotaGpStalematePeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final c = mutualExhaustedBelowQuotaGpStalematePeaceTargets(
        game: game,
        snapshot: snapshot,
      );

      expect(a, [kMutualExhaustedStalemateEnemyNationId]);
      expect(b, a);
      expect(c, a);
    });
  });
}
