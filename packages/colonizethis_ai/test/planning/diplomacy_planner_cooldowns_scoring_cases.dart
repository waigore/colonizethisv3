// Scoring-level cooldown pins for diplomacy planner (Refs #4669 Slice D densify).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/planner_test_helpers.dart';

void registerDiplomacyPlannerCooldownsScoringCases() {
  group('diplomacy planner cooldowns — scoring', () {
    test('declareWar candidate score zero while wardec retry cooldown active', () {
      final game = Game(
        id: 'g-cool-war',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 5),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'A',
            isHuman: false,
            leaderKey: 'napoleon',
          ),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 10,
            level: RelationLevel.hostile,
            state: RelationState.atPeace,
          ),
        ],
        diplomaticHistoryEvents: [
          DiplomaticEvent(
            turn: 2,
            intraTurnIndex: 0,
            type: DiplomaticEventType.declareWar,
            participants: {'gp1', 'gp2'},
            fromFactionId: 'gp1',
            toFactionId: 'gp2',
          ),
        ],
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, 'gp1');
      final snapshot = AIWorldSnapshot.fromPlayerView(view);
      const config = AIConfig(
        leaderId: 'napoleon',
        personalityId: 'napoleon',
        hiddenAgendaId: 'warmonger',
      );
      final scores = computeDiplomaticCandidateScores(
        DiplomaticCandidateScoringInput(
          candidates: const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp2',
            ),
          ],
          nationId: 'gp1',
          game: game,
          snapshot: snapshot,
          config: config,
        ),
      );
      expect(scores.single, 0);
    });

    test('establishOverture score zero while improve-relations cooldown active', () {
      final game = Game(
        id: 'g-cool-overture',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 8),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'A',
            isHuman: false,
            leaderKey: 'victoria',
          ),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 40,
            state: RelationState.atPeace,
          ),
        ],
        diplomaticHistoryEvents: [
          DiplomaticEvent(
            turn: 7,
            intraTurnIndex: 0,
            type: DiplomaticEventType.overtureAccepted,
            participants: {'gp1', 'gp2'},
            fromFactionId: 'gp1',
            toFactionId: 'gp2',
          ),
        ],
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, 'gp1');
      final snapshot = AIWorldSnapshot.fromPlayerView(view);
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final scores = computeDiplomaticCandidateScores(
        DiplomaticCandidateScoringInput(
          candidates: const [
            DiplomaticOrder(
              type: DiplomaticOrderType.establishOverture,
              targetFactionId: 'gp2',
            ),
          ],
          nationId: 'gp1',
          game: game,
          snapshot: snapshot,
          config: config,
        ),
      );
      expect(scores.single, 0);
    });
  });
}
