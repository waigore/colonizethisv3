// Table-driven matrix consolidation of the observer-phase peace-target
// guard-branch suites (Refs #3749 branch-pin consolidation).
//
// Part 3 of 3 — DEVELOP + stalled-below-quota peace-target guard ladders.
// The GP-blocker contracts live in
// `observer_goal_phase_gp_blocker_peace_matrix_test.dart`; the COLONIAL +
// EXPAND peace ladders live in
// `observer_goal_phase_gp_blocker_peace_matrix_part2_test.dart`. Shared
// fixture families and the guard-branch runner live in
// `observer_goal_phase_gp_blocker_peace_matrix_support.dart`.
//
// This part folds in two further peace-target guard suites that share the
// same `({required Game game, required AIWorldSnapshot snapshot}) ->
// List<String>` signature, so they reuse the same peace-target case runner
// ([runPeace]):
//
//   - `observer_goal_phase_develop_peace_target_branches_test.dart`
//     (`developPhaseGpPeaceTargets`, DEVELOP phase, GP-vs-GP peace-all
//     rule with no blocker preservation / minor-first short-circuit;
//     Refs #2509 S10).
//   - `expand_phase_planner_stalled_below_quota_gp_lead_branches_test.dart`
//     (`stalledBelowQuotaGpLeadPeaceTargets`, below-quota lead-peace
//     shortcut keyed on `minLeadDeficit` / quota guard / GP-only blocker;
//     Refs #2509).
//
// Coverage is preserved 1:1 — every former `test(...)` becomes one matrix
// row with the same fixture and the verbatim regression `reason`.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'observer_goal_phase_gp_blocker_peace_matrix_support.dart';

