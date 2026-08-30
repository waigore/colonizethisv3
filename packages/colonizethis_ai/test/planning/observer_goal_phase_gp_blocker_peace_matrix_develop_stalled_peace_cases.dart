// Case tables for observer_goal_phase_gp_blocker_peace_matrix_test.dart
// (Refs #3941). Imported by the support library / contract file.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'observer_goal_phase_gp_blocker_peace_matrix_support.dart';
export 'observer_goal_phase_gp_blocker_peace_matrix_develop_stalled_peace_stalled_cases.dart';

/// Matrix rows for `developPhaseGpPeaceTargets guard branches` (Refs #3941 matrix consolidation).
final List<PeaceCase> kDevelopPhaseGpPeaceTargetsGuardBranchesCases = <PeaceCase>[
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
    ];

