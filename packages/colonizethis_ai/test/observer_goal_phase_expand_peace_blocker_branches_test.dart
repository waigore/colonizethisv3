// Pins the EXPAND-phase peace-targeting branches of
// `primaryInvadableOldWorldGpBlocker` and `expandPhaseGpPeaceTargets`
// from issue #2509 S10 at the function-unit boundary (Refs #2509).
//
//   SPEC/ai/ai-architecture.md § Observer goal phases (Full AI), EXPAND:
//     "Hold blocker war ... peace the non-blocker GP front(s)" /
//     "When at war with two or more GPs: peace all non-blocker GP fronts"
//     plus the minor-first rule "exit every GP front while uninvaded
//     minors remain".
//
// This file is the EXPAND/OW analog of
// `observer_goal_phase_colonial_peace_blocker_branches_test.dart` (the
// COLONIAL pin landed via PR #2661). The COLONIAL helper has a simple
// not-in-phase / empty / single-GP / null-blocker / blocker-membership
// guard ladder; the EXPAND helper adds a **minor-first** early return
// that peaces every GP front while uninvaded OW minors remain. That
// branch has only one happy-path pin today (`observer_goal_phase_test.dart`
// group `expandPhaseGpPeaceTargets` test
// 'peaces every GP front when uninvaded minors remain below quota') and
// no negative pin asserting the branch is **not** entered when no minors
// remain.
//
// Sibling coverage that this file complements (but does not duplicate):
//
//   - `observer_goal_phase_test.dart` group `expandPhaseGpPeaceTargets`
//     pins the single canonical 2-GP non-blocker peace (gp2 blocker,
//     gp3 non-blocker -> `['gp3']`) and the single minor-first happy
//     path (uninvaded minor + 1 GP at war -> `[that GP]`). It does
//     **not** exercise the `primaryInvadableOldWorldGpBlocker` contract
//     itself, the empty / single-GP-without-minor guard arms, the
//     null-blocker fall-through, the blocker-not-in-`gpWars` branch,
//     the 3+ GP ordering, the non-EXPAND-phase early return, or the
//     defensive minor-first interaction with non-GP factions in
//     `atWarWith` (which must be filtered out of `gpWars` before the
//     minor-first short-circuit).
//   - `domain_planner_orchestrator_expand_two_gp_peace_test.dart` pins
//     the canonical 2-GP non-blocker peace at the orchestrator output.
//     It asserts `primaryInvadableOldWorldGpBlocker == gp2` only as a
//     sanity check on its own setup; it does not exercise the other
//     blocker branches in isolation.
//   - `domain_planner_orchestrator_expand_gp_only_blocker_declare_test.dart`
//     pins the single-GP-blocker declare-war path under EXPAND. It
//     also does not pin the blocker function's negative arms (empty,
//     all-non-GP, all-unowned, plurality).
//
// What's not currently pinned (this file's coverage):
//
//   1. **`primaryInvadableOldWorldGpBlocker` contract:** empty invadable
//      OW -> null; all invadable OW owned by non-GP factions (tribes /
//      minors / unowned) -> null; single GP owning all invadable OW ->
//      that GP; plurality wins among multiple GP owners; mixed GP +
//      non-GP ownership counts only GP-owned invadable provinces. A
//      regression that resolved the blocker to a minor owner, a
//      non-plurality GP, or `null` when a clear plurality GP exists
//      would silently invert the `expandPhaseGpPeaceTargets`
//      preservation set.
//   2. **`expandPhaseGpPeaceTargets` guard branches:** not in EXPAND ->
//      empty; empty `gpWars` -> empty; minor-first not engaged when no
//      uninvaded minor remains AND `gpWars.length <= 1` -> empty (the
//      length guard runs only after minor-first abstains, so a single
//      GP at war without minors must fall through to empty); null
//      blocker fall-through (`gpWars >= 2`, no GP-owned invadable OW)
//      -> empty; blocker exists but is not in `gpWars` -> empty
//      (blocker is a different GP than the live war fronts); non-GP
//      factions in `atWarWith` filtered out of `gpWars` before the
//      minor-first short-circuit; 3+ GP ordering returns the non-blocker
//      front list in ascending factionId order (deterministic for fixed
//      seed per Must-have #7).
//
// Coverage layers:
//   - **Function unit (`primaryInvadableOldWorldGpBlocker`):** empty
//     invadable / all-minor / all-tribe / all-unowned / single-GP /
//     plurality / mixed-GP-and-non-GP / determinism branch table.
//   - **Function unit (`expandPhaseGpPeaceTargets`):** not-in-EXPAND /
//     empty-gpWars / single-gpWar-without-minor / minor-first-with-non-GP-
//     filtered-faction / null-blocker / blocker-not-in-gpWars / 3-GP-
//     ordering branch table.
//
// Pin strategy: small synthetic fixtures targeted at one branch each.
// The happy paths are covered by the existing canonical tests; this
// file fills in the remaining branch arms so future S10 tuning cannot
// silently regress them.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _gp4 = 'gp4';
const String _tribe1 = 'tribe1';
const String _tribe2 = 'tribe2';
const String _minor1 = 'minor1';
const String _minor2 = 'minor2';

