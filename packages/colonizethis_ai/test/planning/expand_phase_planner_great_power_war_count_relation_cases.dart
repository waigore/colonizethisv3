// Relation-path pins for `greatPowerWarCountOnTarget` (Refs #4669 Slice B).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void registerExpandPhasePlannerGreatPowerWarCountRelationCases() {
  group('greatPowerWarCountOnTarget relation paths', () {
    test('counts only Great Powers via diplomacy relations', () {
      final game = Game(
        id: 'g-gp-war-count-basic',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 12),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'P1', isHuman: false),
          Player(id: 'gp2', displayName: 'P2', isHuman: false),
          Player(id: 'gp3', displayName: 'P3', isHuman: false),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp3',
            state: RelationState.atWar,
            score: 10,
          ),
          DiplomacyRelation(
            factionId1: 'gp2',
            factionId2: 'gp3',
            state: RelationState.atWar,
            score: 20,
          ),
          DiplomacyRelation(
            factionId1: 'minor1',
            factionId2: 'gp3',
            state: RelationState.atWar,
            score: 5,
          ),
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            state: RelationState.atPeace,
            score: 0,
          ),
        ],
      );
      expect(
        greatPowerWarCountOnTarget(game: game, targetGpId: 'gp3'),
        2,
        reason:
            'Only Great Power vs Great Power at-war relations against the '
            'target must contribute to the dogpile signal; minor wars and '
            'non-war states are ignored.',
      );
    });

    test('returns zero when no GP is at war with the target', () {
      final game = Game(
        id: 'g-gp-war-count-zero',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'P1', isHuman: false),
          Player(id: 'gp2', displayName: 'P2', isHuman: false),
        ],
      );
      expect(
        greatPowerWarCountOnTarget(game: game, targetGpId: 'gp3'),
        0,
        reason:
            'Targets without any active GP-vs-GP at-war relation must '
            'produce a zero count so the war-concentration gate does not '
            'suppress an otherwise valid declare-war candidate.',
      );
    });
  });
}
