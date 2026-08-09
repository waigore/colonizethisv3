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


void registerColonialPhasePlannerPeaceEdgeCases() {
  group('planColonialPeace', () {
    test(
      'mixed GP + non-GP atWarWith with blocker -> only non-blocker GPs',
      () {
        // Composes both filters in one fixture: tribe1 + minor1 must
        // drop before the GP-only blocker filter; the surviving GP
        // fronts (gp2, gp3, gp4) are then thinned to exclude the
        // blocker (gp2). Input order `[gp4, tribe1, gp3, minor1, gp2]`
        // exercises the GP filter, the blocker scan, and the trailing
        // sort all together.
        final game = buildColonialPeaceGame(
          newWorldProvinces: const [
            Province(
              id: 'newWorld|gp2_a',
              regionId: 'newWorld',
              ownerId: kColonialPhaseGp2,
            ),
          ],
          tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'T1')],
          minorNations: const [
            MinorNation(id: kColonialPhaseMinor1, displayName: 'M1'),
          ],
        );
        final snapshot = buildColonialPeaceSnapshot(
          atWarWith: const [
            kColonialPhaseGp4,
            kColonialPhaseTribe1,
            kColonialPhaseGp3,
            kColonialPhaseMinor1,
            kColonialPhaseGp2,
          ],
          invadableNw: const ['newWorld|gp2_a'],
        );
        expect(
          planColonialPeace(game: game, snapshot: snapshot),
          const [kColonialPhaseGp3, kColonialPhaseGp4],
          reason:
              'Non-GP factions filtered out via `game.playerById`; '
              'blocker (gp2) excluded; remaining GP fronts (gp3, gp4) '
              'returned sorted ascending.',
        );
      },
    );

    test('determinism: identical inputs produce identical lists', () {
      // Pins Must-have #7 (determinism) at the in-module level. The
      // mixed-input fixture exercises the GP filter, the blocker
      // scan, and the sort in one pass; repeating the call must
      // yield byte-identical lists.
      final game = buildColonialPeaceGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|gp2_a',
            regionId: 'newWorld',
            ownerId: kColonialPhaseGp2,
          ),
        ],
        tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'T1')],
        minorNations: const [
          MinorNation(id: kColonialPhaseMinor1, displayName: 'M1'),
        ],
      );
      final snapshot = buildColonialPeaceSnapshot(
        atWarWith: const [
          kColonialPhaseGp4,
          kColonialPhaseTribe1,
          kColonialPhaseGp3,
          kColonialPhaseMinor1,
          kColonialPhaseGp2,
        ],
        invadableNw: const ['newWorld|gp2_a'],
      );
      final first = planColonialPeace(game: game, snapshot: snapshot);
      final second = planColonialPeace(game: game, snapshot: snapshot);
      expect(second, first);
    });

    test(
      'single below-quota peer at war -> empty (Refs #2509 S7 Must-have #5)',
      () {
        // The active player (gp1, COLONIAL at quota) is at war with
        // exactly one Great Power peer (gp3) whose OW province count
        // is 7 -- below `kObserverConquestMinOwProvincesPerGp = 10`.
        // No invadable NW is owned by gp3 (the blocker scan returns
        // null). The new below-quota peer exclusion arm fires: the
        // planner must NOT emit `offerPeace` toward gp3 while gp3 is
        // still in EXPAND, otherwise `war_resolver.dart`'s one-sided
        // GP peace conditions would end gp3's only OW frontier-blocker
        // war on a single offerer.
        final game = buildColonialPeaceGame(
          perGpOwCounts: const {kColonialPhaseGp3: 7},
        );
        final snapshot = buildColonialPeaceSnapshot(
          atWarWith: const [kColonialPhaseGp3],
        );
        expect(
          planColonialPeace(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'gp3 is a below-quota peer (OW = 7 < quota = 10) and not the '
              'colonial blocker -- the below-quota exclusion arm must drop '
              'it so the COLONIAL planner emits no `offerPeace` while the '
              'peer is still in EXPAND (Refs #2509 § Must-have #5).',
        );
      },
    );

    test(
      'mixed at-quota + below-quota peers at war -> only at-quota peers peaced (Refs #2509 S7)',
      () {
        // gp2 is at quota (10 OW) and not the blocker; gp3 is below
        // quota (8 OW, still in EXPAND); gp4 is at quota (10 OW) and
        // not the blocker. No invadable NW is owned by any GP (blocker
        // is null). Expected: peace gp2 + gp4 sorted ascending; gp3 is
        // dropped by the below-quota exclusion arm. Pins that the
        // exclusion is per-GP and does not short-circuit the whole
        // list.
        final game = buildColonialPeaceGame(
          perGpOwCounts: const {kColonialPhaseGp3: 8},
        );
        final snapshot = buildColonialPeaceSnapshot(
          atWarWith: const [
            kColonialPhaseGp4,
            kColonialPhaseGp3,
            kColonialPhaseGp2,
          ],
        );
        expect(
          planColonialPeace(game: game, snapshot: snapshot),
          const [kColonialPhaseGp2, kColonialPhaseGp4],
          reason:
              'Below-quota peer gp3 dropped (OW = 8 < quota = 10); at-quota '
              'peers gp2 + gp4 peaced in ascending sort (Refs #2509 § '
              'Must-have #5; trailing `..sort()` -> Must-have #7).',
        );
      },
    );

    test(
      'below-quota peer that IS the blocker -> dropped once, remaining at-quota peers peaced (Refs #2509 S7)',
      () {
        // gp2 is the colonial blocker (owns the only invadable NW
        // province) AND is below quota (OW = 6). gp3 and gp4 are at
        // quota and not the blocker. Both exclusion arms target gp2:
        // it is excluded once and the remaining at-quota peers
        // (gp3, gp4) are returned sorted ascending. Pins that the
        // composed filter does not double-drop or accidentally
        // surface gp2 via either arm.
        final game = buildColonialPeaceGame(
          perGpOwCounts: const {kColonialPhaseGp2: 6},
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
              'gp2 is both the colonial NW blocker and a below-quota peer; '
              'either exclusion arm drops it. Remaining at-quota peers '
              'gp3 + gp4 are peaced in ascending sort.',
        );
      },
    );
  });
}
