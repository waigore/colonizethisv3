// Pins the function-unit truth table of
// `isMutualBelowQuotaPlateauPeer({ownOw, partnerOw})` from
// `colonial_pressure.dart` (Refs #2509).
//
//   SPEC/ai/ai-architecture.md § Observer goal phases (Full AI), EXPAND:
//     "peace below-quota Great Power peers when both are stalled in the
//     observer start-size band and within one province of each other".
//
// The implementation:
//
//   bool isMutualBelowQuotaPlateauPeer({
//     required int ownOw,
//     required int partnerOw,
//   }) =>
//       isStalledOldWorldExpansion(ownOw) &&
//       isStalledOldWorldExpansion(partnerOw) &&
//       isBelowObserverConquestQuota(ownOw) &&
//       isBelowObserverConquestQuota(partnerOw) &&
//       (partnerOw - ownOw).abs() <= 1;
//
// Effective truth table given the data-side helpers
// (`packages/colonizethis_data/lib/src/ai_victory_config.dart`):
//   - `isStalledOldWorldExpansion(ow)` ≡ `ow > 0 && ow <= 9` (per
//     `kStalledOldWorldProvinceThreshold = 9`).
//   - `isBelowObserverConquestQuota(ow)` ≡ `ow < 10` (per
//     `kObserverConquestMinOwProvincesPerGp = 10`).
//   - True iff both `ownOw` and `partnerOw` are in `[1, 9]` and
//     `|partnerOw - ownOw| <= 1`.
//
// The predicate fans out to **9 call sites** across `diplomacy_planner.dart`
// (peace planning, blocker preservation), `colonial_pressure.dart`
// (`belowQuotaPeerGpPeaceTargets`), and
// `diplomatic_candidate_scoring_declare_war.dart` (peer-stall declare-war
// gating). A regression flipping the gap window, the lower stalled bound
// (e.g. dropping the `ow > 0` guard inside `isStalledOldWorldExpansion`),
// or the 10-province quota bound would silently re-open dumped GP-vs-GP
// wars at arbitrary OW spreads, undermining the seed-42 turn-100 OW
// conquest gate this pivot exists to protect.
//
// Existing related coverage (not redundant with this pin):
//
//   - `colonial_pressure_peer_gap_boundary_test.dart` — pins the **3-province
//     gap with uninvaded minor** branch of the *consumer*
//     `belowQuotaPeerGpPeaceTargets`; that helper's `maxPeerOwGap` is gated
//     by `hasUninvadedOldWorldMinor` (3-province window when a minor pivot
//     remains, otherwise 1). This exercises the consumer's outer
//     branch — it does **not** pin the inner `isMutualBelowQuotaPlateauPeer`
//     truth table directly, and a future tuning slice could swap the inner
//     predicate (e.g. broadening to 2-province gap) without tripping any
//     consumer test.
//   - `domain_planner_orchestrator_expand_gp_only_blocker_declare_test.dart`
//     references `isMutualBelowQuotaPlateauPeer(ownOw=7, partnerOw=4) =
//     false` only as a comment justifying its fixture. No behaviour test
//     calls the helper directly.
//   - `diplomacy_planner_below_quota_peace_part2_test.dart` and
//     `diplomatic_candidate_scoring_declare_war_*_test.dart` pin
//     orchestrator-boundary effects of the peer-plateau predicate but
//     never the predicate itself, so a constant tweak inside the helper
//     can leak into orchestration in subtle ways before any test fails.
//
// Coverage layers in this file:
//
//   - **Canonical mutual plateau:** `(ownOw, partnerOw)` pairs that satisfy
//     all five conjuncts — both stalled, both below quota, gap ∈ {0, 1}.
//   - **Stalled-band lower boundary:** `ownOw == 1` flips the
//     `isStalledOldWorldExpansion(ow > 0)` guard from false (at `ow == 0`)
//     to true; pins both sides of the boundary on `ownOw` and `partnerOw`.
//   - **Stalled-band upper boundary:** `ownOw == 9` is the inclusive top of
//     the stalled band (per `kStalledOldWorldProvinceThreshold`); pin both
//     `ownOw == 9, partnerOw == 9` (true) and `ownOw == 10, partnerOw == 9`
//     (false — quota met means no longer stalled).
//   - **Quota guard with stalled inputs:** `ownOw == 10` already exits the
//     stalled band, so the redundant `isBelowObserverConquestQuota` checks
//     never observe a `>= 10` value through this helper today; pin the
//     behaviour explicitly so future refactors that loosen
//     `kStalledOldWorldProvinceThreshold` past `kObserverConquestMin...` do
//     not silently widen the plateau window.
//   - **Gap window:** `gap == 1` (true), `gap == 2` (false), and
//     `gap == 0` (true) on both sides of the diagonal.
//   - **Symmetry:** `isMutualBelowQuotaPlateauPeer(ownOw: a, partnerOw: b)`
//     equals `(b, a)` for every pin pair, so the helper cannot be
//     accidentally rewritten to assert "weaker peer only".
//   - **Determinism:** repeated invocations on identical inputs are
//     bit-identical (must-have #7 alignment with existing
//     `colonizethis_ai` determinism patterns).
//
// No production code changes — pin tests only.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/src/planning/colonial_pressure.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