/// Game with OW provinces enumerated by `(id, ownerId)` pairs.
///
/// Uses default 4-GP roster + 2 tribes + 2 minors so single fixtures can
/// flip ownership without rewiring the roster.
Game _gameWithOwProvinces({
  required int turnNumber,
  required List<Province> owProvinces,
  List<Player> players = const [
    Player(id: _gp1, displayName: 'GP1', isHuman: false),
    Player(id: _gp2, displayName: 'GP2', isHuman: false),
    Player(id: _gp3, displayName: 'GP3', isHuman: false),
    Player(id: _gp4, displayName: 'GP4', isHuman: false),
  ],
  List<Tribe> tribes = const [
    Tribe(id: _tribe1, displayName: 'T1'),
    Tribe(id: _tribe2, displayName: 'T2'),
  ],
  // Default: no minors mounted, so `hasUninvadedOldWorldMinor` is false.
  // Tests that want the minor-first branch supply their own minor list.
  List<MinorNation> minorNations = const [],
}) {
  return Game(
    id: 'g-2509-expand-peace-blocker-branches-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(
        turnNumber: turnNumber,
        phase: TurnPhase.orders,
      ),
      oldWorld: RegionData(provinces: owProvinces),
      newWorld: const RegionData(),
    ),
    players: players,
    tribes: tribes,
    minorNations: minorNations,
  );
}

