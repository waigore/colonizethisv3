// belowQuotaPeerGpPeaceTargets (Refs #4602 Slice B).

// Case bodies for `expand_phase_planner_peer_peace_basic_test.dart` (Refs #3977 Phase 6).
// Registered from the thin contract file of the same stem.
// Pin/row coverage is preserved 1:1 from the former inline suite.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';

void registerPeerPeaceStartHoldBelowquotapeergppeacetargetsCases() {
  group('belowQuotaPeerGpPeaceTargets', () {
    test(
      'peaces mutual plateau peer on GP-only cleared frontier (both sides)',
      () {
        final game = Game(
          id: 'g-below-quota-peer-no-minors',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 90),
            oldWorld: RegionData(
              provinces: [
                for (var i = 0; i < 8; i++)
                  Province(
                    id: 'oldWorld|gp5_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp5',
                  ),
                for (var i = 0; i < 8; i++)
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
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp5', displayName: 'P5', isHuman: false),
            Player(id: 'gp6', displayName: 'P6', isHuman: false),
          ],
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
            invadableProvinceIdsSorted: ['oldWorld|gp6_frontier'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        const snapshotGp6 = AIWorldSnapshot(
          playerId: 'gp6',
          threats: ThreatSummary(atWarWith: ['gp5']),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 9,
            invadableProvinceIdsSorted: ['oldWorld|gp6_frontier'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        expect(
          belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
          ['gp6'],
          reason:
              'seed-42 gp5/gp6 plateau: both sides must exit the sole GP-blocker '
              'war on a cleared frontier (Refs #2509).',
        );
        expect(
          belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshotGp6),
          ['gp5'],
        );
      },
    );

    test(
      'peaces mutual plateau peer when uninvaded minors remain on GP-only',
      () {
        final game = Game(
          id: 'g-below-quota-peer-gp-only-minors',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
            oldWorld: RegionData(
              provinces: [
                for (var i = 0; i < 8; i++)
                  Province(
                    id: 'oldWorld|gp6_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp6',
                  ),
                for (var i = 0; i < 9; i++)
                  Province(
                    id: 'oldWorld|gp5_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp5',
                  ),
                const Province(
                  id: 'oldWorld|frontier',
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
          playerId: 'gp6',
          threats: ThreatSummary(atWarWith: ['gp5']),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 8,
            invadableProvinceIdsSorted: ['oldWorld|frontier'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        expect(belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot), [
          'gp5',
        ]);
      },
    );

    // 3-province gap boundary tests (Refs #2509) live in
    // `expand_phase_planner_peer_gap_boundary_test.dart` so this file stays under
    // repo.dart_file_non_comment_line_size (1000 NCL).
  });
}
