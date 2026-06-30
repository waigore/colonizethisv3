// Table-driven matrix consolidation of the two structurally-parallel
// observer-phase GP-blocker branch-pin suites (Refs #3749 branch-pin
// consolidation, continuation of the observer-phase matrix work in
// `observer_goal_phase_nw_suppression_predicate_game_matrix_test.dart`).
//
// Part 1 of 3 — GP-blocker contracts. The COLONIAL + EXPAND peace-target
// guard ladders live in
// `observer_goal_phase_gp_blocker_peace_matrix_part2_test.dart`; the
// DEVELOP + stalled-below-quota peace ladders live in
// `observer_goal_phase_gp_blocker_peace_matrix_part3_test.dart`. Shared
// fixture families and the truth-table / guard-branch runners live in
// `observer_goal_phase_gp_blocker_peace_matrix_support.dart`.
//
// This part replaces the blocker-contract halves of two former per-phase
// `*_branches_test.dart` suites:
//
//   - `observer_goal_phase_colonial_peace_blocker_branches_test.dart`
//     (`primaryColonialGpBlocker`, COLONIAL phase, NEW-WORLD invadable
//     frontier; Refs #2509 S10, PR #2661).
//   - `observer_goal_phase_expand_peace_blocker_branches_test.dart`
//     (`primaryInvadableOldWorldGpBlocker`, EXPAND phase, OLD-WORLD
//     invadable frontier; Refs #2509 S10).
//
// Both functions share the `({required Game game, required AIWorldSnapshot
// snapshot}) -> String?` signature, so the two blocker contracts collapse
// into one shared truth-table runner ([runBlocker]). Coverage is preserved
// 1:1 — every former `test(...)` becomes one matrix row with the same
// fixture and the verbatim regression `reason`.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'observer_goal_phase_gp_blocker_peace_matrix_support.dart';

void main() {
  // ---------------------------------------------------------------------
  // primaryColonialGpBlocker contract (COLONIAL / NW frontier).
  // ---------------------------------------------------------------------
  runBlocker(
    'primaryColonialGpBlocker contract',
    primaryColonialGpBlocker,
    <BlockerCase>[
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
    ],
  );

  group('primaryColonialGpBlocker determinism', () {
    test('identical inputs produce identical blocker', () {
      // Must-have #7 (determinism) at the function-unit level.
      final game = gameWithNwProvinces(
        turnNumber: 110,
        nwProvinces: const [
          Province(id: 'newWorld|gp2_a', regionId: 'newWorld', ownerId: gp2),
          Province(id: 'newWorld|gp2_b', regionId: 'newWorld', ownerId: gp2),
          Province(id: 'newWorld|gp3_a', regionId: 'newWorld', ownerId: gp3),
        ],
      );
      final snapshot = colonialSnapshot(
        atWarWith: const [gp2, gp3],
        invadableNw: const [
          'newWorld|gp2_a',
          'newWorld|gp2_b',
          'newWorld|gp3_a',
        ],
      );
      final first = primaryColonialGpBlocker(game: game, snapshot: snapshot);
      final second = primaryColonialGpBlocker(game: game, snapshot: snapshot);
      expect(second, first);
    });
  });

  // ---------------------------------------------------------------------
  // primaryInvadableOldWorldGpBlocker contract (EXPAND / OW frontier).
  // ---------------------------------------------------------------------
  runBlocker(
    'primaryInvadableOldWorldGpBlocker contract',
    primaryInvadableOldWorldGpBlocker,
    <BlockerCase>[
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
    ],
  );

  group('primaryInvadableOldWorldGpBlocker determinism', () {
    test('identical inputs produce identical blocker', () {
      // Must-have #7 (determinism) at the function-unit level.
      final game = gameWithOwProvinces(
        turnNumber: 50,
        owProvinces: const [
          Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: gp2),
          Province(id: 'oldWorld|gp2_b', regionId: 'oldWorld', ownerId: gp2),
          Province(id: 'oldWorld|gp3_a', regionId: 'oldWorld', ownerId: gp3),
        ],
      );
      final snapshot = expandSnapshot(
        atWarWith: const [gp2, gp3],
        invadableOw: const [
          'oldWorld|gp2_a',
          'oldWorld|gp2_b',
          'oldWorld|gp3_a',
        ],
      );
      final first = primaryInvadableOldWorldGpBlocker(
        game: game,
        snapshot: snapshot,
      );
      final second = primaryInvadableOldWorldGpBlocker(
        game: game,
        snapshot: snapshot,
      );
      expect(second, first);
    });
  });
}
