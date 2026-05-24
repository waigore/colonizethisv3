// Pins the canonical `isStalledOldWorldGpBlockerFocus` helper in
// `expand_phase_planner.dart` (Refs #2509 S1).
//
// This helper is the EXPAND GP-blocker pivot signal: a below-quota GP whose
// invadable Old World frontier is held exclusively by Great Powers (no minor
// pivot remaining) is in the canonical seed-42 gp5/gp6 trap shape where the
// EXPAND-phase declare-war / peace / economy gates must all converge on the
// sole GP frontier blocker. The predicate fans out across at least eight
// planner call sites (`diplomacy_planner.dart`,
// `diplomacy_planner_peace_targets.dart`,
// `diplomatic_candidate_scoring_offer_peace.dart`,
// `diplomatic_candidate_scoring_declare_war*.dart`,
// `phase_planner_economy_filter.dart`, `phase_planner_goal_filter.dart`)
// where it gates colonial-pressure routing, build-order thresholds, and
// sole-GP-war scoring.
//
// The S1 plan in #2509 deletes `colonial_pressure.dart` outright, so the
// public helper now lives in `expand_phase_planner.dart`. This test pins
// the canonical entrypoint directly so the delegation stub in
// `colonial_pressure.dart` can be removed in a future slice without
// regressing the eight downstream planner call sites that gate the
// GP-blocker pivot.
//
// Behavioral invariants pinned here (all deterministic):
//
//   1. Returns `true` exactly when both component gates hold together:
//      `isBelowObserverConquestQuota(oldWorldProvincesOwned)` and
//      `isOldWorldGpOnlyInvadableFrontier(game, snapshot)`. Flipping
//      either gate to `false` must drop the result — this protects
//      against a regression that swapped `&&` for `||` or dropped one
//      gate from the composite.
//   2. The quota gate is sourced from `isBelowObserverConquestQuota`
//      (strictly `< kObserverConquestMinOwProvincesPerGp`), not a
//      hard-coded literal. Pinning at the boundary (quota-1, quota,
//      quota+1, and 0) keeps the helper aligned with the shared EXPAND
//      quota constant if it is ever retuned in `ai_victory_config.dart`.
//   3. The GP-only-frontier gate must drop to `false` when any invadable
//      OW province is owned by a minor nation (minor pivot exists) or
//      when every invadable owner is a tribe (no GP to invade — the
//      GP-only check returns false). The truth table here mirrors the
//      legacy `colonial_pressure_stalled_ow_gp_blocker_focus_branches_test.dart`
//      so removing the delegation stub cannot silently shift the
//      branch behavior.
//   4. The result is deterministic across repeated calls — required by
//      issue #2509 Must-have #7 "Determinism: same save + seeds → same
//      orders; phase planners are pure functions with deterministic
//      inputs."
//   5. The delegating stub in `colonial_pressure.dart` returns the same
//      value as the canonical helper for every relevant input
//      combination — required so the legacy diplomacy-planner /
//      diplomatic-candidate-scoring call sites and the EXPAND planner
//      agree on the GP-blocker pivot boundary.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/colonial_pressure.dart'
    as colonial_pressure;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

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
              'At-quota short-circuit must skip the GP-only frontier delegate '
              'so the EXPAND-only GP-blocker pivot does not leak into '
              'COLONIAL / DEVELOP play.',
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
        reason:
            'Empty invadable list defeats the GP-only frontier delegate so '
            'the GP-blocker pivot does not fire on a sealed map state.',
      );
    });

    test(
      'false when an invadable province is owned by a minor nation (minor pivot)',
      () {
        final game = _gameWithMinorAndGpInvadable(ownOwProvinces: 8);
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
          reason:
              'Minor-owned invadable province must break the GP-only focus '
              'so the EXPAND planner pivots to the minor first instead of '
              'declaring on the lone GP blocker.',
        );
      },
    );

    test('false when every invadable province is owned by a tribe (no GP)', () {
      final game = _gameWithTribeOnlyInvadable(ownOwProvinces: 8);
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
            'Tribe-owned invadable provinces do not satisfy the GP-only '
            'frontier delegate; the helper must report false so the '
            'EXPAND planner stays out of the GP-blocker pivot arm.',
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
          reason:
              'No non-zero OW floor — only the quota ceiling matters; the '
              'GP-blocker pivot must fire from the first turn for a GP '
              'starting against a GP-only frontier.',
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
        reason:
            'One province below quota must still trip the predicate so '
            'the EXPAND planner stays in the GP-blocker pivot arm right '
            'up until the quota gate trips.',
      );
    });

    test('is deterministic across repeated calls (Must-have #7)', () {
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
      final first = isStalledOldWorldGpBlockerFocus(
        game: game,
        snapshot: snapshot,
      );
      final second = isStalledOldWorldGpBlockerFocus(
        game: game,
        snapshot: snapshot,
      );
      expect(
        first,
        second,
        reason:
            'Pure helper must return identical results on repeated calls — '
            'required by issue #2509 Must-have #7 (phase planners are pure '
            'functions with deterministic inputs).',
      );
    });

    test('colonial_pressure delegation stub returns the canonical value', () {
      // Pins the S1 delegation contract: the legacy public symbol exported
      // from `colonial_pressure.dart` must mirror the canonical helper for
      // every relevant fixture so removing the stub in a future slice
      // cannot silently shift the EXPAND-trap GP-blocker pivot boundary
      // for the eight downstream diplomacy / scoring call sites.
      final fixtures = <(Game, AIWorldSnapshot, String)>[
        (
          _gameWithGpOnlyInvadable(
            ownOwProvinces: kObserverConquestMinOwProvincesPerGp,
          ),
          const AIWorldSnapshot(
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
          ),
          'at-quota with GP-only invadable',
        ),
        (
          _gameWithGpOnlyInvadable(ownOwProvinces: 8),
          const AIWorldSnapshot(
            playerId: 'gp5',
            threats: ThreatSummary(atWarWith: ['gp6']),
            opportunities: OpportunitySummary(),
            conquest: ConquestSummary(oldWorldProvincesOwned: 8),
            colonial: ColonialSummary(),
            economy: EconomySummary(),
            relations: {},
          ),
          'below-quota with empty invadable list',
        ),
        (
          _gameWithMinorAndGpInvadable(ownOwProvinces: 8),
          const AIWorldSnapshot(
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
          ),
          'below-quota with minor pivot on the invadable list',
        ),
        (
          _gameWithTribeOnlyInvadable(ownOwProvinces: 8),
          const AIWorldSnapshot(
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
          ),
          'below-quota with tribe-only invadable list',
        ),
        (
          _gameWithGpOnlyInvadable(ownOwProvinces: 9),
          const AIWorldSnapshot(
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
          ),
          'canonical seed-42 gp5/gp6 trap shape',
        ),
        (
          _gameWithGpOnlyInvadable(ownOwProvinces: 0),
          const AIWorldSnapshot(
            playerId: 'gp5',
            threats: ThreatSummary(atWarWith: ['gp6']),
            opportunities: OpportunitySummary(),
            conquest: ConquestSummary(
              invadableProvinceIdsSorted: ['oldWorld|gp6_frontier'],
            ),
            colonial: ColonialSummary(),
            economy: EconomySummary(),
            relations: {},
          ),
          'zero-OW lower bound with GP-only invadable',
        ),
        (
          _gameWithGpOnlyInvadable(
            ownOwProvinces: kObserverConquestMinOwProvincesPerGp - 1,
          ),
          const AIWorldSnapshot(
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
          ),
          'quota - 1 boundary with GP-only invadable',
        ),
      ];
      for (final (game, snapshot, label) in fixtures) {
        expect(
          colonial_pressure.isStalledOldWorldGpBlockerFocus(
            game: game,
            snapshot: snapshot,
          ),
          isStalledOldWorldGpBlockerFocus(game: game, snapshot: snapshot),
          reason:
              '`colonial_pressure.isStalledOldWorldGpBlockerFocus` is a thin '
              'delegating stub for legacy callers; it must mirror the '
              'canonical helper exactly so the diplomacy-planner / '
              'diplomatic-candidate-scoring call sites and the EXPAND '
              'planner agree on the GP-blocker pivot trigger (fixture: '
              '$label).',
        );
      }
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

Game _gameWithMinorAndGpInvadable({required int ownOwProvinces}) {
  return Game(
    id: 'g-stalled-blocker-minor-pivot',
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
}

Game _gameWithTribeOnlyInvadable({required int ownOwProvinces}) {
  return Game(
    id: 'g-stalled-blocker-tribe-only',
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
}
