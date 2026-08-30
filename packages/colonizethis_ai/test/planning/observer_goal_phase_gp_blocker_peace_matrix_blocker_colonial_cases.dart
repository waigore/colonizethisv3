// Case tables for observer_goal_phase_gp_blocker_peace_matrix_test.dart
// (Refs #3941). Imported by the contract file.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'observer_goal_phase_gp_blocker_peace_matrix_support.dart';

/// Matrix rows for `primaryColonialGpBlocker contract` (Refs #3941 matrix consolidation).
final List<BlockerCase> kPrimaryColonialGpBlockerContractCases = <BlockerCase>[
      BlockerCase(
        label: 'empty invadable NW → null',
        build: () => (
          gameWithNwProvinces(turnNumber: 110, nwProvinces: const []),
          colonialSnapshot(
            atWarWith: const [gp2, gp3],
            invadableNw: const [],
          ),
        ),
        matcher: isNull,
        reason:
            'No invadable NW provinces means no GP can be the colonial '
            'frontier blocker — the loop body never runs and the function '
            'returns null. A regression that returned an arbitrary at-war GP '
            'as blocker would silently preserve that front when '
            '`colonialPhaseGpPeaceTargets` should peace everyone.',
      ),
      BlockerCase(
        label: 'all invadable NW owned by tribes/minors → null',
        build: () => (
          gameWithNwProvinces(
            turnNumber: 110,
            nwProvinces: const [
              Province(
                id: 'newWorld|t1_a',
                regionId: 'newWorld',
                ownerId: tribe1,
              ),
              Province(
                id: 'newWorld|t2_a',
                regionId: 'newWorld',
                ownerId: tribe2,
              ),
              Province(
                id: 'newWorld|m1_a',
                regionId: 'newWorld',
                ownerId: minor1,
              ),
            ],
          ),
          colonialSnapshot(
            atWarWith: const [gp2, gp3],
            invadableNw: const [
              'newWorld|t1_a',
              'newWorld|t2_a',
              'newWorld|m1_a',
            ],
          ),
        ),
        matcher: isNull,
        reason:
            'Tribes and minor nations are not Great Powers '
            '(`game.playerById` returns null for them) so they are skipped '
            'by the blocker scan. A regression that counted non-GP owners '
            'would falsely identify a tribe as the colonial blocker and '
            'invert the peace preservation set.',
      ),
      BlockerCase(
        label: 'all invadable NW unowned (null owner) → null',
        build: () => (
          gameWithNwProvinces(
            turnNumber: 110,
            nwProvinces: const [
              Province(id: 'newWorld|u_a', regionId: 'newWorld'),
              Province(id: 'newWorld|u_b', regionId: 'newWorld'),
            ],
          ),
          colonialSnapshot(
            atWarWith: const [gp2, gp3],
            invadableNw: const ['newWorld|u_a', 'newWorld|u_b'],
          ),
        ),
        matcher: isNull,
        reason:
            'Unowned NW provinces have null ownerId in the province-owner '
            'map and are skipped by the blocker scan (mirrors the '
            '`getProvinceOwnerMap` contract). A regression that picked the '
            'first iterated province\'s owner unconditionally would crash '
            'or return an empty-string owner here.',
      ),
      BlockerCase(
        label: 'single GP owning all invadable NW → that GP',
        build: () => (
          gameWithNwProvinces(
            turnNumber: 110,
            nwProvinces: const [
              Province(
                id: 'newWorld|gp2_a',
                regionId: 'newWorld',
                ownerId: gp2,
              ),
              Province(
                id: 'newWorld|gp2_b',
                regionId: 'newWorld',
                ownerId: gp2,
              ),
            ],
          ),
          colonialSnapshot(
            atWarWith: const [gp2, gp3],
            invadableNw: const ['newWorld|gp2_a', 'newWorld|gp2_b'],
          ),
        ),
        matcher: gp2,
        reason:
            'When exactly one GP owns every invadable NW province, that GP '
            'is unambiguously the colonial blocker.',
      ),
      BlockerCase(
        label: 'plurality wins among multiple GP owners (2 vs 1)',
        build: () => (
          gameWithNwProvinces(
            turnNumber: 110,
            nwProvinces: const [
              Province(
                id: 'newWorld|gp2_a',
                regionId: 'newWorld',
                ownerId: gp2,
              ),
              Province(
                id: 'newWorld|gp2_b',
                regionId: 'newWorld',
                ownerId: gp2,
              ),
              Province(
                id: 'newWorld|gp3_a',
                regionId: 'newWorld',
                ownerId: gp3,
              ),
            ],
          ),
          colonialSnapshot(
            atWarWith: const [gp2, gp3],
            invadableNw: const [
              'newWorld|gp2_a',
              'newWorld|gp2_b',
              'newWorld|gp3_a',
            ],
          ),
        ),
        matcher: gp2,
        reason:
            'The GP with the largest count of owned invadable NW provinces '
            'is the colonial blocker (strict `>` over running max). A '
            'regression that picked the last encountered GP, the highest '
            'factionId, or any non-plurality owner would shift the '
            'preservation set off the correct frontier.',
      ),
      BlockerCase(
        label: 'mixed GP + tribe ownership: only GP counts contribute',
        // gp3 owns one invadable NW; tribe1 owns two. The plurality scan
        // skips tribe-owned provinces entirely, so gp3 is the blocker even
        // though it does not own the most invadable NW overall.
        build: () => (
          gameWithNwProvinces(
            turnNumber: 110,
            nwProvinces: const [
              Province(
                id: 'newWorld|t1_a',
                regionId: 'newWorld',
                ownerId: tribe1,
              ),
              Province(
                id: 'newWorld|t1_b',
                regionId: 'newWorld',
                ownerId: tribe1,
              ),
              Province(
                id: 'newWorld|gp3_a',
                regionId: 'newWorld',
                ownerId: gp3,
              ),
            ],
          ),
          colonialSnapshot(
            atWarWith: const [gp2, gp3],
            invadableNw: const [
              'newWorld|gp3_a',
              'newWorld|t1_a',
              'newWorld|t1_b',
            ],
          ),
        ),
        matcher: gp3,
        reason:
            'Tribes do not register as GPs in the blocker scan, so a '
            'tribe-owned majority cannot shadow a single-province GP owner. '
            'A regression that counted tribe-owned invadable NW would '
            'falsely return null (since the inner `provinceOwner[pid] == '
            'owner` check would compare tribe owners) and silently disable '
            'colonial blocker preservation.',
      ),
    ];
