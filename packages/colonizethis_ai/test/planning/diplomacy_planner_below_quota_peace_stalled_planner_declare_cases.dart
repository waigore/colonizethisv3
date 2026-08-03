// Topic-split case module (Refs #3997 Phase 8).
// Registered from the thin contract / barrel for this family.
// Pin/row coverage is preserved 1:1 from the former combined cases file.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/domain_planner_test_fake_api.dart';
import '../support/planner_test_helpers.dart';


void registerDiplomacyBelowQuotaPeaceStalledPlannerDeclareCases() {
  test(
    'criticalWeakUninvadedMinorDeclareTarget picks uninvaded minor owner',
    () {
      final game = Game(
        id: 'g-critical-minor-declare',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 40),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 5; i++)
                Province(
                  id: 'oldWorld|gp3_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
              const Province(
                id: 'oldWorld|m1',
                regionId: 'oldWorld',
                ownerId: 'minor1',
              ),
              const Province(
                id: 'oldWorld|m2',
                regionId: 'oldWorld',
                ownerId: 'minor2',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'gp3', displayName: 'P3', isHuman: false)],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'M1'),
          MinorNation(id: 'minor2', displayName: 'M2'),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp3',
            factionId2: 'minor1',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp3',
        threats: ThreatSummary(atWarWith: ['minor1']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 6,
          invadableProvinceIdsSorted: ['oldWorld|m1', 'oldWorld|m2'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        criticalWeakUninvadedMinorDeclareTarget(game: game, snapshot: snapshot),
        'minor2',
      );
    },
  );

  test(
    'criticalWeakUninvadedMinorDeclareTarget fires at 8 OW with sole GP war',
    () {
      final game = Game(
        id: 'g-critical-minor-with-gp-war',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 40),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 8; i++)
                Province(
                  id: 'oldWorld|gp5_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp5',
                ),
              for (var i = 1; i <= 8; i++)
                Province(
                  id: 'oldWorld|gp6_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp6',
                ),
              const Province(
                id: 'oldWorld|m1',
                regionId: 'oldWorld',
                ownerId: 'minor1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp5', displayName: 'P5', isHuman: false),
          Player(id: 'gp6', displayName: 'P6', isHuman: false),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp5',
            factionId2: 'gp6',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp5',
        threats: ThreatSummary(atWarWith: ['gp6']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 8,
          invadableProvinceIdsSorted: ['oldWorld|m1'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        criticalWeakUninvadedMinorDeclareTarget(game: game, snapshot: snapshot),
        'minor1',
      );
    },
  );

  test(
    'runDiplomacyPlannerWithResult forces peace when candidates are empty',
    () {
      final game = Game(
        id: 'g-empty-candidates-peace',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 60),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 5; i++)
                Province(
                  id: 'oldWorld|gp3_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
              for (var i = 1; i <= 10; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
            ],
          ),
          newWorld: const RegionData(),
          armies: [
            Army(
              id: homeArmyIdFor('gp3'),
              ownerId: 'gp3',
              regionId: 'oldWorld',
              stationedProvinceId: 'oldWorld|gp3_1',
              regimentUnitIds: const ['u_gp3_1'],
              isHomeArmy: true,
            ),
            Army(
              id: homeArmyIdFor('gp4'),
              ownerId: 'gp4',
              regionId: 'oldWorld',
              stationedProvinceId: 'oldWorld|gp4_1',
              regimentUnitIds: const ['u_gp4_1'],
              isHomeArmy: true,
            ),
          ],
        ),
        players: const [
          Player(id: 'gp3', displayName: 'P3', isHuman: false),
          Player(id: 'gp4', displayName: 'P4', isHuman: false),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp3',
            factionId2: 'gp4',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
        aiControlByGpId: const {'gp3': true},
      );
      const topology = MapTopology(nodes: [], edges: []);
      final ctx = buildTestPlannerContext(
        game: game,
        topology: topology,
        nationId: 'gp3',
        primaryGoal: StrategicGoal.trade,
        suggestionAPI: const FakeOrderSuggestionAPIForDomainPlannerTests(
          work: [],
          build: [],
          move: [],
          research: [],
          navalMove: [],
          navalMission: [],
          diplomatic: [],
        ),
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp3',
        threats: ThreatSummary(atWarWith: ['gp4']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 5,
          invadableProvinceIdsSorted: ['oldWorld|gp4_10'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      final result = runDiplomacyPlannerWithResult(
        ctx: ctx,
        snapshot: snapshot,
        pass: DiplomacyPlannerPass.nonDeclareWarOnly,
      );
      final peaceOrders =
          result.orders.diplomaticOrdersByPlayerId['gp3'] ?? const [];
      expect(
        peaceOrders.any(
          (o) =>
              o.type == DiplomaticOrderType.offerPeace &&
              o.targetFactionId == 'gp4',
        ),
        isFalse,
        reason: 'below-quota GP-only frontier keeps war on invadable blocker',
      );
    },
  );

  test(
    'defaultStartOwMinorDeclareTarget picks minor at 7 OW without GP-only frontier',
    () {
      final game = Game(
        id: 'g-default-start-minor',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 7; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
              const Province(
                id: 'oldWorld|minor3',
                regionId: 'oldWorld',
                ownerId: 'minor3',
              ),
              const Province(
                id: 'oldWorld|p99',
                regionId: 'oldWorld',
                ownerId: 'gp3',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp3', displayName: 'P3', isHuman: false),
          Player(id: 'gp4', displayName: 'P4', isHuman: false),
        ],
        minorNations: const [MinorNation(id: 'minor3', displayName: 'M3')],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp4',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 7,
          invadableProvinceIdsSorted: ['oldWorld|minor3'],
          adjacentOwnerFactionIdsSorted: ['minor3'],
        ),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        defaultStartOwMinorDeclareTarget(game: game, snapshot: snapshot),
        'minor3',
      );
    },
  );

}
