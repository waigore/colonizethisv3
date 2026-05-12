import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_test_fake_api.dart';
void main() {
  group('war declaration relation threshold and target scoring', () {
    test(
      'peacemaker scores declareWar 0 when relation above threshold so does not pick it when another candidate exists',
      () {
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(
              id: 'gp1',
              displayName: 'A',
              isHuman: false,
              leaderKey: 'victoria',
            ),
            Player(id: 'gp2', displayName: 'B', isHuman: false),
            Player(id: 'gp3', displayName: 'C', isHuman: false),
          ],
          diplomacyRelations: [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp2',
              score: 60,
              level: RelationLevel.neutral,
              state: RelationState.atPeace,
            ),
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp3',
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
          leaderId: 'victoria',
          personalityId: 'victoria',
          hiddenAgendaId: 'peacemaker',
        );
        final seeds = AISeedBundle.fromTurnSeed(111);
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
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp3',
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

        final diplo = orders.diplomaticOrdersByPlayerId['gp1'];
        expect(diplo, isNotNull);
        expect(
          diplo!.single.targetFactionId,
          'gp3',
          reason:
              'peacemaker max relation 30; gp2 has 60 so score 0; only gp3 has positive score',
        );
      },
    );

    test('warmonger gets bonus for weakNeighbors target', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
              Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'gp2'),
              Province(id: 'oldWorld|p3', regionId: 'oldWorld', ownerId: 'gp3'),
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
            militaryLevel: 3,
          ),
          Player(id: 'gp2', displayName: 'B', isHuman: false, militaryLevel: 1),
          Player(id: 'gp3', displayName: 'C', isHuman: false, militaryLevel: 5),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 50,
            state: RelationState.atPeace,
          ),
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp3',
            score: 50,
            state: RelationState.atPeace,
          ),
        ],
      );
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'p2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'p3',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [
          TopologyEdge(id1: 'p1', id2: 'p2'),
          TopologyEdge(id1: 'p1', id2: 'p3'),
        ],
      );
      final view = buildPlayerView(game, topology, 'gp1');
      final snapshot = AIWorldSnapshot.fromPlayerView(view, topology: topology);
      expect(
        snapshot.opportunities.weakNeighbors,
        contains('gp2'),
        reason: 'gp2 owns p2 adjacent to gp1 p1',
      );
      expect(snapshot.opportunities.weakNeighbors, contains('gp3'));
      const config = AIConfig(
        leaderId: 'napoleon',
        personalityId: 'napoleon',
        hiddenAgendaId: 'warmonger',
      );
      final seeds = AISeedBundle.fromTurnSeed(222);
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

      final diplo = orders.diplomaticOrdersByPlayerId['gp1'];
      expect(diplo, isNotNull);
      expect(diplo!.single.type, DiplomaticOrderType.declareWar);
      expect(
        diplo.single.targetFactionId,
        'gp2',
        reason:
            'only candidate is gp2 (weak neighbor); warmonger applies +30 bonus',
      );
    });

    test(
      'backstabber prefers allied target when it is the only declare-war candidate',
      () {
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
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
              score: 80,
              level: RelationLevel.allied,
              state: RelationState.atPeace,
            ),
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp3',
              score: 50,
              level: RelationLevel.neutral,
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
          hiddenAgendaId: 'backstabber',
        );
        final seeds = AISeedBundle.fromTurnSeed(333);
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

        final diplo = orders.diplomaticOrdersByPlayerId['gp1'];
        expect(diplo, isNotNull);
        expect(diplo!.single.type, DiplomaticOrderType.declareWar);
        expect(
          diplo.single.targetFactionId,
          'gp2',
          reason:
              'only candidate is gp2 (allied); backstabber applies +25 bonus',
        );
      },
    );
  });

  group('computeWarDesireScore', () {
    test(
      'higher relative power and hostile relation yields higher war desire',
      () {
        final strongVsWeak = Game(
          id: 'g-desire-1',
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
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'A', isHuman: false),
            Player(id: 'gp2', displayName: 'B', isHuman: false),
          ],
        );
        final weakVsStrong = strongVsWeak.copyWith(
          worldState: strongVsWeak.worldState.copyWith(
            oldWorld: RegionData(
              provinces: strongVsWeak.worldState.oldWorld.provinces,
              units: [
                Unit(
                  id: 'u3',
                  type: 'grenadiers',
                  ownerId: 'gp2',
                  locationProvinceId: 'oldWorld|p3',
                ),
                Unit(
                  id: 'u4',
                  type: 'grenadiers',
                  ownerId: 'gp2',
                  locationProvinceId: 'oldWorld|p3',
                ),
              ],
            ),
          ),
        );

        final high = computeWarDesireScore(
          game: strongVsWeak,
          nationId: 'gp1',
          targetFactionId: 'gp2',
          relationScore: 20,
        );
        final low = computeWarDesireScore(
          game: weakVsStrong,
          nationId: 'gp1',
          targetFactionId: 'gp2',
          relationScore: 80,
        );

        expect(high, greaterThan(low));
      },
    );

    test(
      'minor target with intervention risk and no navy reduces war desire',
      () {
        final game = Game(
          id: 'g-desire-2',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
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
                  ownerId: 'minor1',
                ),
              ],
              units: [
                Unit(
                  id: 'u1',
                  type: 'grenadiers',
                  ownerId: 'gp1',
                  locationProvinceId: 'oldWorld|p1',
                ),
              ],
            ),
            newWorld: RegionData(
              provinces: const [
                Province(
                  id: 'newWorld|n1',
                  regionId: 'newWorld',
                  ownerId: 'minor1',
                ),
              ],
              units: [
                Unit(
                  id: 'u2',
                  type: 'grenadiers',
                  ownerId: 'minor1',
                  locationProvinceId: 'newWorld|n1',
                ),
                Unit(
                  id: 'u3',
                  type: 'grenadiers',
                  ownerId: 'minor1',
                  locationProvinceId: 'newWorld|n1',
                ),
              ],
            ),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'A', isHuman: false),
            Player(id: 'gp2', displayName: 'B', isHuman: false),
            Player(id: 'gp3', displayName: 'C', isHuman: false),
          ],
          minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
          overtureStates: const [
            OvertureState(
              gpId: 'gp2',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
            ),
            OvertureState(
              gpId: 'gp3',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
            ),
          ],
        );
        final score = computeWarDesireScore(
          game: game,
          nationId: 'gp1',
          targetFactionId: 'minor1',
          relationScore: 40,
        );
        expect(score, lessThan(50));
      },
    );

    test('minor target resources increase war desire when GP stockpile lacks them', () {
      const tileKey = 'oldWorld|p2|0|0';
      WorldState state({required Map<String, String> resources}) => WorldState(
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
              ownerId: 'minor1',
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
              locationProvinceId: 'oldWorld|p1',
            ),
            Unit(
              id: 'u3',
              type: 'grenadiers',
              ownerId: 'minor1',
              locationProvinceId: 'oldWorld|p2',
            ),
          ],
        ),
        newWorld: const RegionData(),
        tileKeysByRegionAndProvince: {
          'oldWorld': {
            'oldWorld|p2': [tileKey],
          },
        },
        resourceByTileKey: resources,
      );
      final withoutRes = Game(
        id: 'g-res-0',
        worldState: state(resources: const {}),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'A',
            isHuman: false,
            stockpile: Stockpile(quantities: {'grain': 10}),
          ),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M')],
      );
      final withRes = withoutRes.copyWith(
        id: 'g-res-1',
        worldState: state(resources: {tileKey: 'tobacco'}),
      );
      const relation = 40;
      final a = computeWarDesireScore(
        game: withoutRes,
        nationId: 'gp1',
        targetFactionId: 'minor1',
        relationScore: relation,
      );
      final b = computeWarDesireScore(
        game: withRes,
        nationId: 'gp1',
        targetFactionId: 'minor1',
        relationScore: relation,
      );
      expect(b - a, 5);
    });
  });

}
