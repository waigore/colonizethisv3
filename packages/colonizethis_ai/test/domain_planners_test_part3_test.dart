import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planners_test_fake_api.dart';
void main() {
  group('computeDiplomaticCandidateScores', () {
    test('declareWar score exceeds establishOverture for same hostile target', () {
      final game = Game(
        id: 'g-diplo-score-1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'gp1',
              ),
              Province(
                id: 'oldWorld|p2',
                regionId: 'oldWorld',
                ownerId: 'gp1',
              ),
              Province(
                id: 'oldWorld|p3',
                regionId: 'oldWorld',
                ownerId: 'gp1',
              ),
              Province(
                id: 'oldWorld|p4',
                regionId: 'oldWorld',
                ownerId: 'gp2',
              ),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'gp1',
                locationProvinceId: 'oldWorld|p1',
              ),
              Unit(
                id: 'u2',
                type: 'grenadiers',
                ownerId: 'gp1',
                locationProvinceId: 'oldWorld|p2',
              ),
              Unit(
                id: 'u3',
                type: 'grenadiers',
                ownerId: 'gp1',
                locationProvinceId: 'oldWorld|p3',
              ),
              Unit(
                id: 'u4',
                type: 'grenadiers',
                ownerId: 'gp2',
                locationProvinceId: 'oldWorld|p4',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 20,
            level: RelationLevel.hostile,
            state: RelationState.atPeace,
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
      expect(scores.length, 2);
      expect(scores[0], greaterThan(scores[1]));
    });

    test('offer peace candidate scores lower when war desire is higher', () {
      Game gameForWarDesire({
        required int gp2ProvinceCount,
        required int gp2Regiments,
      }) {
        final provinces = <Province>[
          const Province(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            ownerId: 'gp1',
          ),
        ];
        var i = 0;
        for (; i < gp2ProvinceCount; i++) {
          provinces.add(
            Province(
              id: 'oldWorld|g2_$i',
              regionId: 'oldWorld',
              ownerId: 'gp2',
            ),
          );
        }
        final units = <Unit>[
          Unit(
            id: 'a1',
            type: 'grenadiers',
            ownerId: 'gp1',
            locationProvinceId: 'oldWorld|p1',
          ),
          Unit(
            id: 'a2',
            type: 'grenadiers',
            ownerId: 'gp1',
            locationProvinceId: 'oldWorld|p1',
          ),
        ];
        for (var r = 0; r < gp2Regiments; r++) {
          units.add(
            Unit(
              id: 'b$r',
              type: 'grenadiers',
              ownerId: 'gp2',
              locationProvinceId: 'oldWorld|g2_0',
            ),
          );
        }
        return Game(
          id: 'g-peace-$gp2ProvinceCount-$gp2Regiments',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
            oldWorld: RegionData(provinces: provinces, units: units),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'A', isHuman: false),
            Player(id: 'gp2', displayName: 'B', isHuman: false),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp2',
              score: 25,
              level: RelationLevel.hostile,
              state: RelationState.atWar,
            ),
          ],
        );
      }

      final highDesireGame = gameForWarDesire(gp2ProvinceCount: 1, gp2Regiments: 1);
      final lowDesireGame =
          gameForWarDesire(gp2ProvinceCount: 3, gp2Regiments: 4);
      expect(
        computeWarDesireScore(
          game: highDesireGame,
          nationId: 'gp1',
          targetFactionId: 'gp2',
          relationScore: 25,
        ),
        greaterThan(
          computeWarDesireScore(
            game: lowDesireGame,
            nationId: 'gp1',
            targetFactionId: 'gp2',
            relationScore: 25,
          ),
        ),
      );
      const topology = MapTopology(nodes: [], edges: []);
      final viewHi = buildPlayerView(highDesireGame, topology, 'gp1');
      final viewLo = buildPlayerView(lowDesireGame, topology, 'gp1');
      final snapHi = AIWorldSnapshot.fromPlayerView(viewHi);
      final snapLo = AIWorldSnapshot.fromPlayerView(viewLo);
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final peaceHi = computeDiplomaticCandidateScores(
        candidates: const [
          DiplomaticOrder(
            type: DiplomaticOrderType.offerPeace,
            targetFactionId: 'gp2',
          ),
        ],
        nationId: 'gp1',
        game: highDesireGame,
        snapshot: snapHi,
        config: config,
      ).single;
      final peaceLo = computeDiplomaticCandidateScores(
        candidates: const [
          DiplomaticOrder(
            type: DiplomaticOrderType.offerPeace,
            targetFactionId: 'gp2',
          ),
        ],
        nationId: 'gp1',
        game: lowDesireGame,
        snapshot: snapLo,
        config: config,
      ).single;
      expect(peaceLo, greaterThan(peaceHi));
    });
  });

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

  group('move planner diplomacy filter', () {
    test('full-AI move planner scores civilian moves; at-peace target not pre-filtered',
        () {
      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'p1', regionId: ow, ownerId: 'gp1'),
              Province(id: 'p2', regionId: ow, ownerId: 'gp2'),
              Province(id: 'p3', regionId: ow, ownerId: 'gp3'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'A',
            isHuman: false,
            leaderKey: 'napoleon',
          ),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
          Player(id: 'gp3', displayName: 'C', isHuman: false),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 0,
            state: RelationState.atWar,
          ),
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp3',
            score: 50,
            state: RelationState.atPeace,
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
      final seeds = AISeedBundle.fromTurnSeed(444);
      const fakeApi = FakeOrderSuggestionAPIForDomainPlannerTests(
        work: [],
        build: [],
        move: [
          MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|p2|0|0'),
          MoveOrder(unitId: 'u2', destinationTileKey: 'oldWorld|p3|0|0'),
        ],
        research: [],
        navalMove: [],
        navalMission: [],
        diplomatic: [],
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

      final moves = orders.moveOrdersByPlayerId['gp1'] ?? [];
      expect(moves.length, 1);
      // At-war destination is heavily weighted over at-peace (see kMovePreferEnemyTerritoryBonus).
      expect(moves.single.destinationTileKey, 'oldWorld|p2|0|0');
    });
  });
}
