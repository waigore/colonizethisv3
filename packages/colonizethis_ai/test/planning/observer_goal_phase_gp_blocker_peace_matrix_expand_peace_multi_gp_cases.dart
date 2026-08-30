// EXPAND-phase GP peace multi-front case table (Refs #3941).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'observer_goal_phase_gp_blocker_peace_matrix_support.dart';

final List<PeaceCase> kExpandPhaseGpPeaceTargetsMultiGpCases = <PeaceCase>[
  PeaceCase(
    label: 'minor-first does not engage when the only uninvaded minor '
        'is already at war',
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
        'minor-first branch does not engage.',
  ),
  PeaceCase(
    label: 'two GPs at war but no GP-owned blocker -> empty (null blocker)',
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
        'Without a GP blocker the rule has no front to preserve.',
  ),
  PeaceCase(
    label: 'blocker exists but is not among gpWars -> empty',
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
        'GP, no peace is suggested by this helper.',
  ),
  PeaceCase(
    label: 'minor-first peaces every GP front while a second uninvaded '
        'minor remains and `atWarWith` includes a non-GP faction',
    gameBuilder: () => gameWithOwProvinces(
      turnNumber: 50,
      owProvinces: const [
        Province(id: 'oldWorld|m2_a', regionId: 'oldWorld', ownerId: minor2),
        Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: gp2),
      ],
      minorNations: const [MinorNation(id: minor2, displayName: 'M2')],
    ),
    snapshot: expandSnapshot(
      atWarWith: const [gp3, tribe1, gp2],
      invadableOw: const ['oldWorld|gp2_a'],
    ),
    expectedPhase: ObserverGoalPhase.expand,
    expectedPeace: const [gp2, gp3],
    peaceReason:
        'Minor-first peaces every GP front in stable ascending '
        'factionId order; non-GP factions in `atWarWith` must be '
        'filtered out of `gpWars` first.',
  ),
  PeaceCase(
    label: 'three GPs at war with one blocker (no uninvaded minor) -> '
        'other two sorted ascending',
    gameBuilder: () => gameWithOwProvinces(
      turnNumber: 50,
      owProvinces: const [
        Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: gp2),
      ],
    ),
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
];
