import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'domain_planner_test_fake_api.dart';
import 'planner_test_helpers.dart';

void main() {
  test(
    'stalledZeroRegimentAllFactionPeaceTargets includes minors when stalled',
    () {
      final game = Game(
        id: 'g-zero-reg-all-faction-peace',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 8; i++)
                Province(
                  id: 'oldWorld|gp5_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp5',
                ),
              Province(
                id: 'oldWorld|m1',
                regionId: 'oldWorld',
                ownerId: 'minor1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'gp5', displayName: 'P5', isHuman: false)],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp5',
            factionId2: 'minor1',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp5',
        threats: ThreatSummary(atWarWith: ['minor1', 'minor2']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 8,
          invadableProvinceIdsSorted: ['oldWorld|m1'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        stalledZeroRegimentAllFactionPeaceTargets(
          game: game,
          snapshot: snapshot,
        ),
        ['minor1', 'minor2'],
        reason:
            'Zero-regiment path peaces minors/tribes only, not Great Powers',
      );
    },
  );

  test(
    'belowQuotaMultiMinorDistractionPeaceTargets keeps focused minor only',
    () {
      final game = Game(
        id: 'g-multi-minor-focus',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
          oldWorld: RegionData(
            provinces: [
              for (var i = 0; i < 9; i++)
                Province(
                  id: 'oldWorld|gp3_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
              Province(
                id: 'oldWorld|m1_a',
                regionId: 'oldWorld',
                ownerId: 'minor1',
              ),
              Province(
                id: 'oldWorld|m2_a',
                regionId: 'oldWorld',
                ownerId: 'minor2',
              ),
            ],
          ),
          newWorld: const RegionData(),
          armies: [
            Army(
              id: homeArmyIdFor('gp3'),
              ownerId: 'gp3',
              regionId: 'oldWorld',
              stationedProvinceId: 'oldWorld|gp3_0',
              regimentUnitIds: const ['u_gp3_1', 'u_gp3_2'],
              isHomeArmy: true,
            ),
          ],
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
          const DiplomacyRelation(
            factionId1: 'gp3',
            factionId2: 'minor2',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp3',
        threats: ThreatSummary(atWarWith: ['minor1', 'minor2']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 9,
          invadableProvinceIdsSorted: ['oldWorld|m1_a', 'oldWorld|m2_a'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        belowQuotaMultiMinorDistractionPeaceTargets(
          game: game,
          snapshot: snapshot,
        ),
        ['minor2'],
      );
    },
  );

  test(
    'stalledZeroRegimentGpPeaceTargets includes all GP wars when stalled',
    () {
      final game = Game(
        id: 'g-zero-reg-gp-peace',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 8; i++)
                Province(
                  id: 'oldWorld|gp3_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
              for (var i = 1; i <= 12; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
            ],
          ),
          newWorld: const RegionData(),
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
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp3',
        threats: ThreatSummary(atWarWith: ['gp4', 'minor1']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 8,
          invadableProvinceIdsSorted: ['oldWorld|inv1'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        stalledZeroRegimentGpPeaceTargets(game: game, snapshot: snapshot),
        ['gp4'],
      );
    },
  );

  test(
    'collectStalledGreatPowerPeaceTargets peace sole GP blocker on zero-regiment stalemate',
    () {
      final game = Game(
        id: 'g-zero-reg-gp-only-blocker-peace',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 8; i++)
                Province(
                  id: 'oldWorld|gp3_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
              for (var i = 1; i <= 9; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
              for (var i = 1; i <= 5; i++)
                Province(
                  id: 'oldWorld|gp4_inv_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
            ],
          ),
          newWorld: const RegionData(),
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
      );
      final snapshot = AIWorldSnapshot(
        playerId: 'gp3',
        threats: const ThreatSummary(atWarWith: ['gp4']),
        opportunities: const OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 8,
          invadableProvinceIdsSorted: [
            for (var i = 1; i <= 5; i++) 'oldWorld|gp4_inv_$i',
          ],
        ),
        economy: const EconomySummary(),
        relations: const {},
      );
      expect(
        collectStalledGreatPowerPeaceTargets(game: game, snapshot: snapshot),
        contains('gp4'),
      );
    },
  );

  test(
    'weakHoldingsInvadableBlockerPeaceTargets peace frontier GP when outmatched',
    () {
      final game = Game(
        id: 'g-weak-blocker-peace',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 60),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 4; i++)
                Province(
                  id: 'oldWorld|gp3_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
              for (var i = 1; i <= 11; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
              const Province(
                id: 'oldWorld|inv1',
                regionId: 'oldWorld',
                ownerId: 'gp4',
              ),
              const Province(
                id: 'oldWorld|inv2',
                regionId: 'oldWorld',
                ownerId: 'minor1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp3', displayName: 'P3', isHuman: false),
          Player(id: 'gp4', displayName: 'P4', isHuman: false),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp3',
            factionId2: 'gp4',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp3',
        threats: ThreatSummary(atWarWith: ['gp4']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 4,
          invadableProvinceIdsSorted: ['oldWorld|inv1', 'oldWorld|inv2'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        weakHoldingsInvadableBlockerPeaceTargets(
          game: game,
          snapshot: snapshot,
        ),
        ['gp4'],
      );
    },
  );

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

  test(
    'defaultStartOwMinorDeclareTarget picks uninvaded minor on GP-only invadable frontier',
    () {
      final game = Game(
        id: 'g-default-start-minor-gp-frontier',
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
                id: 'oldWorld|minor2',
                regionId: 'oldWorld',
                ownerId: 'minor2',
              ),
              const Province(
                id: 'oldWorld|gp3_block',
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
        minorNations: const [MinorNation(id: 'minor2', displayName: 'M2')],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp4',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 7,
          invadableProvinceIdsSorted: ['oldWorld|gp3_block'],
          adjacentOwnerFactionIdsSorted: ['gp3'],
        ),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        defaultStartOwMinorDeclareTarget(game: game, snapshot: snapshot),
        'minor2',
      );
    },
  );

  test(
    'runDiplomacyPlannerWithResult scoring path prefers minor over GP blocker on GP-only frontier',
    () {
      final game = Game(
        id: 'g-scoring-minor-before-gp',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 9; i++)
                Province(
                  id: 'oldWorld|gp5_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp5',
                ),
              for (var i = 1; i <= 9; i++)
                Province(
                  id: 'oldWorld|gp6_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp6',
                ),
              const Province(
                id: 'oldWorld|gp6_frontier',
                regionId: 'oldWorld',
                ownerId: 'gp6',
              ),
              const Province(
                id: 'oldWorld|minor1_hold',
                regionId: 'oldWorld',
                ownerId: 'minor1',
              ),
              const Province(
                id: 'oldWorld|minor2_hold',
                regionId: 'oldWorld',
                ownerId: 'minor2',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp5', displayName: 'P5', isHuman: false),
          Player(id: 'gp6', displayName: 'P6', isHuman: false),
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'M1'),
          MinorNation(id: 'minor2', displayName: 'M2'),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp5',
            factionId2: 'gp6',
            state: RelationState.atWar,
            score: 30,
          ),
          const DiplomacyRelation(
            factionId1: 'gp5',
            factionId2: 'minor1',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp5',
        threats: ThreatSummary(atWarWith: ['gp6', 'minor1']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 9,
          invadableProvinceIdsSorted: ['oldWorld|gp6_frontier'],
          adjacentOwnerFactionIdsSorted: ['gp6'],
        ),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      const topology = MapTopology(nodes: [], edges: []);
      final ctx = buildTestPlannerContext(
        game: game,
        topology: topology,
        nationId: 'gp5',
        primaryGoal: StrategicGoal.conquer,
        suggestionAPI: FakeOrderSuggestionAPIForDomainPlannerTests(
          work: const [],
          build: const [],
          move: const [],
          research: const [],
          navalMove: const [],
          navalMission: const [],
          diplomatic: const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'minor2',
            ),
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp6',
            ),
          ],
        ),
      );
      final result = runDiplomacyPlannerWithResult(
        ctx: ctx,
        snapshot: snapshot,
        pass: DiplomacyPlannerPass.declareWarOnly,
      );
      expect(result.declaredWarTargetFactionId, 'minor2');
    },
  );

  test(
    'runDiplomacyPlannerWithResult prefers minor declare before GP blocker on GP-only frontier',
    () {
      final game = Game(
        id: 'g-minor-before-gp-blocker',
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
                id: 'oldWorld|minor1',
                regionId: 'oldWorld',
                ownerId: 'minor1',
              ),
              const Province(
                id: 'oldWorld|gp3_block',
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
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp4',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 7,
          invadableProvinceIdsSorted: ['oldWorld|gp3_block'],
          adjacentOwnerFactionIdsSorted: ['gp3'],
        ),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      const topology = MapTopology(nodes: [], edges: []);
      final ctx = buildTestPlannerContext(
        game: game,
        topology: topology,
        nationId: 'gp4',
        primaryGoal: StrategicGoal.conquer,
      );
      final result = runDiplomacyPlannerWithResult(
        ctx: ctx,
        snapshot: snapshot,
        pass: DiplomacyPlannerPass.declareWarOnly,
      );
      expect(result.declaredWarTargetFactionId, 'minor1');
    },
  );

  test(
    'plateauOwMinorDeclareTarget allows mutual plateau war on mixed frontier',
    () {
      final game = Game(
        id: 'g-plateau-minor-mixed-frontier',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 8; i++)
                Province(
                  id: 'oldWorld|gp5_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp5',
                ),
              for (var i = 1; i <= 9; i++)
                Province(
                  id: 'oldWorld|gp6_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp6',
                ),
              const Province(
                id: 'oldWorld|minor2',
                regionId: 'oldWorld',
                ownerId: 'minor2',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp5', displayName: 'P5', isHuman: false),
          Player(id: 'gp6', displayName: 'P6', isHuman: false),
        ],
        minorNations: const [MinorNation(id: 'minor2', displayName: 'M2')],
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
          invadableProvinceIdsSorted: ['oldWorld|minor2'],
          adjacentOwnerFactionIdsSorted: ['minor2'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        plateauOwMinorDeclareTarget(game: game, snapshot: snapshot),
        'minor2',
      );
    },
  );
}
