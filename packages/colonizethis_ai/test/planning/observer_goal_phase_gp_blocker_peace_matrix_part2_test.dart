// Table-driven matrix consolidation of the observer-phase peace-target
// guard-branch suites (Refs #3749 branch-pin consolidation).
//
// Part 2 of 3 — COLONIAL + EXPAND peace-target guard ladders, including the
// EXPAND-unique minor-first and mutual-plateau arms. The GP-blocker
// contracts live in `observer_goal_phase_gp_blocker_peace_matrix_test.dart`;
// the DEVELOP + stalled-below-quota peace ladders live in
// `observer_goal_phase_gp_blocker_peace_matrix_part3_test.dart`. Shared
// fixture families and the guard-branch runner live in
// `observer_goal_phase_gp_blocker_peace_matrix_support.dart`.
//
// This part replaces the peace-target halves of two former per-phase
// `*_branches_test.dart` suites:
//
//   - `observer_goal_phase_colonial_peace_blocker_branches_test.dart`
//     (`colonialPhaseGpPeaceTargets`, COLONIAL phase, NEW-WORLD invadable
//     frontier; Refs #2509 S10, PR #2661).
//   - `observer_goal_phase_expand_peace_blocker_branches_test.dart`
//     (`expandPhaseGpPeaceTargets`, EXPAND phase, OLD-WORLD invadable
//     frontier; Refs #2509 S10).
//
// Both functions share the `({required Game game, required AIWorldSnapshot
// snapshot}) -> List<String>` signature, so the two peace-target guard
// ladders collapse into one shared case runner ([runPeace]). Coverage is
// preserved 1:1 — every former `test(...)` becomes one matrix row with the
// same fixture and the verbatim regression `reason`.
//
//   SPEC/ai/ai-architecture.md § Observer goal phases (Full AI):
//     COLONIAL — "offerPeace toward at-war Great Powers that do not own
//     the primary colonial NW frontier blocker when fighting two or more
//     GPs"; EXPAND — "Hold blocker war ... peace the non-blocker GP
//     front(s)" / "When at war with two or more GPs: peace all
//     non-blocker GP fronts" plus the minor-first rule "exit every GP
//     front while uninvaded minors remain".

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'observer_goal_phase_gp_blocker_peace_matrix_support.dart';