void main() {
  // ---------------------------------------------------------------------
  // developPhaseGpPeaceTargets guard branches (DEVELOP phase, GP-vs-GP
  // peace-all rule). No blocker preservation and no minor-first
  // short-circuit (unlike EXPAND / COLONIAL).
  // ---------------------------------------------------------------------
  runPeace(
    'developPhaseGpPeaceTargets guard branches',
    developPhaseGpPeaceTargets,
    <PeaceCase>[
      PeaceCase(
        label: 'not in DEVELOP phase (EXPAND fixture) -> empty',
        // Below OW quota -> EXPAND. EXPAND has its own peace-target
        // helper (`expandPhaseGpPeaceTargets`) with a different rule
        // (minor-first + blocker preservation), so the DEVELOP helper
        // must abstain here. A regression that dropped the phase guard
        // would silently flatten "peace all GPs" onto EXPAND fronts and
        // collapse the SPEC EXPAND minor-first / blocker preservation
        // contract.
        gameBuilder: () => developGame(turnNumber: 50),
        snapshot: const AIWorldSnapshot(
          playerId: gp1,
          threats: ThreatSummary(atWarWith: [gp2, gp3]),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(oldWorldProvincesOwned: 8),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        ),
        expectedPhase: ObserverGoalPhase.expand,
        phaseReason:
            'Fixture must place GP in EXPAND so the DEVELOP helper\'s '
            'early return is the only branch under test.',
        expectedPeace: isEmpty,
        peaceReason:
            'Outside DEVELOP the helper must return the empty list '
            'immediately -- EXPAND has its own peace-target helper '
            'with a minor-first / blocker preservation rule that '
            '`developPhaseGpPeaceTargets` must not pre-empt.',
      ),
      PeaceCase(
        label: 'not in DEVELOP phase (COLONIAL fixture) -> empty',
        // OW at quota plus visible invadable NW -> COLONIAL. COLONIAL
        // preserves the colonial-blocker GP front via
        // `colonialPhaseGpPeaceTargets`. A regression that dropped the
        // phase guard would peace every at-war GP in COLONIAL and
        // collapse the blocker preservation rule.
        gameBuilder: () => developGame(turnNumber: 110),
        snapshot: const AIWorldSnapshot(
          playerId: gp1,
          threats: ThreatSummary(atWarWith: [gp2, gp3]),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
          ),
          colonial: ColonialSummary(
            invadableNewWorldProvinceIdsSorted: ['newWorld|p1'],
          ),
          economy: EconomySummary(),
          relations: {},
        ),
        expectedPhase: ObserverGoalPhase.colonial,
        phaseReason:
            'Fixture must place GP in COLONIAL so the DEVELOP helper\'s '
            'early return is the only branch under test.',
        expectedPeace: isEmpty,
        peaceReason:
            'Outside DEVELOP the helper must return the empty list '
            'immediately -- COLONIAL has its own peace-target helper '
            'with a blocker preservation rule that '
            '`developPhaseGpPeaceTargets` must not pre-empt.',
      ),
      PeaceCase(
        label: 'DEVELOP with empty atWarWith -> empty',
        // DEVELOP phase entry confirmed below; the loop body never runs
        // and the sort on an empty list is a no-op. A regression that
        // returned the at-peace GP roster would generate spurious
        // `offerPeace` orders toward neutral powers.
        gameBuilder: () => developGame(turnNumber: 140),
        snapshot: developSnapshot(atWarWith: const []),
        expectedPhase: ObserverGoalPhase.develop,
        phaseReason: 'Fixture must place GP in DEVELOP.',
        expectedPeace: isEmpty,
        peaceReason:
            'Empty `atWarWith` means there are no live war fronts; '
            'the helper must return empty without iterating the GP '
            'roster.',
      ),
      PeaceCase(
        label: 'DEVELOP with only minors/tribes in atWarWith -> empty',
        // The inline `game.playerById(factionId) != null` filter must
        // drop every non-GP faction. DEVELOP is GP-vs-GP peace only --
        // minor / tribe wars are pursued through other diplomacy paths
        // (war pursuit, embassy chain, purchase_land). A regression
        // that returned tribe / minor ids here would emit `offerPeace`
        // toward non-GP factions and break downstream order
        // validation.
        gameBuilder: () => developGame(
          turnNumber: 140,
          tribes: const [Tribe(id: tribe1, displayName: 'T1')],
          minorNations: const [MinorNation(id: minor1, displayName: 'M1')],
        ),
        snapshot: developSnapshot(atWarWith: const [tribe1, minor1]),
        expectedPhase: ObserverGoalPhase.develop,
        phaseReason: 'Fixture must place GP in DEVELOP.',
        expectedPeace: isEmpty,
        peaceReason:
            'Non-GP factions (tribes / minors) are filtered out of '
            'the peace-target list by `game.playerById` returning '
            'null for non-player ids. With only non-GP wars present, '
            'the helper must return empty.',
      ),
      PeaceCase(
        label: 'DEVELOP with single GP at war -> [that GP]',
        // Unlike EXPAND / COLONIAL, DEVELOP has **no** `gpWars.length
        // <= 1` guard -- a single GP front must be peaced too. A
        // regression that copied the EXPAND / COLONIAL length guard
        // would leave a lone GP war open and starve the
        // improvement-first DEVELOP civilian work (turn-150
        // `--verify-colonial-expansion` 70% extractable-tile
        // improvement gate).
        gameBuilder: () => developGame(turnNumber: 140),
        snapshot: developSnapshot(atWarWith: const [gp2]),
        expectedPhase: ObserverGoalPhase.develop,
        phaseReason: 'Fixture must place GP in DEVELOP.',
        expectedPeace: const [gp2],
        peaceReason:
            'DEVELOP peace rule covers every at-war GP, including a '
            'single GP front. The helper must return a one-element '
            'list, not empty.',
      ),
      PeaceCase(
        label: 'DEVELOP with three GPs at war (unsorted input) -> '
            'ascending sorted',
        // Pins the `..sort()` contract: the helper must return GP
        // fronts in stable ascending `factionId` order so downstream
        // order generation is deterministic for a fixed seed
        // (Must-have #7). Input order shuffled to gp3 / gp4 / gp2 so
        // a regression that dropped the sort (or replaced it with
        // input-order preservation) would surface here.
        gameBuilder: () => developGame(turnNumber: 140),
        snapshot: developSnapshot(atWarWith: const [gp3, gp4, gp2]),
        expectedPhase: ObserverGoalPhase.develop,
        phaseReason: 'Fixture must place GP in DEVELOP.',
        expectedPeace: const [gp2, gp3, gp4],
        peaceReason:
            'All at-war GPs returned in ascending `factionId` order '
            'regardless of `snapshot.threats.atWarWith` order '
            '(Refs #2509 must-have #7 determinism).',
      ),
      PeaceCase(
        label: 'DEVELOP with mixed GP + non-GP atWarWith -> only GPs, sorted',
        // Defensive pin: the filter and the sort must compose so that
        // tribe / minor ids in `atWarWith` are dropped **before** the
        // sort runs. The shuffled input order (gp3, tribe1, gp2,
        // minor1) exercises both the filter (drops tribe1, minor1)
        // and the sort (gp3, gp2 -> gp2, gp3) in one fixture. A
        // regression that sorted first and filtered after would
        // still pass; a regression that left non-GP ids in the
        // output list would break downstream `offerPeace` validation.
        gameBuilder: () => developGame(
          turnNumber: 140,
          tribes: const [Tribe(id: tribe1, displayName: 'T1')],
          minorNations: const [MinorNation(id: minor1, displayName: 'M1')],
        ),
        snapshot: developSnapshot(
          atWarWith: const [gp3, tribe1, gp2, minor1],
        ),
        expectedPhase: ObserverGoalPhase.develop,
        phaseReason: 'Fixture must place GP in DEVELOP.',
        expectedPeace: const [gp2, gp3],
        peaceReason:
            'Non-GP factions in `atWarWith` are filtered out before '
            'the sort, leaving the GP fronts in ascending '
            '`factionId` order.',
      ),
    ],
  );

  group('developPhaseGpPeaceTargets determinism', () {
    test('identical inputs produce identical peace target list', () {
      // Must-have #7 (determinism) at the function-unit level,
      // mirroring the determinism pins in the COLONIAL and EXPAND
      // peace-blocker families above. The mixed-input fixture
      // exercises both the filter and the sort, so repeating the call
      // must yield the same list.
      final game = developGame(
        turnNumber: 140,
        tribes: const [Tribe(id: tribe1, displayName: 'T1')],
        minorNations: const [MinorNation(id: minor1, displayName: 'M1')],
      );
      final snapshot = developSnapshot(
        atWarWith: const [gp3, tribe1, gp2, minor1],
      );
      final first = developPhaseGpPeaceTargets(game: game, snapshot: snapshot);
      final second = developPhaseGpPeaceTargets(game: game, snapshot: snapshot);
      expect(second, first);
    });
  });

  // ---------------------------------------------------------------------
  // stalledBelowQuotaGpLeadPeaceTargets branches (below-quota lead-peace
  // shortcut). Quota guard, `minLeadDeficit` table, GP-only invadable
  // blocker exclusion, and collection guards.
  // ---------------------------------------------------------------------
  runPeace(
    'stalledBelowQuotaGpLeadPeaceTargets branches',
    stalledBelowQuotaGpLeadPeaceTargets,
    <PeaceCase>[
      PeaceCase(
        label: 'quota guard: empty at the observer OW quota even when '
            'enemy leads by 3+',
        gameBuilder: () => ownVsPartnerGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp,
          partnerProvinces: kObserverConquestMinOwProvincesPerGp + 3,
          partnerId: 'gp_enemy',
        ),
        snapshot: ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
          atWarWith: const ['gp_enemy'],
        ),
        expectedPeace: isEmpty,
        peaceReason:
            'At kObserverConquestMinOwProvincesPerGp the below-quota lead-peace '
            'shortcut must not run (COLONIAL/DEVELOP paths own mop-up).',
      ),
      PeaceCase(
        label: 'minLeadDeficit: default-start empty when enemy leads by '
            'only 1 (needs 2)',
        gameBuilder: () => ownVsPartnerGame(
          ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
          partnerProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 1,
          partnerId: 'gp_enemy',
          invadableOwnerId: 'minor1',
        ),
        snapshot: ownSnapshot(
          oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
          atWarWith: const ['gp_enemy'],
          invadableProvinceIdsSorted: const ['oldWorld|frontier'],
        ),
        expectedPeace: isEmpty,
        peaceReason:
            'own <= kObserverDefaultStartOldWorldProvincesPerGp uses '
            'minLeadDeficit=kUnwinnableSoleGpMinProvinceDeficit (2). '
            'Lead 1 must not peace.',
      ),
      PeaceCase(
        label: 'minLeadDeficit: default-start returns enemy when lead is '
            'exactly 2',
        gameBuilder: () => ownVsPartnerGame(
          ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
          partnerProvinces: kObserverDefaultStartOldWorldProvincesPerGp +
              kUnwinnableSoleGpMinProvinceDeficit,
          partnerId: 'gp_enemy',
          invadableOwnerId: 'minor1',
        ),
        snapshot: ownSnapshot(
          oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
          atWarWith: const ['gp_enemy'],
          invadableProvinceIdsSorted: const ['oldWorld|frontier'],
        ),
        expectedPeace: const ['gp_enemy'],
      ),
      PeaceCase(
        label: 'minLeadDeficit: post-default empty when enemy ties OW '
            'count (needs 1)',
        gameBuilder: () => ownVsPartnerGame(
          ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 1,
          partnerProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 1,
          partnerId: 'gp_enemy',
        ),
        snapshot: ownSnapshot(
          oldWorldProvincesOwned:
              kObserverDefaultStartOldWorldProvincesPerGp + 1,
          atWarWith: const ['gp_enemy'],
          invadableProvinceIdsSorted: const ['oldWorld|inv1'],
        ),
        expectedPeace: isEmpty,
        peaceReason:
            'When own > kObserverDefaultStartOldWorldProvincesPerGp the '
            'minLeadDeficit row is 1; enemyOw == own must not peace.',
      ),
      PeaceCase(
        label: 'minLeadDeficit: post-default returns enemy when lead is '
            'exactly 1',
        gameBuilder: () => ownVsPartnerGame(
          ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 1,
          partnerProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 2,
          partnerId: 'gp_enemy',
        ),
        snapshot: ownSnapshot(
          oldWorldProvincesOwned:
              kObserverDefaultStartOldWorldProvincesPerGp + 1,
          atWarWith: const ['gp_enemy'],
          invadableProvinceIdsSorted: const ['oldWorld|inv1'],
        ),
        expectedPeace: const ['gp_enemy'],
      ),
      PeaceCase(
        label: 'GP-only blocker: skips invadable blocker but keeps '
            'non-blocker GP with sufficient lead',
        gameBuilder: () => ownVsPartnerGame(
          ownProvinces: 8,
          partnerProvinces: 9,
          partnerId: 'gp_blocker',
          extraGpId: 'gp_enemy',
          extraGpProvinces: 11,
          invadableOwnerId: 'gp_blocker',
        ),
        snapshot: ownSnapshot(
          oldWorldProvincesOwned: 8,
          atWarWith: const ['gp_blocker', 'gp_enemy'],
          invadableProvinceIdsSorted: const ['oldWorld|frontier'],
        ),
        expectedPeace: const ['gp_enemy'],
        peaceReason:
            'On a GP-only frontier the invadable blocker is excluded even '
            'when it leads; a second GP that meets minLeadDeficit=1 must still '
            'be peaced.',
      ),
      PeaceCase(
        label: 'GP-only blocker: empty when sole at-war GP is the '
            'invadable blocker with lead 1',
        gameBuilder: () => ownVsPartnerGame(
          ownProvinces: 8,
          partnerProvinces: 9,
          partnerId: 'gp_blocker',
          invadableOwnerId: 'gp_blocker',
        ),
        snapshot: ownSnapshot(
          oldWorldProvincesOwned: 8,
          atWarWith: const ['gp_blocker'],
          invadableProvinceIdsSorted: const ['oldWorld|frontier'],
        ),
        expectedPeace: isEmpty,
      ),
      PeaceCase(
        label: 'collection guard: skips minors in atWarWith',
        gameBuilder: () => ownVsPartnerGame(
          ownProvinces: 8,
          partnerProvinces: 12,
          partnerId: 'gp_enemy',
          minorId: 'minor1',
          atWarWithMinor: true,
        ),
        snapshot: ownSnapshot(
          oldWorldProvincesOwned: 8,
          atWarWith: const ['gp_enemy', 'minor1'],
          invadableProvinceIdsSorted: const ['oldWorld|inv1'],
        ),
        expectedPeace: const ['gp_enemy'],
      ),
      PeaceCase(
        label: 'collection guard: returns sorted GP targets that each '
            'meet the deficit',
        gameBuilder: () => ownVsPartnerGame(
          ownProvinces: 6,
          partnerProvinces: 8,
          partnerId: 'gp_b',
          extraGpId: 'gp_a',
          extraGpProvinces: 9,
        ),
        snapshot: ownSnapshot(
          oldWorldProvincesOwned: 6,
          atWarWith: const ['gp_a', 'gp_b'],
          invadableProvinceIdsSorted: const ['oldWorld|inv1'],
        ),
        expectedPeace: const ['gp_a', 'gp_b'],
        peaceReason:
            'Default-start minLeadDeficit=2: gp_b at +2 qualifies; gp_a at +3 '
            'qualifies; result must be sorted.',
      ),
      PeaceCase(
        label: 'collection guard: omits GP that leads by less than '
            'minLeadDeficit',
        gameBuilder: () => ownVsPartnerGame(
          ownProvinces: 8,
          partnerProvinces: 8,
          partnerId: 'gp_weak',
          extraGpId: 'gp_strong',
          extraGpProvinces: 10,
        ),
        snapshot: ownSnapshot(
          oldWorldProvincesOwned: 8,
          atWarWith: const ['gp_weak', 'gp_strong'],
          invadableProvinceIdsSorted: const ['oldWorld|inv1'],
        ),
        expectedPeace: const ['gp_strong'],
      ),
    ],
  );
}
