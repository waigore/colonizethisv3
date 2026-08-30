// Case tables for observer_goal_phase_gp_blocker_peace_matrix_test.dart
// (Refs #3941). Imported by the support library / contract file.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'observer_goal_phase_gp_blocker_peace_matrix_support.dart';

/// Matrix rows for `colonialPhaseGpPeaceTargets guard branches` (Refs #3941 matrix consolidation).
final List<PeaceCase> kColonialPhaseGpPeaceTargetsGuardBranchesCases = <PeaceCase>[
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
    ];
