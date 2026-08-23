// defaultStartFutileMinorPeaceTargets (Refs #4602 Slice B).

// Case bodies for `expand_phase_planner_peer_peace_basic_test.dart` (Refs #3977 Phase 6).
// Registered from the thin contract file of the same stem.
// Pin/row coverage is preserved 1:1 from the former inline suite.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';

void registerPeerPeaceStartHoldDefaultstartfutileminorpeacetargetsCases() {
  group('defaultStartFutileMinorPeaceTargets', () {
    test(
      'peaces at-war minors that own no invadable OW at default start size',
      () {
        final game = Game(
          id: 'g-futile-minor',
          players: [Player(id: 'gp4', displayName: 'GP4', isHuman: false)],
          minorNations: [
            MinorNation(id: 'minor1', displayName: 'M1'),
            MinorNation(id: 'minor2', displayName: 'M2'),
          ],
          tribes: const [],
          worldState: WorldState(
            turnState: const TurnState(turnNumber: 40, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [
                for (var i = 0; i < 7; i++)
                  Province(
                    id: 'oldWorld|gp4_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp4',
                  ),
                Province(
                  id: 'oldWorld|m1',
                  regionId: 'oldWorld',
                  ownerId: 'minor1',
                ),
                Province(
                  id: 'oldWorld|m2',
                  regionId: 'oldWorld',
                  ownerId: 'minor2',
                ),
              ],
            ),
            newWorld: const RegionData(provinces: []),
          ),
        );
        const snapshot = AIWorldSnapshot(
          playerId: 'gp4',
          threats: ThreatSummary(atWarWith: ['minor1']),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 7,
            invadableProvinceIdsSorted: ['oldWorld|m2'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        expect(
          defaultStartFutileMinorPeaceTargets(game: game, snapshot: snapshot),
          ['minor1'],
        );
      },
    );

    test('peaces all at-war minors on GP-only invadable frontier', () {
      final game = Game(
        id: 'g-gp-only-minor',
        players: [
          Player(id: 'gp4', displayName: 'GP4', isHuman: false),
          Player(id: 'gp3', displayName: 'GP3', isHuman: false),
        ],
        minorNations: [MinorNation(id: 'minor1', displayName: 'M1')],
        tribes: const [],
        worldState: WorldState(
          turnState: const TurnState(turnNumber: 40, phase: TurnPhase.orders),
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
            factionId2: 'minor1',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp4',
        threats: ThreatSummary(atWarWith: ['minor1']),
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
        defaultStartFutileMinorPeaceTargets(game: game, snapshot: snapshot),
        ['minor1'],
      );
    });
  });
}
