// Case bodies for `diplomacy_planner_stalled_peace_test.dart` (Refs #4104 Slice C).
// Registered from the thin contract; pin coverage preserved 1:1 from the
// former inline suite.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void registerDiplomacyPlannerStalledPeaceQuotaSoleGpPartBCases() {
  test('consolidateGainsSoleGpPeaceTarget returns weaker sole GP enemy', () {
    final game = Game(
      id: 'g-consolidate',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 90),
        oldWorld: RegionData(
          provinces: [
            for (var i = 1; i <= 12; i++)
              Province(
                id: 'oldWorld|gp4_$i',
                regionId: 'oldWorld',
                ownerId: 'gp4',
              ),
            for (var i = 1; i <= 5; i++)
              Province(
                id: 'oldWorld|gp3_$i',
                regionId: 'oldWorld',
                ownerId: 'gp3',
              ),
          ],
          units: [],
        ),
        newWorld: const RegionData(provinces: [], units: []),
      ),
      players: const [
        Player(
          id: 'gp4',
          displayName: 'GP4',
          isHuman: false,
          leaderKey: 'victoria',
        ),
        Player(
          id: 'gp3',
          displayName: 'GP3',
          isHuman: false,
          leaderKey: 'napoleon',
        ),
      ],
      diplomacyRelations: [
        const DiplomacyRelation(
          factionId1: 'gp4',
          factionId2: 'gp3',
          state: RelationState.atWar,
          score: 30,
        ),
      ],
    );
    const snapshot = AIWorldSnapshot(
      playerId: 'gp4',
      threats: ThreatSummary(atWarWith: ['gp3']),
      opportunities: OpportunitySummary(),
      conquest: ConquestSummary(oldWorldProvincesOwned: 12),
      economy: EconomySummary(),
      relations: {},
    );

    expect(
      consolidateGainsSoleGpPeaceTarget(game: game, snapshot: snapshot),
      'gp3',
    );
  });

  test(
    'supplementMutualStalledGreatPowerPeaceOrders mirrors sole-GP blocker peace',
    () {
      final game = Game(
        id: 'g-mutual-blocker',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 20),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 5; i++)
                Province(
                  id: 'oldWorld|gp6_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp6',
                ),
              for (var i = 1; i <= 12; i++)
                Province(
                  id: 'oldWorld|gp5_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp5',
                ),
              const Province(
                id: 'oldWorld|minor1',
                regionId: 'oldWorld',
                ownerId: 'minor1',
              ),
            ],
            units: [],
          ),
          newWorld: const RegionData(provinces: [], units: []),
        ),
        players: const [
          Player(
            id: 'gp6',
            displayName: 'GP6',
            isHuman: false,
            leaderKey: 'victoria',
          ),
          Player(
            id: 'gp5',
            displayName: 'GP5',
            isHuman: false,
            leaderKey: 'napoleon',
          ),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp6',
            factionId2: 'gp5',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
        aiControlByGpId: const {'gp6': true, 'gp5': true},
      );
      const topology = MapTopology();
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp6': [
            const DiplomaticOrder(
              type: DiplomaticOrderType.offerPeace,
              targetFactionId: 'gp5',
            ),
          ],
        },
      );

      final supplemented = supplementMutualStalledGreatPowerPeaceOrders(
        game: game,
        topology: topology,
        orders: orders,
      );

      expect(
        supplemented.diplomaticOrdersByPlayerId['gp5'],
        contains(
          isA<DiplomaticOrder>().having(
            (o) => o.type,
            'type',
            DiplomaticOrderType.offerPeace,
          ).having((o) => o.targetFactionId, 'target', 'gp6'),
        ),
      );
    },
  );

  test(
    'criticalWeakGpSurvivalPeaceTargets includes stronger GP when minors are gone',
    () {
      final game = Game(
        id: 'g-weak-survival',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 4; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
              for (var i = 1; i <= 12; i++)
                Province(
                  id: 'oldWorld|gp3_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
              const Province(
                id: 'oldWorld|inv1',
                regionId: 'oldWorld',
                ownerId: 'gp3',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp4', displayName: 'P4', isHuman: false),
          Player(id: 'gp3', displayName: 'P3', isHuman: false),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp4',
            factionId2: 'gp3',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp4',
        threats: ThreatSummary(atWarWith: ['gp3']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 4,
          invadableProvinceIdsSorted: ['oldWorld|inv1'],
        ),
        economy: EconomySummary(),
        relations: {},
      );

      expect(
        criticalWeakGpSurvivalPeaceTargets(game: game, snapshot: snapshot),
        ['gp3'],
      );
      const aboveStalledThreshold = AIWorldSnapshot(
        playerId: 'gp4',
        threats: ThreatSummary(atWarWith: ['gp3']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 10,
          invadableProvinceIdsSorted: ['oldWorld|inv1'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        criticalWeakGpSurvivalPeaceTargets(
          game: game,
          snapshot: aboveStalledThreshold,
        ),
        isEmpty,
      );
    },
  );
}