void main() {
  // ---------------------------------------------------------------------
  // colonialPhaseGpPeaceTargets guard branches (COLONIAL / NW frontier).
  // ---------------------------------------------------------------------
  runPeace(
    'colonialPhaseGpPeaceTargets guard branches',
    colonialPhaseGpPeaceTargets,
    <PeaceCase>[
      PeaceCase(
        label: 'not in COLONIAL phase → empty (EXPAND fixture)',
        // OW = 7, well below quota → EXPAND.
        gameBuilder: () => gameWithNwProvinces(
          turnNumber: 50,
          nwProvinces: const [
            Province(id: 'newWorld|gp2_a', regionId: 'newWorld', ownerId: gp2),
          ],
        ),
        snapshot: const AIWorldSnapshot(
          playerId: gp1,
          threats: ThreatSummary(atWarWith: [gp2, gp3]),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(oldWorldProvincesOwned: 7),
          colonial: ColonialSummary(
            invadableNewWorldProvinceIdsSorted: ['newWorld|gp2_a'],
            adjacentNewWorldOwnerFactionIdsSorted: [gp2],
          ),
          economy: EconomySummary(),
          relations: {},
        ),
        expectedPhase: ObserverGoalPhase.expand,
        phaseReason:
            'Fixture must place the GP in EXPAND so the COLONIAL peace '
            'helper\'s early return is the only branch under test.',
        expectedPeace: isEmpty,
        peaceReason:
            'Outside COLONIAL the helper must return the empty list '
            'immediately — EXPAND and DEVELOP have their own peace-target '
            'helpers and their own SPEC rules.',
      ),
      PeaceCase(
        label: 'empty gpWars → empty',
        // COLONIAL phase, but `atWarWith` empty.
        gameBuilder: () => gameWithNwProvinces(
          turnNumber: 110,
          nwProvinces: const [
            Province(id: 'newWorld|gp2_a', regionId: 'newWorld', ownerId: gp2),
          ],
        ),
        snapshot: colonialSnapshot(
          atWarWith: const [],
          invadableNw: const ['newWorld|gp2_a'],
        ),
        expectedPhase: ObserverGoalPhase.colonial,
        phaseReason: 'Fixture must place GP in COLONIAL.',
        expectedPeace: isEmpty,
        peaceReason:
            'Empty `gpWars` short-circuits the `length <= 1` guard. A '
            'regression that always returned the empty `gpWars` list would '
            'still pass this test, but a regression that crashed on empty '
            'input or returned an arbitrary stub would not.',
      ),
      PeaceCase(
        label: 'single GP at war → empty (length <= 1 guard)',
        // SPEC: "when fighting two or more GPs". A one-GP war must keep the
        // front open for the regular war-pursuit path, not silently peace
        // it via the blocker-preservation rule.
        gameBuilder: () => gameWithNwProvinces(
          turnNumber: 110,
          nwProvinces: const [
            Province(id: 'newWorld|gp2_a', regionId: 'newWorld', ownerId: gp2),
          ],
        ),
        snapshot: colonialSnapshot(
          atWarWith: const [gp2],
          invadableNw: const ['newWorld|gp2_a'],
        ),
        expectedPhase: ObserverGoalPhase.colonial,
        expectedPeace: isEmpty,
        peaceReason:
            'A single-GP war is below the SPEC two-or-more-GPs trigger. The '
            'blocker-preservation rule must not engage here; the lone front '
            'is kept open by returning the empty peace-target list.',
      ),
      PeaceCase(
        label: 'single GP at war which is the blocker → still empty '
            '(length guard)',
        // Confirms the order of guard checks: `gpWars.length <= 1` runs
        // before the blocker computation, so a single-GP war never reaches
        // the blocker-membership branch.
        gameBuilder: () => gameWithNwProvinces(
          turnNumber: 110,
          nwProvinces: const [
            Province(id: 'newWorld|gp2_a', regionId: 'newWorld', ownerId: gp2),
          ],
        ),
        snapshot: colonialSnapshot(
          atWarWith: const [gp2],
          invadableNw: const ['newWorld|gp2_a'],
        ),
        blockerFn: primaryColonialGpBlocker,
        blockerExpected: gp2,
        blockerReason:
            'Sanity check: the blocker resolves to the only at-war GP. '
            'Despite that, the helper must still return empty due to the '
            '`gpWars.length <= 1` guard.',
        expectedPeace: isEmpty,
      ),
      PeaceCase(
        label: 'two GPs at war but no GP-owned blocker → empty',
        // 2 GPs at war, but all invadable NW are tribe-owned, so
        // `primaryColonialGpBlocker` is null.
        gameBuilder: () => gameWithNwProvinces(
          turnNumber: 110,
          nwProvinces: const [
            Province(id: 'newWorld|t1_a', regionId: 'newWorld', ownerId: tribe1),
          ],
        ),
        snapshot: colonialSnapshot(
          atWarWith: const [gp2, gp3],
          invadableNw: const ['newWorld|t1_a'],
          adjacentNw: const [tribe1],
        ),
        expectedPhase: ObserverGoalPhase.colonial,
        blockerFn: primaryColonialGpBlocker,
        blockerExpected: isNull,
        blockerReason:
            'Sanity check: only a tribe owns invadable NW, so no GP '
            'qualifies as the colonial blocker.',
        expectedPeace: isEmpty,
        peaceReason:
            'Without a GP blocker the rule has no front to preserve. A '
            'regression that returned all `gpWars` as peace targets would '
            'silently peace both GPs and remove any pressure on rival '
            'colonial powers when the only acquisition target is tribal.',
      ),
      PeaceCase(
        label: 'blocker exists but is not among gpWars → empty',
        // gp4 owns the invadable NW (blocker = gp4) but the GP is at war
        // with gp2 and gp3 only.
        gameBuilder: () => gameWithNwProvinces(
          turnNumber: 110,
          nwProvinces: const [
            Province(id: 'newWorld|gp4_a', regionId: 'newWorld', ownerId: gp4),
          ],
        ),
        snapshot: colonialSnapshot(
          atWarWith: const [gp2, gp3],
          invadableNw: const ['newWorld|gp4_a'],
          adjacentNw: const [gp4],
        ),
        expectedPhase: ObserverGoalPhase.colonial,
        blockerFn: primaryColonialGpBlocker,
        blockerExpected: gp4,
        blockerReason:
            'Sanity check: the only GP owning an invadable NW province is '
            'gp4, so it is the colonial blocker.',
        expectedPeace: isEmpty,
        peaceReason:
            'When the blocker is not actually at war with the planning GP, '
            'no peace is suggested by this helper — the SPEC rule '
            'preserves "Great Powers that do not own the primary colonial '
            'NW frontier blocker" only when that blocker is itself an '
            'active war front.',
      ),
      PeaceCase(
        label: 'three GPs at war with one blocker → other two sorted '
            'ascending',
        // Pins the deterministic ordering for the multi-GP-at-war happy
        // path. gp2 is the blocker; gp3 and gp4 are non-blockers and must
        // appear in stable ascending factionId order.
        gameBuilder: () => gameWithNwProvinces(
          turnNumber: 110,
          nwProvinces: const [
            Province(id: 'newWorld|gp2_a', regionId: 'newWorld', ownerId: gp2),
          ],
        ),
        // Provide war list out of sorted order to exercise the sort.
        snapshot: colonialSnapshot(
          atWarWith: const [gp4, gp2, gp3],
          invadableNw: const ['newWorld|gp2_a'],
          adjacentNw: const [gp2],
        ),
        expectedPhase: ObserverGoalPhase.colonial,
        blockerFn: primaryColonialGpBlocker,
        blockerExpected: gp2,
        expectedPeace: const [gp3, gp4],
        peaceReason:
            'Non-blocker GPs must be returned in stable ascending '
            'factionId order so downstream order generation is '
            'deterministic for a fixed seed (Must-have #7).',
      ),
    ],
  );

  // ---------------------------------------------------------------------
  // expandPhaseGpPeaceTargets guard branches (EXPAND / OW frontier).
  // Includes the EXPAND-unique minor-first and mutual-plateau arms.
  // ---------------------------------------------------------------------
  runPeace(
    'expandPhaseGpPeaceTargets guard branches',
    expandPhaseGpPeaceTargets,
    <PeaceCase>[
      PeaceCase(
        label: 'not in EXPAND phase -> empty (DEVELOP fixture)',
        // OW = quota, no colonial targets -> DEVELOP.
        gameBuilder: () => gameWithOwProvinces(
          turnNumber: 110,
          owProvinces: const [
            Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: gp2),
          ],
        ),
        snapshot: const AIWorldSnapshot(
          playerId: gp1,
          threats: ThreatSummary(atWarWith: [gp2, gp3]),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
            invadableProvinceIdsSorted: ['oldWorld|gp2_a'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        ),
        expectedPhase: ObserverGoalPhase.develop,
        phaseReason:
            'Fixture must place the GP in DEVELOP so the EXPAND peace '
            'helper\'s early return is the only branch under test.',
        expectedPeace: isEmpty,
        peaceReason:
            'Outside EXPAND the helper must return the empty list '
            'immediately -- COLONIAL and DEVELOP have their own '
            'peace-target helpers and their own SPEC rules.',
      ),
      PeaceCase(
        label: 'empty gpWars -> empty',
        // EXPAND phase, but `atWarWith` empty.
        gameBuilder: () => gameWithOwProvinces(
          turnNumber: 50,
          owProvinces: const [
            Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: gp2),
          ],
        ),
        snapshot: expandSnapshot(
          atWarWith: const [],
          invadableOw: const ['oldWorld|gp2_a'],
        ),
        expectedPhase: ObserverGoalPhase.expand,
        phaseReason: 'Fixture must place GP in EXPAND.',
        expectedPeace: isEmpty,
        peaceReason:
            'Empty `gpWars` short-circuits both the minor-first branch '
            '(which requires `gpWars.isNotEmpty`) and the `length <= 1` '
            'guard, returning empty without invoking the blocker scan.',
      ),
      PeaceCase(
        label: 'single GP at war with NO uninvaded minor -> empty '
            '(length guard)',
        // SPEC: "When at war with two or more GPs: peace all non-blocker
        // GP fronts". A one-GP war must keep the front open for the
        // regular war-pursuit path. With no uninvaded minor on the map the
        // minor-first branch is also skipped, so the length guard is the
        // sole gate.
        gameBuilder: () => gameWithOwProvinces(
          turnNumber: 50,
          owProvinces: const [
            Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: gp2),
          ],
        ),
        snapshot: expandSnapshot(
          atWarWith: const [gp2],
          invadableOw: const ['oldWorld|gp2_a'],
        ),
        expectedPhase: ObserverGoalPhase.expand,
        expectedPeace: isEmpty,
        peaceReason:
            'A single-GP war is below the SPEC two-or-more-GPs trigger '
            'and there is no uninvaded minor for the minor-first branch '
            'to engage. The blocker-preservation rule must not engage '
            'here; the lone front is kept open by returning the empty '
            'peace-target list.',
      ),
      PeaceCase(
        label: 'mutual-plateau sole GP war on GP-only cleared frontier -> '
            'peace peer',
        gameBuilder: () => gameWithOwProvinces(
          turnNumber: 90,
          owProvinces: [
            for (var i = 0; i < 8; i++)
              Province(
                id: 'oldWorld|gp3_$i',
                regionId: 'oldWorld',
                ownerId: 'gp3',
              ),
            for (var i = 0; i < 9; i++)
              Province(
                id: 'oldWorld|gp4_$i',
                regionId: 'oldWorld',
                ownerId: 'gp4',
              ),
          ],
          players: const [
            Player(id: 'gp3', displayName: 'P3', isHuman: false),
            Player(id: 'gp4', displayName: 'P4', isHuman: false),
          ],
        ).copyWith(
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp3',
              factionId2: 'gp4',
              state: RelationState.atWar,
              score: 30,
            ),
          ],
        ),
        snapshot: expandSnapshot(
          playerId: 'gp3',
          atWarWith: const ['gp4'],
          invadableOw: const ['oldWorld|gp4_0'],
          oldWorldProvincesOwned: 8,
        ),
        expectedPeace: const ['gp4'],
        peaceReason:
            'Seed-42 gp3/gp4 plateau: when minors are cleared and the sole '
            'GP front is the mutual-plateau blocker, EXPAND must offer peace '
            'so rebuild/minor pivots can resume (Refs #2509).',
      ),
      PeaceCase(
        label: 'minor-first does not engage when the only uninvaded minor '
            'is already at war',
        // The minor-first branch requires `hasUninvadedOldWorldMinor`,
        // which excludes minors that are themselves in `atWarWith`. So a
        // minor that is "the only minor on the map" but currently at war
        // cannot trigger the rule. With a single GP at war and no other
        // minors, the helper must fall through to the `gpWars.length <= 1`
        // guard and return empty.
        gameBuilder: () => gameWithOwProvinces(
          turnNumber: 50,
          owProvinces: const [
            Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: minor1),
          ],
          minorNations: const [MinorNation(id: minor1, displayName: 'M1')],
        ),
        snapshot: expandSnapshot(
          atWarWith: const [gp2, minor1],
          invadableOw: const ['oldWorld|m1_a'],
        ),
        expectedPhase: ObserverGoalPhase.expand,
        expectedPeace: isEmpty,
        peaceReason:
            'A minor already in `atWarWith` is not "uninvaded", so the '
            'minor-first branch does not engage. With only one GP in '
            'the filtered `gpWars` list and no remaining uninvaded '
            'minor, the helper returns empty via the `length <= 1` '
            'guard. A regression that counted at-war minors as '
            'uninvaded would peace the lone GP and undermine the '
            'EXPAND quota push.',
      ),
      PeaceCase(
        label: 'two GPs at war but no GP-owned blocker -> empty '
            '(null blocker)',
        // 2 GPs at war, but all invadable OW are minor-owned, so
        // `primaryInvadableOldWorldGpBlocker` is null. With no uninvaded
        // (non-at-war) minor on the map the minor-first branch is also
        // skipped, and the null-blocker guard returns empty rather than
        // picking an arbitrary non-blocker GP.
        gameBuilder: () => gameWithOwProvinces(
          turnNumber: 50,
          owProvinces: const [
            Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: minor1),
          ],
          minorNations: const [MinorNation(id: minor1, displayName: 'M1')],
        ),
        snapshot: expandSnapshot(
          atWarWith: const [gp2, gp3, minor1],
          invadableOw: const ['oldWorld|m1_a'],
        ),
        expectedPhase: ObserverGoalPhase.expand,
        blockerFn: primaryInvadableOldWorldGpBlocker,
        blockerExpected: isNull,
        blockerReason:
            'Sanity check: only a minor owns invadable OW, so no GP '
            'qualifies as the OW blocker.',
        expectedPeace: isEmpty,
        peaceReason:
            'Without a GP blocker the rule has no front to preserve. '
            'A regression that returned all `gpWars` as peace targets '
            'would silently peace both GPs and remove pressure on '
            'rival OW powers when the only invadable target is a '
            'minor (regular war-pursuit still handles the minor).',
      ),
      PeaceCase(
        label: 'blocker exists but is not among gpWars -> empty',
        // gp4 owns the invadable OW (blocker = gp4) but the GP is at war
        // with gp2 and gp3 only.
        gameBuilder: () => gameWithOwProvinces(
          turnNumber: 50,
          owProvinces: const [
            Province(id: 'oldWorld|gp4_a', regionId: 'oldWorld', ownerId: gp4),
          ],
        ),
        snapshot: expandSnapshot(
          atWarWith: const [gp2, gp3],
          invadableOw: const ['oldWorld|gp4_a'],
        ),
        expectedPhase: ObserverGoalPhase.expand,
        blockerFn: primaryInvadableOldWorldGpBlocker,
        blockerExpected: gp4,
        blockerReason:
            'Sanity check: the only GP owning an invadable OW province is '
            'gp4, so it is the OW blocker.',
        expectedPeace: isEmpty,
        peaceReason:
            'When the blocker is not actually at war with the planning '
            'GP, no peace is suggested by this helper -- the SPEC rule '
            'preserves "Great Powers that do not own the primary '
            'invadable OW frontier blocker" only when that blocker is '
            'itself an active war front.',
      ),
      PeaceCase(
        label: 'minor-first peaces every GP front while a second uninvaded '
            'minor remains and `atWarWith` includes a non-GP faction',
        // Defensive pin for the `gpWars` filter that runs before
        // minor-first: `atWarWith` includes a tribe id, which must be
        // dropped (it is not a player). With two GPs and one tribe in
        // `atWarWith`, plus an uninvaded minor still holding territory,
        // the helper must peace both GPs in ascending factionId order.
        gameBuilder: () => gameWithOwProvinces(
          turnNumber: 50,
          owProvinces: const [
            Province(id: 'oldWorld|m2_a', regionId: 'oldWorld', ownerId: minor2),
            Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: gp2),
          ],
          minorNations: const [MinorNation(id: minor2, displayName: 'M2')],
        ),
        // Provide war list out of sorted order to exercise the sort.
        snapshot: expandSnapshot(
          atWarWith: const [gp3, tribe1, gp2],
          invadableOw: const ['oldWorld|gp2_a'],
        ),
        expectedPhase: ObserverGoalPhase.expand,
        expectedPeace: const [gp2, gp3],
        peaceReason:
            'Minor-first peaces every GP front in stable ascending '
            'factionId order; non-GP factions in `atWarWith` must be '
            'filtered out of `gpWars` first (Refs #2509 must-have #7 '
            'determinism + EXPAND minor-first rule).',
      ),
      PeaceCase(
        label: 'three GPs at war with one blocker (no uninvaded minor) -> '
            'other two sorted ascending',
        // Pins the deterministic ordering for the multi-GP-at-war happy
        // path with no minor-first short-circuit. gp2 is the blocker;
        // gp3 and gp4 are non-blockers and must appear in stable
        // ascending factionId order.
        gameBuilder: () => gameWithOwProvinces(
          turnNumber: 50,
          owProvinces: const [
            Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: gp2),
          ],
        ),
        // Provide war list out of sorted order to exercise the sort.
        snapshot: expandSnapshot(
          atWarWith: const [gp4, gp2, gp3],
          invadableOw: const ['oldWorld|gp2_a'],
        ),
        expectedPhase: ObserverGoalPhase.expand,
        blockerFn: primaryInvadableOldWorldGpBlocker,
        blockerExpected: gp2,
        expectedPeace: const [gp3, gp4],
        peaceReason:
            'Non-blocker GPs must be returned in stable ascending '
            'factionId order so downstream order generation is '
            'deterministic for a fixed seed (Must-have #7).',
      ),
    ],
  );

  group('expandPhaseGpPeaceTargets determinism', () {
    test('identical inputs produce identical peace target list', () {
      // Must-have #7 (determinism) for the helper itself, mirroring the
      // `primaryInvadableOldWorldGpBlocker` determinism pin above. The
      // 3-GP-at-war fixture exercises both the blocker scan and the sort,
      // so repeating the call must yield the same list.
      final game = gameWithOwProvinces(
        turnNumber: 50,
        owProvinces: const [
          Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: gp2),
        ],
      );
      final snapshot = expandSnapshot(
        atWarWith: const [gp4, gp2, gp3],
        invadableOw: const ['oldWorld|gp2_a'],
      );
      final first = expandPhaseGpPeaceTargets(game: game, snapshot: snapshot);
      final second = expandPhaseGpPeaceTargets(game: game, snapshot: snapshot);
      expect(second, first);
    });
  });
}
