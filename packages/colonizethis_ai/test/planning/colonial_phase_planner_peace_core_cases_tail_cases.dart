// Case bodies for `colonial_phase_planner_test.dart` (Refs #4291 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1.

// Unit tests for the COLONIAL-phase planner contracts in
// `packages/colonizethis_ai/lib/src/planning/colonial_phase_planner.dart`
// (Refs #2509 S3 / S10 + S7 below-quota peer exclusion).
//
// Spec contract (issue #2509 § COLONIAL phase planner § planColonialPeace
// plus the `phase-planner-architecture.md` below-quota peer AC):
//
//   "Peace all at-war Great Powers, with TWO exceptions:
//    1. Keep fighting a GP that owns a province blocking the primary
//       colonial NW target (primaryColonialGpBlocker).
//    2. Keep fighting a Great Power peer whose OW province count is
//       below `kObserverConquestMinOwProvincesPerGp` (the OW quota).
//       This preserves Must-have #5 ('OW pressure preserved while
//       below quota'): a peer still in EXPAND may depend on the
//       active COLONIAL player as their only invadable OW
//       frontier-blocker war.
//
//    Never peace tribe/minor colonial targets until:
//    → Objective met (tribe no longer owns the target NW province), OR
//    → War is unwinnable (zero regiments, no treasury, can't build)."
//
// Mirrors the test pattern established for the EXPAND-phase planner in
// `expand_phase_planner_test.dart` and the DEVELOP-phase planner in
// `develop_phase_planner_test.dart`: small synthetic fixtures, one
// branch arm per test, in-module pin (planner module never re-checks
// phase, so these tests stay scoped to the GP filter, blocker scan,
// blocker membership guard, the below-quota peer filter, and the
// deterministic-sort contract). The tribe / minor "never peace" rule
// is preserved structurally via the `game.playerById` filter; the
// tests pin that behavior directly. The default `buildColonialPeaceGame`
// helper puts every roster GP at the OW quota
// (`kObserverConquestMinOwProvincesPerGp = 10`) so the at-quota tests
// surface the canonical paths without accidental below-quota
// filtering; the dedicated below-quota tests override the per-GP OW
// count via `perGpOwCounts`.
//
// `planColonialPeace` tests:
//
//   1. **Empty `atWarWith`:** no live wars -> empty list (loop body
//      never runs; trailing sort is a no-op; blocker scan does not run).
//   2. **Only tribes/minors in `atWarWith`:** non-GP factions are
//      filtered via `game.playerById` returning null -> empty (COLONIAL
//      peace is GP-only; tribe / minor wars continue per the
//      "Never peace tribe/minor" rule).
//   3. **Multi-GP at quota, no invadable NW (blocker null):** peace
//      ALL at-war GPs sorted ascending (no exception applies; "peace
//      all at-quota peers" arm).
//   4. **Multi-GP at quota, blocker is a non-at-war GP:** the blocker
//      is a different GP than any live war front -> peace all live
//      fronts ascending (`factionId != blocker` arm).
//   5. **Multi-GP at quota, blocker among `gpWars`:** peace all GPs
//      except the blocker, sorted ascending (canonical COLONIAL-peace
//      happy path).
//   6. **Sole GP at war IS the blocker:** keep fighting the lone
//      blocker -> empty (the lone war IS the colonial blocker war).
//   7. **Sole at-quota GP at war is NOT the blocker:** peace that
//      single GP -> `[that GP]`.
//   8. **Three GPs at war (input order shuffled):** trailing
//      `..sort()` restores ascending order (Must-have #7 pin).
//   9. **Mixed GP + non-GP `atWarWith` with blocker:** non-GP ids
//      dropped before the blocker filter; remaining GPs sorted
//      ascending less blocker (composite filter pin).
//  10. **Determinism:** identical inputs yield identical lists across
//      repeated calls (Must-have #7).
//  11. **Single below-quota peer at war -> empty (Refs #2509 S7):**
//      the active player is at war with exactly one Great Power whose
//      OW province count is below `kObserverConquestMinOwProvincesPerGp`
//      and that peer is not the colonial blocker -> the new exclusion
//      arm fires, returning an empty list so the COLONIAL planner
//      does not emit `offerPeace` while the peer is still in EXPAND.
//  12. **Mixed at-quota + below-quota peers at war (Refs #2509 S7):**
//      below-quota peer dropped; at-quota peers peaced sorted
//      ascending. Pins that the exclusion arm is per-GP, not a
//      whole-list short-circuit.
//  13. **Below-quota peer that IS the blocker (Refs #2509 S7):** the
//      blocker exclusion and the below-quota peer exclusion compose
//      additively -- the blocker is removed once via either arm and
//      the remaining at-quota peers are returned sorted ascending.
//
// This file is the in-module pin for the COLONIAL planner. The S5
// orchestrator wiring through `phase_planner_dispatch.dart` /
// `domain_planner_orchestrator.dart` is in place, so this pin guards the
// canonical `planColonialPeace` contract. The function-unit pin on the
// legacy `colonialPhaseGpPeaceTargets` helper in
// `observer_goal_phase_colonial_peace_blocker_branches_test.dart` keeps
// the no-`phasePlan` fallback path through
// `collectStalledGreatPowerPeaceTargets` covered.

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/colonial_phase_planner_test_support.dart';


