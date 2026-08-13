// OW matrix rows for observer_goal_phase_gp_blocker_peace_matrix_test.dart
// (Refs #3941 / #4365 Slice B split).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'observer_goal_phase_gp_blocker_peace_matrix_support.dart';

/// Matrix rows for `primaryInvadableOldWorldGpBlocker contract` (Refs #3941 matrix consolidation).
final List<BlockerCase> kPrimaryInvadableOldWorldGpBlockerContractCases = <BlockerCase>[
      BlockerCase(
        label: 'empty invadable OW -> null',
        build: () => (
          gameWithOwProvinces(turnNumber: 50, owProvinces: const []),
          expandSnapshot(
            atWarWith: const [gp2, gp3],
            invadableOw: const [],
          ),
        ),
        matcher: isNull,
        reason:
            'No invadable OW provinces means no GP can be the OW frontier '
            'blocker -- the loop body never runs and the function returns '
            'null. A regression that returned an arbitrary at-war GP as '
            'blocker would silently preserve that front when '
            '`expandPhaseGpPeaceTargets` should peace all non-blockers (or '
            'fall through to a different rule when no blocker exists).',
      ),
      BlockerCase(
        label: 'all invadable OW owned by tribes/minors -> null',
        build: () => (
          gameWithOwProvinces(
            turnNumber: 50,
            owProvinces: const [
              Province(
                id: 'oldWorld|t1_a',
                regionId: 'oldWorld',
                ownerId: tribe1,
              ),
              Province(
                id: 'oldWorld|t2_a',
                regionId: 'oldWorld',
                ownerId: tribe2,
              ),
              Province(
                id: 'oldWorld|m1_a',
                regionId: 'oldWorld',
                ownerId: minor1,
              ),
            ],
            minorNations: const [MinorNation(id: minor1, displayName: 'M1')],
          ),
          expandSnapshot(
            atWarWith: const [gp2, gp3],
            invadableOw: const [
              'oldWorld|t1_a',
              'oldWorld|t2_a',
              'oldWorld|m1_a',
            ],
          ),
        ),
        matcher: isNull,
        reason:
            'Tribes and minor nations are not Great Powers '
            '(`game.playerById` returns null for them) so they are skipped '
            'by the blocker scan. A regression that counted non-GP owners '
            'would falsely identify a tribe / minor as the OW blocker and '
            'invert the EXPAND peace preservation set.',
      ),
      BlockerCase(
        label: 'all invadable OW unowned (null owner) -> null',
        build: () => (
          gameWithOwProvinces(
            turnNumber: 50,
            owProvinces: const [
              Province(id: 'oldWorld|u_a', regionId: 'oldWorld'),
              Province(id: 'oldWorld|u_b', regionId: 'oldWorld'),
            ],
          ),
          expandSnapshot(
            atWarWith: const [gp2, gp3],
            invadableOw: const ['oldWorld|u_a', 'oldWorld|u_b'],
          ),
        ),
        matcher: isNull,
        reason:
            'Unowned OW provinces have null ownerId in the province-owner '
            'map and are skipped by the blocker scan (mirrors the '
            '`getProvinceOwnerMap` contract). A regression that picked the '
            'first iterated province\'s owner unconditionally would crash '
            'or return an empty-string owner here.',
      ),
      BlockerCase(
        label: 'single GP owning all invadable OW -> that GP',
        build: () => (
          gameWithOwProvinces(
            turnNumber: 50,
            owProvinces: const [
              Province(
                id: 'oldWorld|gp2_a',
                regionId: 'oldWorld',
                ownerId: gp2,
              ),
              Province(
                id: 'oldWorld|gp2_b',
                regionId: 'oldWorld',
                ownerId: gp2,
              ),
            ],
          ),
          expandSnapshot(
            atWarWith: const [gp2, gp3],
            invadableOw: const ['oldWorld|gp2_a', 'oldWorld|gp2_b'],
          ),
        ),
        matcher: gp2,
        reason:
            'When exactly one GP owns every invadable OW province, that GP '
            'is unambiguously the OW frontier blocker.',
      ),
      BlockerCase(
        label: 'plurality wins among multiple GP owners (2 vs 1)',
        build: () => (
          gameWithOwProvinces(
            turnNumber: 50,
            owProvinces: const [
              Province(
                id: 'oldWorld|gp2_a',
                regionId: 'oldWorld',
                ownerId: gp2,
              ),
              Province(
                id: 'oldWorld|gp2_b',
                regionId: 'oldWorld',
                ownerId: gp2,
              ),
              Province(
                id: 'oldWorld|gp3_a',
                regionId: 'oldWorld',
                ownerId: gp3,
              ),
            ],
          ),
          expandSnapshot(
            atWarWith: const [gp2, gp3],
            invadableOw: const [
              'oldWorld|gp2_a',
              'oldWorld|gp2_b',
              'oldWorld|gp3_a',
            ],
          ),
        ),
        matcher: gp2,
        reason:
            'The GP with the largest count of owned invadable OW provinces '
            'is the OW frontier blocker (strict `>` over running max). A '
            'regression that picked the last encountered GP, the highest '
            'factionId, or any non-plurality owner would shift the '
            'preservation set off the correct frontier.',
      ),
      BlockerCase(
        label: 'mixed GP + minor ownership: only GP counts contribute',
        // gp3 owns one invadable OW; minor1 owns two. The plurality scan
        // skips minor-owned provinces entirely, so gp3 is the blocker even
        // though it does not own the most invadable OW overall.
        build: () => (
          gameWithOwProvinces(
            turnNumber: 50,
            owProvinces: const [
              Province(
                id: 'oldWorld|m1_a',
                regionId: 'oldWorld',
                ownerId: minor1,
              ),
              Province(
                id: 'oldWorld|m1_b',
                regionId: 'oldWorld',
                ownerId: minor1,
              ),
              Province(
                id: 'oldWorld|gp3_a',
                regionId: 'oldWorld',
                ownerId: gp3,
              ),
            ],
            minorNations: const [MinorNation(id: minor1, displayName: 'M1')],
          ),
          expandSnapshot(
            atWarWith: const [gp2, gp3],
            invadableOw: const [
              'oldWorld|gp3_a',
              'oldWorld|m1_a',
              'oldWorld|m1_b',
            ],
          ),
        ),
        matcher: gp3,
        reason:
            'Minors do not register as GPs in the blocker scan, so a '
            'minor-owned majority cannot shadow a single-province GP '
            'owner. A regression that counted minor-owned invadable OW '
            'would falsely return null (since the inner `provinceOwner['
            'pid] == owner` check would compare minor owners) and '
            'silently disable OW blocker preservation.',
      ),
    ];
