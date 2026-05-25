import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/colonial_pressure.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// Pins the `isStalledOldWorldGpBlockerFocus` branch table (Refs #2509 § Observer
// goal phases (Full AI) — "EXPAND GP-blocker pivot"). The predicate fans out to
// at least eight planner call sites (`diplomacy_planner.dart`,
// `diplomacy_planner_peace_targets.dart`, `diplomatic_candidate_scoring_offer_peace.dart`,
// `diplomatic_candidate_scoring_declare_war*.dart`, `domain_planner_orchestrator.dart`,
// `strategic_ai.dart`) where it gates colonial-pressure routing, build-order
// thresholds, and sole-GP-war scoring — yet no test exercised its direct
// truth table on `origin/dev`. This file pins every branch so a silent change
// to either the below-quota cutoff or the GP-only-frontier delegation surfaces
// here before the planner-output integration tests do.
//
// Branch table covered (`isBelowObserverConquestQuota(own)` × `isOldWorldGpOnlyInvadableFrontier`):
//
// 1. `own >= kObserverConquestMinOwProvincesPerGp` → false (at-quota short-circuit
//    even with a clean GP-only frontier).
// 2. `own < kObserverConquestMinOwProvincesPerGp` AND `invadableProvinceIdsSorted`
//    empty → false (frontier delegate has no invadable list).
// 3. Below quota AND any invadable owner is a minor nation → false (minor
//    pivot exists, no GP-only blocker focus).
// 4. Below quota AND every invadable owner is a tribe (not minor, not GP)
//    → false (no GP to invade — gp-only check returns false).
// 5. Below quota AND all invadable owners are Great Powers → true
//    (canonical seed-42 gp5/gp6 trap shape).
// 6. Lower-quota boundary: `own == 0` with all-GP invadable list → true
//    (the predicate must not gate on a non-zero floor).
// 7. Upper-quota boundary: `own == kObserverConquestMinOwProvincesPerGp - 1`
//    with all-GP invadable list → true (one province below quota still trips).
void main() {
  group('isStalledOldWorldGpBlockerFocus', () {
    test(
      'false when at the observer OW quota even with a GP-only invadable frontier',
      () {
        final game = _gameWithGpOnlyInvadable(
          ownOwProvinces: kObserverConquestMinOwProvincesPerGp,
        );
        const snapshot = AIWorldSnapshot(
          playerId: 'gp5',
          threats: ThreatSummary(atWarWith: ['gp6']),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
            invadableProvinceIdsSorted: ['oldWorld|gp6_frontier'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        expect(
          isStalledOldWorldGpBlockerFocus(game: game, snapshot: snapshot),
          isFalse,
          reason:
              'at-quota short-circuit must skip the GP-only frontier delegate',
        );
      },
    );

    test('false when below quota but no invadable provinces remain', () {
      final game = _gameWithGpOnlyInvadable(ownOwProvinces: 8);
      const snapshot = AIWorldSnapshot(
        playerId: 'gp5',
        threats: ThreatSummary(atWarWith: ['gp6']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(oldWorldProvincesOwned: 8),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        isStalledOldWorldGpBlockerFocus(game: game, snapshot: snapshot),
        isFalse,
        reason: 'empty invadable list defeats the GP-only frontier delegate',
      );
    });

    test(
      'false when an invadable province is owned by a minor nation (minor pivot)',
      () {
        final game = Game(
          id: 'g-stalled-blocker-minor-pivot',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 60),
            oldWorld: RegionData(
              provinces: [
                for (var i = 0; i < 8; i++)
                  Province(
                    id: 'oldWorld|gp5_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp5',
                  ),
                const Province(
                  id: 'oldWorld|gp6_frontier',
                  regionId: 'oldWorld',
                  ownerId: 'gp6',
                ),
                const Province(
                  id: 'oldWorld|minor1_p1',
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
        );
        const snapshot = AIWorldSnapshot(
          playerId: 'gp5',
          threats: ThreatSummary(atWarWith: ['gp6']),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 8,
            invadableProvinceIdsSorted: [
              'oldWorld|gp6_frontier',
              'oldWorld|minor1_p1',
            ],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        expect(
          isStalledOldWorldGpBlockerFocus(game: game, snapshot: snapshot),
          isFalse,
          reason: 'minor-owned invadable province must break the GP-only focus',
        );
      },
    );

    test('false when every invadable province is owned by a tribe (no GP)', () {
      final game = Game(
        id: 'g-stalled-blocker-tribe-only',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 60),
          oldWorld: RegionData(
            provinces: [
              for (var i = 0; i < 8; i++)
                Province(
                  id: 'oldWorld|gp5_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp5',
                ),
              const Province(
                id: 'oldWorld|tribe1_p1',
                regionId: 'oldWorld',
                ownerId: 'tribe1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp5', displayName: 'P5', isHuman: false),
          Player(id: 'gp6', displayName: 'P6', isHuman: false),
        ],
        tribes: const [Tribe(id: 'tribe1', displayName: 'T1')],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp5',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 8,
          invadableProvinceIdsSorted: ['oldWorld|tribe1_p1'],
        ),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        isStalledOldWorldGpBlockerFocus(game: game, snapshot: snapshot),
        isFalse,
        reason:
            'tribe-owned invadable provinces do not satisfy the GP-only check',
      );
    });

    test(
      'true when below quota and every invadable province is owned by a Great Power '
      '(canonical seed-42 gp5/gp6 trap)',
      () {
        final game = _gameWithGpOnlyInvadable(ownOwProvinces: 9);
        const snapshot = AIWorldSnapshot(
          playerId: 'gp5',
          threats: ThreatSummary(atWarWith: ['gp6']),
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
          isStalledOldWorldGpBlockerFocus(game: game, snapshot: snapshot),
          isTrue,
        );
      },
    );

    test(
      'true at zero OW provinces with an all-GP invadable list (lower bound)',
      () {
        final game = _gameWithGpOnlyInvadable(ownOwProvinces: 0);
        const snapshot = AIWorldSnapshot(
          playerId: 'gp5',
          threats: ThreatSummary(atWarWith: ['gp6']),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            invadableProvinceIdsSorted: ['oldWorld|gp6_frontier'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        expect(
          isStalledOldWorldGpBlockerFocus(game: game, snapshot: snapshot),
          isTrue,
          reason: 'no non-zero OW floor — only the quota ceiling matters',
        );
      },
    );

    test('true just below the observer OW quota with an all-GP invadable list '
        '(quota - 1 boundary)', () {
      final game = _gameWithGpOnlyInvadable(
        ownOwProvinces: kObserverConquestMinOwProvincesPerGp - 1,
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp5',
        threats: ThreatSummary(atWarWith: ['gp6']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 1,
          invadableProvinceIdsSorted: ['oldWorld|gp6_frontier'],
        ),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        isStalledOldWorldGpBlockerFocus(game: game, snapshot: snapshot),
        isTrue,
        reason: 'one province below quota must still trip the predicate',
      );
    });
  });
}

Game _gameWithGpOnlyInvadable({required int ownOwProvinces}) {
  return Game(
    id: 'g-stalled-blocker-gp-only',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 60),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < ownOwProvinces; i++)
            Province(
              id: 'oldWorld|gp5_$i',
              regionId: 'oldWorld',
              ownerId: 'gp5',
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
  );
}