void registerColonialPhasePlannerPeaceCoreCasesTail() {
  group('planColonialPeace', () {
    test('multi-GP, blocker among gpWars -> peace all except blocker', () {
      // Canonical COLONIAL happy path: gp2 owns the invadable NW
      // (blocker), gp3 + gp4 are non-blocker fronts -> peace gp3 and
      // gp4 sorted ascending; keep fighting gp2.
      final game = buildColonialPeaceGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|gp2_a',
            regionId: 'newWorld',
            ownerId: kColonialPhaseGp2,
          ),
          Province(
            id: 'newWorld|gp2_b',
            regionId: 'newWorld',
            ownerId: kColonialPhaseGp2,
          ),
        ],
      );
      final snapshot = buildColonialPeaceSnapshot(
        atWarWith: const [
          kColonialPhaseGp2,
          kColonialPhaseGp3,
          kColonialPhaseGp4,
        ],
        invadableNw: const ['newWorld|gp2_a', 'newWorld|gp2_b'],
      );
      expect(
        planColonialPeace(game: game, snapshot: snapshot),
        const [kColonialPhaseGp3, kColonialPhaseGp4],
        reason:
            'Blocker gp2 is preserved (keep fighting the colonial NW '
            'blocker); non-blocker GPs gp3 + gp4 are peaced in '
            'ascending sort (canonical COLONIAL-peace happy path).',
      );
    });

    test('sole GP at war IS the blocker -> empty (keep fighting)', () {
      // Exactly one GP at war (gp2) and that GP IS the colonial
      // blocker. The function falls through to the
      // "exclude blocker" comprehension which yields an empty list
      // because the only candidate equals the blocker. A regression
      // that emitted `[gp2]` here would prematurely peace the
      // colonial blocker and stall NW acquisition.
      final game = buildColonialPeaceGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|gp2_a',
            regionId: 'newWorld',
            ownerId: kColonialPhaseGp2,
          ),
        ],
      );
      final snapshot = buildColonialPeaceSnapshot(
        atWarWith: const [kColonialPhaseGp2],
        invadableNw: const ['newWorld|gp2_a'],
      );
      expect(
        planColonialPeace(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Sole GP front IS the colonial NW blocker -- keep fighting; '
            'the planner returns empty so the orchestrator emits no '
            '`offerPeace` toward gp2 this turn.',
      );
    });

    test('sole GP at war is NOT the blocker -> peace that single GP', () {
      // Exactly one GP at war (gp3) and the colonial blocker is a
      // different GP (gp4) NOT in `atWarWith`. The membership guard
      // fires (`!gpWars.contains(gp4)`) -> peace all `gpWars`
      // sorted. Result: `[gp3]`. This is the explicit divergence
      // from the legacy `colonialPhaseGpPeaceTargets` short-circuit
      // `gpWars.length <= 1 → const []`: the new spec says "Peace
      // all at-war Great Powers" without a length guard, so a lone
      // non-blocker war must still be peaced.
      final game = buildColonialPeaceGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|gp4_a',
            regionId: 'newWorld',
            ownerId: kColonialPhaseGp4,
          ),
        ],
      );
      final snapshot = buildColonialPeaceSnapshot(
        atWarWith: const [kColonialPhaseGp3],
        invadableNw: const ['newWorld|gp4_a'],
      );
      expect(
        planColonialPeace(game: game, snapshot: snapshot),
        const [kColonialPhaseGp3],
        reason:
            'Sole non-blocker GP front -- new spec "Peace all" arm '
            'fires regardless of `gpWars.length`. The single GP is '
            'returned (divergence from legacy `gpWars.length <= 1` '
            'short-circuit).',
      );
    });

    test('3 GPs at war (input order shuffled) -> ascending sort', () {
      // Determinism pin (Must-have #7). Three GP fronts (gp4, gp3, gp2)
      // with gp2 as blocker -> peace gp3 + gp4 in ascending order
      // regardless of input order. A regression that returned the
      // input order would surface here as `[gp4, gp3]`.
      final game = buildColonialPeaceGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|gp2_a',
            regionId: 'newWorld',
            ownerId: kColonialPhaseGp2,
          ),
        ],
      );
      final snapshot = buildColonialPeaceSnapshot(
        atWarWith: const [
          kColonialPhaseGp4,
          kColonialPhaseGp3,
          kColonialPhaseGp2,
        ],
        invadableNw: const ['newWorld|gp2_a'],
      );
      expect(
        planColonialPeace(game: game, snapshot: snapshot),
        const [kColonialPhaseGp3, kColonialPhaseGp4],
        reason:
            'Trailing `..sort()` restores ascending order regardless of '
            'input order (Refs #2509 Must-have #7).',
      );
    });
  });
}
