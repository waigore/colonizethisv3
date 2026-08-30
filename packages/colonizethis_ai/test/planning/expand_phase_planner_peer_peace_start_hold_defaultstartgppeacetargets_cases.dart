// defaultStartGpPeaceTargets (Refs #4602 Slice B).

// Case bodies for `expand_phase_planner_peer_peace_basic_test.dart` (Refs #3977 Phase 6).
// Registered from the thin contract file of the same stem.
// Pin/row coverage is preserved 1:1 from the former inline suite.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';

void registerPeerPeaceStartHoldDefaultstartgppeacetargetsCases() {
  group('defaultStartGpPeaceTargets', () {
    test('peaces all GP wars at 7–8 OW below observer quota', () {
      final game = Game(
        id: 'g',
        players: [
          Player(id: 'gp1', displayName: 'GP1', isHuman: false),
          Player(id: 'gp2', displayName: 'GP2', isHuman: false),
        ],
        minorNations: const [],
        tribes: const [],
        worldState: WorldState(
          turnState: const TurnState(turnNumber: 50, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
            ],
          ),
          newWorld: const RegionData(provinces: []),
        ),
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(atWarWith: ['gp2']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(oldWorldProvincesOwned: 8),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(defaultStartGpPeaceTargets(game: game, snapshot: snapshot), [
        'gp2',
      ]);
    });

    test(
      'keeps invadable blocker war on GP-only frontier at default start',
      () {
        final game = Game(
          id: 'g-blocker-peace',
          players: [
            Player(id: 'gp4', displayName: 'GP4', isHuman: false),
            Player(id: 'gp3', displayName: 'GP3', isHuman: false),
          ],
          minorNations: const [],
          tribes: const [],
          worldState: WorldState(
            turnState: const TurnState(turnNumber: 50, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [
                for (var i = 0; i < 7; i++)
                  Province(
                    id: 'oldWorld|gp4_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp4',
                  ),
                for (var i = 0; i < 6; i++)
                  Province(
                    id: 'oldWorld|gp3_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp3',
                  ),
              ],
            ),
            newWorld: const RegionData(provinces: []),
          ),
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
            oldWorldProvincesOwned: 7,
            invadableProvinceIdsSorted: ['oldWorld|gp3_0'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        expect(
          defaultStartGpPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
        );
      },
    );
  });
}
