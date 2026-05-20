import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/colonial_pressure.dart';

// SPEC/ai/ai-architecture.md § Observer goal phases (Full AI), EXPAND:
// "While uninvaded OW minors remain, also peace below-quota GP peers within
// three provinces". Boundary tests pin the 3-province gap rule (Refs #2509).
//
// Split out of colonial_pressure_test.dart to keep that file under the
// repo.dart_file_non_comment_line_size (1000 NCL) limit. The base group
// (mutual-plateau, GP-only frontier, stronger-self without minors, etc.)
// still lives in `colonial_pressure_test.dart`; this file only covers the
// 3-vs-4 gap boundary, stronger-self symmetry guard under
// kMaxPeerOwGapWithMinors, and the at-war-minor collapse where the
// "uninvaded minor" guard fails and the gap reverts to 1.
void main() {
  group('belowQuotaPeerGpPeaceTargets (peer gap boundary)', () {
    test(
      'peaces partner at 3-province gap when uninvaded minor remains',
      () {
        final game = Game(
          id: 'g-peer-gap-three-with-minors',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 70,
            ),
            oldWorld: RegionData(
              provinces: [
                for (var i = 1; i <= 6; i++)
                  Province(
                    id: 'oldWorld|gp6_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp6',
                  ),
                for (var i = 1; i <= 9; i++)
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
          playerId: 'gp6',
          threats: ThreatSummary(atWarWith: ['gp5']),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 6,
            invadableProvinceIdsSorted: ['oldWorld|minor1'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        expect(
          belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
          ['gp5'],
          reason:
              'minor pivot remains and gap=3 is within kMaxPeerOwGapWithMinors',
        );
      },
    );

    test(
      'skips partner at 4-province gap even when uninvaded minor remains',
      () {
        final game = Game(
          id: 'g-peer-gap-four-with-minors',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 70,
            ),
            oldWorld: RegionData(
              provinces: [
                for (var i = 1; i <= 5; i++)
                  Province(
                    id: 'oldWorld|gp6_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp6',
                  ),
                for (var i = 1; i <= 9; i++)
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
          playerId: 'gp6',
          threats: ThreatSummary(atWarWith: ['gp5']),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 5,
            invadableProvinceIdsSorted: ['oldWorld|minor1'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        expect(
          belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'gap=4 exceeds kMaxPeerOwGapWithMinors; partner stays at war '
              'so the weaker peer cannot dump GP wars at arbitrary OW gaps',
        );
      },
    );

    test(
      'skips stronger self at 3-province gap even when minor pivot remains',
      () {
        // Symmetry guard for the !mutualPlateau && ownOw > partnerOw branch:
        // a stronger self is not peaced into a one-sided distraction exit.
        final game = Game(
          id: 'g-peer-gap-three-stronger-self',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 70,
            ),
            oldWorld: RegionData(
              provinces: [
                for (var i = 1; i <= 9; i++)
                  Province(
                    id: 'oldWorld|gp6_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp6',
                  ),
                for (var i = 1; i <= 6; i++)
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
          playerId: 'gp6',
          threats: ThreatSummary(atWarWith: ['gp5']),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 9,
            invadableProvinceIdsSorted: ['oldWorld|minor1'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        expect(
          belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'stronger self with !mutualPlateau is not peaced; only the '
              'weaker peer pivots off the distraction war',
        );
      },
    );

    test(
      'skips partner at 3-province gap when on-map minor is already at war',
      () {
        // Boundary: a minor still owns OW provinces (minorsOnMap=true) but
        // is itself at war with the planning GP, so hasUninvadedOldWorldMinor
        // returns false. Per the SPEC EXPAND clause "While uninvaded OW
        // minors remain ... within three provinces", the 3-province pivot
        // applies only while at least one minor is still uninvaded; once the
        // last uninvaded minor has been declared on, maxPeerOwGap reverts to
        // 1 and a gap=3 partner is no longer peaced. Pinning this prevents a
        // future tuning slice from silently treating any on-map minor as a
        // pivot (regardless of war state) and re-opening below-quota peer
        // dumps at arbitrary OW gaps.
        final game = Game(
          id: 'g-peer-gap-three-minor-at-war',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 70,
            ),
            oldWorld: RegionData(
              provinces: [
                for (var i = 1; i <= 6; i++)
                  Province(
                    id: 'oldWorld|gp6_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp6',
                  ),
                for (var i = 1; i <= 9; i++)
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
            const DiplomacyRelation(
              factionId1: 'gp6',
              factionId2: 'minor1',
              state: RelationState.atWar,
              score: 10,
            ),
          ],
        );
        const snapshot = AIWorldSnapshot(
          playerId: 'gp6',
          threats: ThreatSummary(atWarWith: ['gp5', 'minor1']),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 6,
            invadableProvinceIdsSorted: ['oldWorld|minor1'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        expect(
          belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'no uninvaded minor remains (minor1 is at war); maxPeerOwGap '
              'collapses to 1 so gp5 at gap=3 is not peaced',
        );
      },
    );
  });
}