void main() {
  group('isMutualBelowQuotaPlateauPeer (truth table)', () {
    group('canonical mutual plateau (true)', () {
      test('both at quota minus 2 (8/8) returns true', () {
        expect(
          isMutualBelowQuotaPlateauPeer(ownOw: 8, partnerOw: 8),
          isTrue,
          reason:
              'observer default-start stall band inclusive of 8; gap=0 satisfies '
              'the 1-province peer window.',
        );
      });

      test('quota minus 2 vs quota minus 1 (8/9) returns true', () {
        expect(
          isMutualBelowQuotaPlateauPeer(ownOw: 8, partnerOw: 9),
          isTrue,
          reason:
              'both stalled (≤ kStalledOldWorldProvinceThreshold), both below '
              'quota (< kObserverConquestMinOwProvincesPerGp), gap=1.',
        );
      });

      test('symmetry guard 9/8 returns true (mirror of 8/9)', () {
        expect(
          isMutualBelowQuotaPlateauPeer(ownOw: 9, partnerOw: 8),
          isTrue,
          reason:
              'absolute gap is symmetric so the predicate must hold from '
              'either GP\'s viewpoint when the band/quota guards both pass.',
        );
      });

      test('both at upper stall edge (9/9) returns true', () {
        expect(
          isMutualBelowQuotaPlateauPeer(ownOw: 9, partnerOw: 9),
          isTrue,
          reason:
              'kStalledOldWorldProvinceThreshold = 9 is inclusive on both sides; '
              'gap=0 keeps the peer window satisfied.',
        );
      });
    });

    group('stalled-band lower boundary', () {
      test('ownOw == 0 returns false even when partnerOw is in band', () {
        expect(
          isMutualBelowQuotaPlateauPeer(ownOw: 0, partnerOw: 8),
          isFalse,
          reason:
              'isStalledOldWorldExpansion requires ow > 0 to filter the start-of-game '
              'pre-init / wiped-from-map state out of the peer-stall pivot.',
        );
      });

      test('partnerOw == 0 returns false even when ownOw is in band', () {
        expect(
          isMutualBelowQuotaPlateauPeer(ownOw: 8, partnerOw: 0),
          isFalse,
          reason:
              'symmetric guard: a partner on zero OW provinces cannot back into '
              'the peer-plateau pivot just because we are stalled.',
        );
      });

      test('lowest in-band 1/1 returns true', () {
        expect(
          isMutualBelowQuotaPlateauPeer(ownOw: 1, partnerOw: 1),
          isTrue,
          reason:
              'ow=1 satisfies isStalledOldWorldExpansion (ow > 0 && ow <= 9); '
              'gap=0 keeps the predicate true.',
        );
      });

      test('lowest in-band edge 1/2 returns true', () {
        expect(
          isMutualBelowQuotaPlateauPeer(ownOw: 1, partnerOw: 2),
          isTrue,
          reason:
              'lower boundary plus gap=1 stays inside the predicate envelope.',
        );
      });
    });

    group('stalled-band upper boundary / quota guard', () {
      test('ownOw at quota (10) returns false against partner in band', () {
        expect(
          isMutualBelowQuotaPlateauPeer(ownOw: 10, partnerOw: 9),
          isFalse,
          reason:
              'reaching the per-GP quota exits the stalled-band guard '
              '(isStalledOldWorldExpansion: ow <= 9); the peer pivot is for '
              'sub-quota plateaus only.',
        );
      });

      test('partnerOw at quota (10) returns false against ownOw in band', () {
        expect(
          isMutualBelowQuotaPlateauPeer(ownOw: 9, partnerOw: 10),
          isFalse,
          reason:
              'symmetric guard: a partner who has cleared the quota is no longer '
              'a co-stalled peer, even when our gap is 1.',
        );
      });

      test('both above quota (12/12) returns false', () {
        expect(
          isMutualBelowQuotaPlateauPeer(ownOw: 12, partnerOw: 12),
          isFalse,
          reason:
              'both well past quota fails isStalledOldWorldExpansion (ow > 9) '
              'and the redundant below-quota guard; gap-only matches must not '
              'open this pivot.',
        );
      });

      test('ownOw at quota+1 vs partnerOw at quota returns false', () {
        expect(
          isMutualBelowQuotaPlateauPeer(ownOw: 11, partnerOw: 10),
          isFalse,
          reason:
              'pinned together with the 10/9 case so a future refactor that '
              'loosens kStalledOldWorldProvinceThreshold past '
              'kObserverConquestMinOwProvincesPerGp does not silently widen '
              'the plateau window.',
        );
      });
    });

    group('peer-gap window', () {
      test('gap == 0 (mid-band 5/5) returns true', () {
        expect(
          isMutualBelowQuotaPlateauPeer(ownOw: 5, partnerOw: 5),
          isTrue,
          reason: 'mid-band identical OW sizes are the canonical plateau case.',
        );
      });

      test('gap == 1 ascending (5/6) returns true', () {
        expect(
          isMutualBelowQuotaPlateauPeer(ownOw: 5, partnerOw: 6),
          isTrue,
          reason:
              'partner one province ahead is still inside the 1-province peer '
              'window.',
        );
      });

      test('gap == 1 descending (6/5) returns true', () {
        expect(
          isMutualBelowQuotaPlateauPeer(ownOw: 6, partnerOw: 5),
          isTrue,
          reason:
              'partner one province behind mirrors the ascending case via '
              '|partnerOw - ownOw|.',
        );
      });

      test('gap == 2 ascending (5/7) returns false', () {
        expect(
          isMutualBelowQuotaPlateauPeer(ownOw: 5, partnerOw: 7),
          isFalse,
          reason:
              'gap=2 violates the |partnerOw - ownOw| <= 1 peer window even '
              'with both inputs deep inside the stall band.',
        );
      });

      test('gap == 2 descending (7/5) returns false', () {
        expect(
          isMutualBelowQuotaPlateauPeer(ownOw: 7, partnerOw: 5),
          isFalse,
          reason:
              'symmetry of the gap window: the predicate must not flip on '
              'caller orientation.',
        );
      });

      test('gap == 8 across full band (1/9) returns false', () {
        expect(
          isMutualBelowQuotaPlateauPeer(ownOw: 1, partnerOw: 9),
          isFalse,
          reason:
              'pins the worst-case in-band gap so a future refactor that '
              'inadvertently widens the peer window cannot regress this case.',
        );
      });
    });

    group('determinism / symmetry guards', () {
      test('repeated invocation on same inputs is bit-identical', () {
        // Aligns with the existing colonizethis_ai determinism pattern from
        // economy_planner_test.dart / tactical_ai_test.dart (must-have #7).
        const samples = <List<int>>[
          [8, 9],
          [9, 8],
          [10, 9],
          [0, 8],
          [5, 5],
          [5, 7],
        ];
        for (final pair in samples) {
          final first = isMutualBelowQuotaPlateauPeer(
            ownOw: pair[0],
            partnerOw: pair[1],
          );
          final second = isMutualBelowQuotaPlateauPeer(
            ownOw: pair[0],
            partnerOw: pair[1],
          );
          expect(
            first,
            second,
            reason:
                'pure-int predicate must yield identical results on repeated '
                'calls for ${pair[0]}/${pair[1]}.',
          );
        }
      });

      test('pairwise symmetry holds across the full pin set', () {
        const pairs = <List<int>>[
          [0, 8],
          [1, 1],
          [1, 2],
          [1, 9],
          [5, 5],
          [5, 6],
          [5, 7],
          [8, 8],
          [8, 9],
          [9, 9],
          [9, 10],
          [10, 9],
          [11, 10],
          [12, 12],
        ];
        for (final pair in pairs) {
          final forward = isMutualBelowQuotaPlateauPeer(
            ownOw: pair[0],
            partnerOw: pair[1],
          );
          final reverse = isMutualBelowQuotaPlateauPeer(
            ownOw: pair[1],
            partnerOw: pair[0],
          );
          expect(
            forward,
            reverse,
            reason:
                'predicate must be invariant under (ownOw, partnerOw) swap '
                'for ${pair[0]}/${pair[1]}; |a - b| is symmetric and both band '
                'guards apply equally to either input.',
          );
        }
      });

      test('constants ground the upper boundary (defensive sanity)', () {
        // Locks the band/quota constants the truth table is built on. A
        // future tightening of either (e.g. raising the quota or lowering
        // the stalled threshold) should fail this test deliberately so the
        // owning slice updates the truth table above in lockstep.
        expect(
          kStalledOldWorldProvinceThreshold,
          9,
          reason:
              'the upper stall boundary the truth table relies on; changing it '
              'changes which (ownOw, partnerOw) pairs the predicate accepts.',
        );
        expect(
          kObserverConquestMinOwProvincesPerGp,
          10,
          reason:
              'the per-GP quota bound that gates the redundant below-quota '
              'check inside the predicate.',
        );
      });
    });
  });
}
