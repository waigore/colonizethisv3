// EXPAND-phase GP peace guard-branch case table (Refs #3941).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'observer_goal_phase_gp_blocker_peace_matrix_support.dart';

final List<PeaceCase> kExpandPhaseGpPeaceTargetsGuardEarlyCases = <PeaceCase>[
  PeaceCase(
    label: 'not in EXPAND phase -> empty (DEVELOP fixture)',
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
    label: 'single GP at war with NO uninvaded minor -> empty (length guard)',
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
        'to engage.',
  ),
  PeaceCase(
    label: 'mutual-plateau sole GP war on GP-only cleared frontier -> peace peer',
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
];
