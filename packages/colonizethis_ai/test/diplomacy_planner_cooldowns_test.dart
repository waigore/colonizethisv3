import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_test_fake_api.dart';

void main() {
  group('diplomacy planner cooldowns', () {
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
      );
      expect(scores.single, 0);
    });

    test('runDomainPlanners emits no diplomatic order when all candidates on cooldown',
        () {
      final game = Game(
        id: 'g-cool-all',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 4),
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
            turn: 1,
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
      final seeds = AISeedBundle.fromTurnSeed(202);
      const fakeApi = FakeOrderSuggestionAPIForDomainPlannerTests(
        work: [],
        build: [],
        move: [],
        research: [],
        navalMove: [],
        navalMission: [],
        diplomatic: [
          DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: 'gp2',
          ),
        ],
      );
      const economyPlan = EconomyPlan(
        productionAssignments: [],
        cargoPreference: CargoPreference.none,
      );
      final orders = runDomainPlanners(
        game: game,
        topology: topology,
        nationId: 'gp1',
        view: view,
        snapshot: snapshot,
        config: config,
        primaryGoal: StrategicGoal.conquer,
        seeds: seeds,
        suggestionAPI: fakeApi,
        economyPlan: economyPlan,
      );
      expect(orders.diplomaticOrdersByPlayerId['gp1'], isNull);
    });

    test('improve-relations cooldown expired allows overture selection deterministically',
        () {
      final game = Game(
        id: 'g-cool-overture-ok',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 10),
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
      final seeds = AISeedBundle.fromTurnSeed(77);
      const diplo = DiplomaticOrder(
        type: DiplomaticOrderType.establishOverture,
        targetFactionId: 'gp2',
      );
      const fakeApi = FakeOrderSuggestionAPIForDomainPlannerTests(
        work: [],
        build: [],
        move: [],
        research: [],
        navalMove: [],
        navalMission: [],
        diplomatic: [diplo],
      );
      const economyPlan = EconomyPlan(
        productionAssignments: [],
        cargoPreference: CargoPreference.none,
      );
      final orders1 = runDomainPlanners(
        game: game,
        topology: topology,
        nationId: 'gp1',
        view: view,
        snapshot: snapshot,
        config: config,
        primaryGoal: StrategicGoal.diplomacy,
        seeds: seeds,
        suggestionAPI: fakeApi,
        economyPlan: economyPlan,
      );
      final orders2 = runDomainPlanners(
        game: game,
        topology: topology,
        nationId: 'gp1',
        view: view,
        snapshot: snapshot,
        config: config,
        primaryGoal: StrategicGoal.diplomacy,
        seeds: seeds,
        suggestionAPI: fakeApi,
        economyPlan: economyPlan,
      );
      expect(orders1.diplomaticOrdersByPlayerId['gp1'], isNotNull);
      expect(orders1.diplomaticOrdersByPlayerId['gp1']!.single, diplo);
      expect(orders2.diplomaticOrdersByPlayerId['gp1'], orders1.diplomaticOrdersByPlayerId['gp1']);
    });
  });
}