/// Snapshot fixing the GP below the OW quota (8 / 10) so
/// `observerGoalPhaseFor` returns EXPAND when the game does not also
/// satisfy the COLONIAL-lite turn / NW-ownership preconditions.
AIWorldSnapshot _expandSnapshot({
  required List<String> atWarWith,
  required List<String> invadableOw,
  int oldWorldProvincesOwned = 8,
  String playerId = _gp1,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: kObserverConquestMinOwProvincesPerGp * 3,
      invadableProvinceIdsSorted: invadableOw,
    ),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

void main() {
  group('primaryInvadableOldWorldGpBlocker contract', () {
    test('empty invadable OW -> null', () {
      final game = _gameWithOwProvinces(turnNumber: 50, owProvinces: const []);
      final snapshot = _expandSnapshot(
        atWarWith: const [_gp2, _gp3],
        invadableOw: const [],
      );
      expect(
        primaryInvadableOldWorldGpBlocker(game: game, snapshot: snapshot),
        isNull,
        reason:
            'No invadable OW provinces means no GP can be the OW frontier '
            'blocker -- the loop body never runs and the function returns '
            'null. A regression that returned an arbitrary at-war GP as '
            'blocker would silently preserve that front when '
            '`expandPhaseGpPeaceTargets` should peace all non-blockers (or '
            'fall through to a different rule when no blocker exists).',
      );
    });

    test('all invadable OW owned by tribes/minors -> null', () {
      final game = _gameWithOwProvinces(
        turnNumber: 50,
        owProvinces: const [
          Province(
            id: 'oldWorld|t1_a',
            regionId: 'oldWorld',
            ownerId: _tribe1,
          ),
          Province(
            id: 'oldWorld|t2_a',
            regionId: 'oldWorld',
            ownerId: _tribe2,
          ),
          Province(
            id: 'oldWorld|m1_a',
            regionId: 'oldWorld',
            ownerId: _minor1,
          ),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _expandSnapshot(
        atWarWith: const [_gp2, _gp3],
        invadableOw: const [
          'oldWorld|t1_a',
          'oldWorld|t2_a',
          'oldWorld|m1_a',
        ],
      );
      expect(
        primaryInvadableOldWorldGpBlocker(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Tribes and minor nations are not Great Powers '
            '(`game.playerById` returns null for them) so they are skipped '
            'by the blocker scan. A regression that counted non-GP owners '
            'would falsely identify a tribe / minor as the OW blocker and '
            'invert the EXPAND peace preservation set.',
      );
    });

    test('all invadable OW unowned (null owner) -> null', () {
      final game = _gameWithOwProvinces(
        turnNumber: 50,
        owProvinces: const [
          Province(id: 'oldWorld|u_a', regionId: 'oldWorld'),
          Province(id: 'oldWorld|u_b', regionId: 'oldWorld'),
        ],
      );
      final snapshot = _expandSnapshot(
        atWarWith: const [_gp2, _gp3],
        invadableOw: const ['oldWorld|u_a', 'oldWorld|u_b'],
      );
      expect(
        primaryInvadableOldWorldGpBlocker(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Unowned OW provinces have null ownerId in the province-owner '
            'map and are skipped by the blocker scan (mirrors the '
            '`getProvinceOwnerMap` contract). A regression that picked the '
            'first iterated province\'s owner unconditionally would crash '
            'or return an empty-string owner here.',
      );
    });

    test('single GP owning all invadable OW -> that GP', () {
      final game = _gameWithOwProvinces(
        turnNumber: 50,
        owProvinces: const [
          Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
          Province(id: 'oldWorld|gp2_b', regionId: 'oldWorld', ownerId: _gp2),
        ],
      );
      final snapshot = _expandSnapshot(
        atWarWith: const [_gp2, _gp3],
        invadableOw: const ['oldWorld|gp2_a', 'oldWorld|gp2_b'],
      );
      expect(
        primaryInvadableOldWorldGpBlocker(game: game, snapshot: snapshot),
        _gp2,
        reason:
            'When exactly one GP owns every invadable OW province, that GP '
            'is unambiguously the OW frontier blocker.',
      );
    });

    test('plurality wins among multiple GP owners (2 vs 1)', () {
      final game = _gameWithOwProvinces(
        turnNumber: 50,
        owProvinces: const [
          Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
          Province(id: 'oldWorld|gp2_b', regionId: 'oldWorld', ownerId: _gp2),
          Province(id: 'oldWorld|gp3_a', regionId: 'oldWorld', ownerId: _gp3),
        ],
      );
      final snapshot = _expandSnapshot(
        atWarWith: const [_gp2, _gp3],
        invadableOw: const [
          'oldWorld|gp2_a',
          'oldWorld|gp2_b',
          'oldWorld|gp3_a',
        ],
      );
      expect(
        primaryInvadableOldWorldGpBlocker(game: game, snapshot: snapshot),
        _gp2,
        reason:
            'The GP with the largest count of owned invadable OW provinces '
            'is the OW frontier blocker (strict `>` over running max). A '
            'regression that picked the last encountered GP, the highest '
            'factionId, or any non-plurality owner would shift the '
            'preservation set off the correct frontier.',
      );
    });

    test('mixed GP + minor ownership: only GP counts contribute', () {
      // gp3 owns one invadable OW; minor1 owns two. The plurality scan
      // skips minor-owned provinces entirely, so gp3 is the blocker even
      // though it does not own the most invadable OW overall.
      final game = _gameWithOwProvinces(
        turnNumber: 50,
        owProvinces: const [
          Province(
            id: 'oldWorld|m1_a',
            regionId: 'oldWorld',
            ownerId: _minor1,
          ),
          Province(
            id: 'oldWorld|m1_b',
            regionId: 'oldWorld',
            ownerId: _minor1,
          ),
          Province(id: 'oldWorld|gp3_a', regionId: 'oldWorld', ownerId: _gp3),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _expandSnapshot(
        atWarWith: const [_gp2, _gp3],
        invadableOw: const [
          'oldWorld|gp3_a',
          'oldWorld|m1_a',
          'oldWorld|m1_b',
        ],
      );
      expect(
        primaryInvadableOldWorldGpBlocker(game: game, snapshot: snapshot),
        _gp3,
        reason:
            'Minors do not register as GPs in the blocker scan, so a '
            'minor-owned majority cannot shadow a single-province GP '
            'owner. A regression that counted minor-owned invadable OW '
            'would falsely return null (since the inner `provinceOwner['
            'pid] == owner` check would compare minor owners) and '
            'silently disable OW blocker preservation.',
      );
    });

    test('determinism: identical inputs produce identical blocker', () {
      // Must-have #7 (determinism) at the function-unit level.
      final game = _gameWithOwProvinces(
        turnNumber: 50,
        owProvinces: const [
          Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
          Province(id: 'oldWorld|gp2_b', regionId: 'oldWorld', ownerId: _gp2),
          Province(id: 'oldWorld|gp3_a', regionId: 'oldWorld', ownerId: _gp3),
        ],
      );
      final snapshot = _expandSnapshot(
        atWarWith: const [_gp2, _gp3],
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

  group('expandPhaseGpPeaceTargets guard branches', () {
    test('not in EXPAND phase -> empty (DEVELOP fixture)', () {
      // OW = quota, no colonial targets -> DEVELOP.
      final game = _gameWithOwProvinces(
        turnNumber: 110,
        owProvinces: const [
          Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: _gp1,
        threats: ThreatSummary(atWarWith: [_gp2, _gp3]),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
          invadableProvinceIdsSorted: ['oldWorld|gp2_a'],
        ),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.develop,
        reason:
            'Fixture must place the GP in DEVELOP so the EXPAND peace '
            'helper\'s early return is the only branch under test.',
      );
      expect(
        expandPhaseGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Outside EXPAND the helper must return the empty list '
            'immediately -- COLONIAL and DEVELOP have their own '
            'peace-target helpers and their own SPEC rules.',
      );
    });

    test('empty gpWars -> empty', () {
      // EXPAND phase, but `atWarWith` empty.
      final game = _gameWithOwProvinces(
        turnNumber: 50,
        owProvinces: const [
          Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
        ],
      );
      final snapshot = _expandSnapshot(
        atWarWith: const [],
        invadableOw: const ['oldWorld|gp2_a'],
      );
      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.expand,
        reason: 'Fixture must place GP in EXPAND.',
      );
      expect(
        expandPhaseGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Empty `gpWars` short-circuits both the minor-first branch '
            '(which requires `gpWars.isNotEmpty`) and the `length <= 1` '
            'guard, returning empty without invoking the blocker scan.',
      );
    });

    test(
      'single GP at war with NO uninvaded minor -> empty (length guard)',
      () {
        // SPEC: "When at war with two or more GPs: peace all non-blocker
        // GP fronts". A one-GP war must keep the front open for the
        // regular war-pursuit path, not silently peace it via the
        // blocker-preservation rule. With no uninvaded minor on the map
        // the minor-first branch is also skipped, so the length guard
        // is the sole gate.
        final game = _gameWithOwProvinces(
          turnNumber: 50,
          owProvinces: const [
            Province(
              id: 'oldWorld|gp2_a',
              regionId: 'oldWorld',
              ownerId: _gp2,
            ),
          ],
        );
        final snapshot = _expandSnapshot(
          atWarWith: const [_gp2],
          invadableOw: const ['oldWorld|gp2_a'],
        );
        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.expand,
        );
        expect(
          expandPhaseGpPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'A single-GP war is below the SPEC two-or-more-GPs trigger '
              'and there is no uninvaded minor for the minor-first branch '
              'to engage. The blocker-preservation rule must not engage '
              'here; the lone front is kept open by returning the empty '
              'peace-target list.',
        );
      },
    );

    test(
      'mutual-plateau sole GP war on GP-only cleared frontier -> peace peer',
      () {
        final game = _gameWithOwProvinces(
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
        );
        final snapshot = _expandSnapshot(
          playerId: 'gp3',
          atWarWith: const ['gp4'],
          invadableOw: const ['oldWorld|gp4_0'],
          oldWorldProvincesOwned: 8,
        );
        expect(
          expandPhaseGpPeaceTargets(game: game, snapshot: snapshot),
          ['gp4'],
          reason:
              'Seed-42 gp3/gp4 plateau: when minors are cleared and the sole '
              'GP front is the mutual-plateau blocker, EXPAND must offer peace '
              'so rebuild/minor pivots can resume (Refs #2509).',
        );
      },
    );

    test(
      'minor-first does not engage when the only uninvaded minor is already '
      'at war',
      () {
        // The minor-first branch requires `hasUninvadedOldWorldMinor`,
        // which **excludes** minors that are themselves in
        // `atWarWith`. So a minor that is "the only minor on the map"
        // but currently at war cannot trigger the rule. With a single
        // GP at war and no other minors, the helper must fall through
        // to the `gpWars.length <= 1` guard and return empty.
        final game = _gameWithOwProvinces(
          turnNumber: 50,
          owProvinces: const [
            Province(
              id: 'oldWorld|m1_a',
              regionId: 'oldWorld',
              ownerId: _minor1,
            ),
          ],
          minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
        );
        final snapshot = _expandSnapshot(
          atWarWith: const [_gp2, _minor1],
          invadableOw: const ['oldWorld|m1_a'],
        );
        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.expand,
        );
        expect(
          expandPhaseGpPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'A minor already in `atWarWith` is not "uninvaded", so the '
              'minor-first branch does not engage. With only one GP in '
              'the filtered `gpWars` list and no remaining uninvaded '
              'minor, the helper returns empty via the `length <= 1` '
              'guard. A regression that counted at-war minors as '
              'uninvaded would peace the lone GP and undermine the '
              'EXPAND quota push.',
        );
      },
    );

    test(
      'two GPs at war but no GP-owned blocker -> empty (null blocker)',
      () {
        // 2 GPs at war, but all invadable OW are minor-owned, so
        // `primaryInvadableOldWorldGpBlocker` is null. With no uninvaded
        // (non-at-war) minor on the map the minor-first branch is also
        // skipped, and the null-blocker guard returns empty rather than
        // picking an arbitrary non-blocker GP.
        final game = _gameWithOwProvinces(
          turnNumber: 50,
          owProvinces: const [
            Province(
              id: 'oldWorld|m1_a',
              regionId: 'oldWorld',
              ownerId: _minor1,
            ),
          ],
          // minor1 is at war -> excluded from `hasUninvadedOldWorldMinor`.
          minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
        );
        final snapshot = _expandSnapshot(
          atWarWith: const [_gp2, _gp3, _minor1],
          invadableOw: const ['oldWorld|m1_a'],
        );
        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.expand,
        );
        expect(
          primaryInvadableOldWorldGpBlocker(game: game, snapshot: snapshot),
          isNull,
          reason:
              'Sanity check: only a minor owns invadable OW, so no GP '
              'qualifies as the OW blocker.',
        );
        expect(
          expandPhaseGpPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'Without a GP blocker the rule has no front to preserve. '
              'A regression that returned all `gpWars` as peace targets '
              'would silently peace both GPs and remove pressure on '
              'rival OW powers when the only invadable target is a '
              'minor (regular war-pursuit still handles the minor).',
        );
      },
    );

    test('blocker exists but is not among gpWars -> empty', () {
      // gp4 owns the invadable OW (blocker = gp4) but the GP is at war
      // with gp2 and gp3 only. The `!gpWars.contains(blocker)` guard
      // returns empty: there is no live blocker front to preserve, so
      // peacing the other GPs would still leave the OW frontier
      // untouched and the rule abstains.
      final game = _gameWithOwProvinces(
        turnNumber: 50,
        owProvinces: const [
          Province(id: 'oldWorld|gp4_a', regionId: 'oldWorld', ownerId: _gp4),
        ],
      );
      final snapshot = _expandSnapshot(
        atWarWith: const [_gp2, _gp3],
        invadableOw: const ['oldWorld|gp4_a'],
      );
      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.expand,
      );
      expect(
        primaryInvadableOldWorldGpBlocker(game: game, snapshot: snapshot),
        _gp4,
        reason:
            'Sanity check: the only GP owning an invadable OW province is '
            'gp4, so it is the OW blocker.',
      );
      expect(
        expandPhaseGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'When the blocker is not actually at war with the planning '
            'GP, no peace is suggested by this helper -- the SPEC rule '
            'preserves "Great Powers that do not own the primary '
            'invadable OW frontier blocker" only when that blocker is '
            'itself an active war front.',
      );
    });

    test(
      'minor-first peaces every GP front while a second uninvaded minor '
      'remains and `atWarWith` includes a non-GP faction',
      () {
        // Defensive pin for the `gpWars` filter that runs before
        // minor-first: `atWarWith` includes a tribe id, which must be
        // dropped (it is not a player). With two GPs and one tribe in
        // `atWarWith`, plus an uninvaded minor still holding territory,
        // the helper must peace **both** GPs in ascending factionId
        // order. A regression that left the tribe in `gpWars` would
        // produce an order list with a non-GP target and break the
        // downstream `offerPeace` validation.
        final game = _gameWithOwProvinces(
          turnNumber: 50,
          owProvinces: const [
            Province(
              id: 'oldWorld|m2_a',
              regionId: 'oldWorld',
              ownerId: _minor2,
            ),
            Province(
              id: 'oldWorld|gp2_a',
              regionId: 'oldWorld',
              ownerId: _gp2,
            ),
          ],
          minorNations: const [MinorNation(id: _minor2, displayName: 'M2')],
        );
        final snapshot = _expandSnapshot(
          // Provide war list out of sorted order to exercise the sort.
          atWarWith: const [_gp3, _tribe1, _gp2],
          invadableOw: const ['oldWorld|gp2_a'],
        );
        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.expand,
        );
        expect(
          expandPhaseGpPeaceTargets(game: game, snapshot: snapshot),
          const [_gp2, _gp3],
          reason:
              'Minor-first peaces every GP front in stable ascending '
              'factionId order; non-GP factions in `atWarWith` must be '
              'filtered out of `gpWars` first (Refs #2509 must-have #7 '
              'determinism + EXPAND minor-first rule).',
        );
      },
    );

    test(
      'three GPs at war with one blocker (no uninvaded minor) -> other two '
      'sorted ascending',
      () {
        // Pins the deterministic ordering for the multi-GP-at-war happy
        // path with no minor-first short-circuit. gp2 is the blocker;
        // gp3 and gp4 are non-blockers and must appear in stable
        // ascending factionId order.
        final game = _gameWithOwProvinces(
          turnNumber: 50,
          owProvinces: const [
            Province(
              id: 'oldWorld|gp2_a',
              regionId: 'oldWorld',
              ownerId: _gp2,
            ),
          ],
        );
        final snapshot = _expandSnapshot(
          // Provide war list out of sorted order to exercise the sort.
          atWarWith: const [_gp4, _gp2, _gp3],
          invadableOw: const ['oldWorld|gp2_a'],
        );
        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.expand,
        );
        expect(
          primaryInvadableOldWorldGpBlocker(game: game, snapshot: snapshot),
          _gp2,
        );
        expect(
          expandPhaseGpPeaceTargets(game: game, snapshot: snapshot),
          const [_gp3, _gp4],
          reason:
              'Non-blocker GPs must be returned in stable ascending '
              'factionId order so downstream order generation is '
              'deterministic for a fixed seed (Must-have #7).',
        );
      },
    );

    test(
      'determinism: identical inputs produce identical peace target list',
      () {
        // Must-have #7 (determinism) for the helper itself, mirroring
        // the `primaryInvadableOldWorldGpBlocker` determinism pin above.
        // The 3-GP-at-war fixture exercises both the blocker scan and
        // the sort, so repeating the call must yield the same list.
        final game = _gameWithOwProvinces(
          turnNumber: 50,
          owProvinces: const [
            Province(
              id: 'oldWorld|gp2_a',
              regionId: 'oldWorld',
              ownerId: _gp2,
            ),
          ],
        );
        final snapshot = _expandSnapshot(
          atWarWith: const [_gp4, _gp2, _gp3],
          invadableOw: const ['oldWorld|gp2_a'],
        );
        final first = expandPhaseGpPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        final second = expandPhaseGpPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        expect(second, first);
      },
    );
  });
}
