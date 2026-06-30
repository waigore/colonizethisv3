// Table-driven matrix consolidation of the two structurally-parallel
// observer-phase GP-blocker / peace-target branch-pin suites (Refs #3749
// branch-pin consolidation, continuation of the observer-phase matrix work
// in `observer_goal_phase_nw_suppression_predicate_game_matrix_test.dart`).
//
// This single file replaces two former per-phase `*_branches_test.dart`
// suites that each pinned one `primary*GpBlocker` contract plus one
// `*PhaseGpPeaceTargets` guard ladder at the function-unit boundary:
//
//   - `observer_goal_phase_colonial_peace_blocker_branches_test.dart`
//     (`primaryColonialGpBlocker` + `colonialPhaseGpPeaceTargets`, COLONIAL
//     phase, NEW-WORLD invadable frontier; Refs #2509 S10, PR #2661).
//   - `observer_goal_phase_expand_peace_blocker_branches_test.dart`
//     (`primaryInvadableOldWorldGpBlocker` + `expandPhaseGpPeaceTargets`,
//     EXPAND phase, OLD-WORLD invadable frontier; Refs #2509 S10).
//
// All four functions share the exact signature
// `({required Game game, required AIWorldSnapshot snapshot})` returning
// `String?` (blocker) or `List<String>` (peace targets), so the two
// blocker contracts collapse into one shared truth-table runner and the
// two peace-target guard ladders collapse into one shared case runner.
// Coverage is preserved 1:1 — every former `test(...)` becomes one matrix
// row with the same fixture and the verbatim regression `reason` — while
// the duplicated per-file fixtures and scaffolding collapse into two
// shared fixture families (COLONIAL/NW and EXPAND/OW). The EXPAND family
// keeps its unique minor-first and mutual-plateau arms as explicit rows;
// the COLONIAL family has no minor-first branch.
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

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _gp4 = 'gp4';
const String _tribe1 = 'tribe1';
const String _tribe2 = 'tribe2';
const String _minor1 = 'minor1';
const String _minor2 = 'minor2';

// --- COLONIAL / NEW-WORLD fixture family --------------------------------

/// Game with NW provinces enumerated by `(id, ownerId)` pairs.
Game _gameWithNwProvinces({
  required int turnNumber,
  required List<Province> nwProvinces,
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
  List<MinorNation> minorNations = const [
    MinorNation(id: _minor1, displayName: 'M1'),
  ],
}) {
  return Game(
    id: 'g-2509-colonial-peace-blocker-branches-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(
        turnNumber: turnNumber,
        phase: TurnPhase.orders,
      ),
      oldWorld: const RegionData(),
      newWorld: RegionData(provinces: nwProvinces),
    ),
    players: players,
    tribes: tribes,
    minorNations: minorNations,
  );
}

/// Snapshot fixing the GP at the OW quota (10) with COLONIAL acquisition
/// targets visible — keeps `observerGoalPhaseFor` on COLONIAL so the
/// peace-target helper runs.
AIWorldSnapshot _colonialSnapshot({
  required List<String> atWarWith,
  required List<String> invadableNw,
  List<String> adjacentNw = const [],
  String playerId = _gp1,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(
      oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
      provincesToVictory: 21,
    ),
    colonial: ColonialSummary(
      invadableNewWorldProvinceIdsSorted: invadableNw,
      adjacentNewWorldOwnerFactionIdsSorted: adjacentNw.isEmpty
          ? (invadableNw.isEmpty ? const [_tribe1] : const [])
          : adjacentNw,
    ),
    economy: const EconomySummary(),
    relations: const {},
  );
}

// --- EXPAND / OLD-WORLD fixture family ----------------------------------

/// Game with OW provinces enumerated by `(id, ownerId)` pairs.
///
/// Uses default 4-GP roster + 2 tribes (no minors mounted) so single
/// fixtures can flip ownership without rewiring the roster. Tests that
/// want the minor-first branch supply their own minor list.
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

// --- Blocker-contract truth-table runner --------------------------------

typedef _BlockerFn = String? Function({
  required Game game,
  required AIWorldSnapshot snapshot,
});

/// One blocker-contract branch row transcribed from a source
/// `*_branches_test`. [matcher] is the verbatim expected blocker (a faction
/// id or `isNull`) and [reason] the verbatim regression rationale.
class _BlockerCase {
  const _BlockerCase({
    required this.label,
    required this.build,
    required this.matcher,
    required this.reason,
  });

  final String label;
  final (Game, AIWorldSnapshot) Function() build;
  final Object matcher;
  final String reason;
}

void _runBlocker(String groupLabel, _BlockerFn fn, List<_BlockerCase> cases) {
  group(groupLabel, () {
    for (final c in cases) {
      test(c.label, () {
        final (game, snapshot) = c.build();
        expect(fn(game: game, snapshot: snapshot), c.matcher, reason: c.reason);
      });
    }
  });
}

// --- Peace-target guard-branch runner -----------------------------------

typedef _PeaceFn = List<String> Function({
  required Game game,
  required AIWorldSnapshot snapshot,
});

/// One peace-target guard-branch row transcribed from a source
/// `*_branches_test`. The optional [expectedPhase] re-asserts the shared
/// phase fixture control (skipped for the rows whose source test did not
/// assert the phase), and the optional blocker sanity check mirrors the
/// source rows that first pinned `primary*GpBlocker` before the peace list.
class _PeaceCase {
  const _PeaceCase({
    required this.label,
    required this.gameBuilder,
    required this.snapshot,
    required this.expectedPeace,
    this.peaceReason,
    this.expectedPhase,
    this.phaseReason,
    this.blockerFn,
    this.blockerExpected,
    this.blockerReason,
  });

  final String label;
  final Game Function() gameBuilder;
  final AIWorldSnapshot snapshot;
  final Object expectedPeace;
  final String? peaceReason;
  final ObserverGoalPhase? expectedPhase;
  final String? phaseReason;
  final _BlockerFn? blockerFn;
  final Object? blockerExpected;
  final String? blockerReason;
}

void _runPeace(String groupLabel, _PeaceFn fn, List<_PeaceCase> cases) {
  group(groupLabel, () {
    for (final c in cases) {
      test(c.label, () {
        final game = c.gameBuilder();
        final expectedPhase = c.expectedPhase;
        if (expectedPhase != null) {
          expect(
            observerGoalPhaseFor(snapshot: c.snapshot, game: game),
            expectedPhase,
            reason: c.phaseReason,
          );
        }
        final blockerFn = c.blockerFn;
        if (blockerFn != null) {
          expect(
            blockerFn(game: game, snapshot: c.snapshot),
            c.blockerExpected,
            reason: c.blockerReason,
          );
        }
        expect(
          fn(game: game, snapshot: c.snapshot),
          c.expectedPeace,
          reason: c.peaceReason,
        );
      });
    }
  });
}

void main() {
  // ---------------------------------------------------------------------
  // primaryColonialGpBlocker contract (COLONIAL / NW frontier).
  // ---------------------------------------------------------------------
  _runBlocker(
    'primaryColonialGpBlocker contract',
    primaryColonialGpBlocker,
    <_BlockerCase>[
      _BlockerCase(
        label: 'empty invadable NW → null',
        build: () => (
          _gameWithNwProvinces(turnNumber: 110, nwProvinces: const []),
          _colonialSnapshot(
            atWarWith: const [_gp2, _gp3],
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
      _BlockerCase(
        label: 'all invadable NW owned by tribes/minors → null',
        build: () => (
          _gameWithNwProvinces(
            turnNumber: 110,
            nwProvinces: const [
              Province(
                id: 'newWorld|t1_a',
                regionId: 'newWorld',
                ownerId: _tribe1,
              ),
              Province(
                id: 'newWorld|t2_a',
                regionId: 'newWorld',
                ownerId: _tribe2,
              ),
              Province(
                id: 'newWorld|m1_a',
                regionId: 'newWorld',
                ownerId: _minor1,
              ),
            ],
          ),
          _colonialSnapshot(
            atWarWith: const [_gp2, _gp3],
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
      _BlockerCase(
        label: 'all invadable NW unowned (null owner) → null',
        build: () => (
          _gameWithNwProvinces(
            turnNumber: 110,
            nwProvinces: const [
              Province(id: 'newWorld|u_a', regionId: 'newWorld'),
              Province(id: 'newWorld|u_b', regionId: 'newWorld'),
            ],
          ),
          _colonialSnapshot(
            atWarWith: const [_gp2, _gp3],
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
      _BlockerCase(
        label: 'single GP owning all invadable NW → that GP',
        build: () => (
          _gameWithNwProvinces(
            turnNumber: 110,
            nwProvinces: const [
              Province(
                id: 'newWorld|gp2_a',
                regionId: 'newWorld',
                ownerId: _gp2,
              ),
              Province(
                id: 'newWorld|gp2_b',
                regionId: 'newWorld',
                ownerId: _gp2,
              ),
            ],
          ),
          _colonialSnapshot(
            atWarWith: const [_gp2, _gp3],
            invadableNw: const ['newWorld|gp2_a', 'newWorld|gp2_b'],
          ),
        ),
        matcher: _gp2,
        reason:
            'When exactly one GP owns every invadable NW province, that GP '
            'is unambiguously the colonial blocker.',
      ),
      _BlockerCase(
        label: 'plurality wins among multiple GP owners (2 vs 1)',
        build: () => (
          _gameWithNwProvinces(
            turnNumber: 110,
            nwProvinces: const [
              Province(
                id: 'newWorld|gp2_a',
                regionId: 'newWorld',
                ownerId: _gp2,
              ),
              Province(
                id: 'newWorld|gp2_b',
                regionId: 'newWorld',
                ownerId: _gp2,
              ),
              Province(
                id: 'newWorld|gp3_a',
                regionId: 'newWorld',
                ownerId: _gp3,
              ),
            ],
          ),
          _colonialSnapshot(
            atWarWith: const [_gp2, _gp3],
            invadableNw: const [
              'newWorld|gp2_a',
              'newWorld|gp2_b',
              'newWorld|gp3_a',
            ],
          ),
        ),
        matcher: _gp2,
        reason:
            'The GP with the largest count of owned invadable NW provinces '
            'is the colonial blocker (strict `>` over running max). A '
            'regression that picked the last encountered GP, the highest '
            'factionId, or any non-plurality owner would shift the '
            'preservation set off the correct frontier.',
      ),
      _BlockerCase(
        label: 'mixed GP + tribe ownership: only GP counts contribute',
        // gp3 owns one invadable NW; tribe1 owns two. The plurality scan
        // skips tribe-owned provinces entirely, so gp3 is the blocker even
        // though it does not own the most invadable NW overall.
        build: () => (
          _gameWithNwProvinces(
            turnNumber: 110,
            nwProvinces: const [
              Province(
                id: 'newWorld|t1_a',
                regionId: 'newWorld',
                ownerId: _tribe1,
              ),
              Province(
                id: 'newWorld|t1_b',
                regionId: 'newWorld',
                ownerId: _tribe1,
              ),
              Province(
                id: 'newWorld|gp3_a',
                regionId: 'newWorld',
                ownerId: _gp3,
              ),
            ],
          ),
          _colonialSnapshot(
            atWarWith: const [_gp2, _gp3],
            invadableNw: const [
              'newWorld|gp3_a',
              'newWorld|t1_a',
              'newWorld|t1_b',
            ],
          ),
        ),
        matcher: _gp3,
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
      final game = _gameWithNwProvinces(
        turnNumber: 110,
        nwProvinces: const [
          Province(id: 'newWorld|gp2_a', regionId: 'newWorld', ownerId: _gp2),
          Province(id: 'newWorld|gp2_b', regionId: 'newWorld', ownerId: _gp2),
          Province(id: 'newWorld|gp3_a', regionId: 'newWorld', ownerId: _gp3),
        ],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_gp2, _gp3],
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
  _runBlocker(
    'primaryInvadableOldWorldGpBlocker contract',
    primaryInvadableOldWorldGpBlocker,
    <_BlockerCase>[
      _BlockerCase(
        label: 'empty invadable OW -> null',
        build: () => (
          _gameWithOwProvinces(turnNumber: 50, owProvinces: const []),
          _expandSnapshot(
            atWarWith: const [_gp2, _gp3],
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
      _BlockerCase(
        label: 'all invadable OW owned by tribes/minors -> null',
        build: () => (
          _gameWithOwProvinces(
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
          ),
          _expandSnapshot(
            atWarWith: const [_gp2, _gp3],
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
      _BlockerCase(
        label: 'all invadable OW unowned (null owner) -> null',
        build: () => (
          _gameWithOwProvinces(
            turnNumber: 50,
            owProvinces: const [
              Province(id: 'oldWorld|u_a', regionId: 'oldWorld'),
              Province(id: 'oldWorld|u_b', regionId: 'oldWorld'),
            ],
          ),
          _expandSnapshot(
            atWarWith: const [_gp2, _gp3],
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
      _BlockerCase(
        label: 'single GP owning all invadable OW -> that GP',
        build: () => (
          _gameWithOwProvinces(
            turnNumber: 50,
            owProvinces: const [
              Province(
                id: 'oldWorld|gp2_a',
                regionId: 'oldWorld',
                ownerId: _gp2,
              ),
              Province(
                id: 'oldWorld|gp2_b',
                regionId: 'oldWorld',
                ownerId: _gp2,
              ),
            ],
          ),
          _expandSnapshot(
            atWarWith: const [_gp2, _gp3],
            invadableOw: const ['oldWorld|gp2_a', 'oldWorld|gp2_b'],
          ),
        ),
        matcher: _gp2,
        reason:
            'When exactly one GP owns every invadable OW province, that GP '
            'is unambiguously the OW frontier blocker.',
      ),
      _BlockerCase(
        label: 'plurality wins among multiple GP owners (2 vs 1)',
        build: () => (
          _gameWithOwProvinces(
            turnNumber: 50,
            owProvinces: const [
              Province(
                id: 'oldWorld|gp2_a',
                regionId: 'oldWorld',
                ownerId: _gp2,
              ),
              Province(
                id: 'oldWorld|gp2_b',
                regionId: 'oldWorld',
                ownerId: _gp2,
              ),
              Province(
                id: 'oldWorld|gp3_a',
                regionId: 'oldWorld',
                ownerId: _gp3,
              ),
            ],
          ),
          _expandSnapshot(
            atWarWith: const [_gp2, _gp3],
            invadableOw: const [
              'oldWorld|gp2_a',
              'oldWorld|gp2_b',
              'oldWorld|gp3_a',
            ],
          ),
        ),
        matcher: _gp2,
        reason:
            'The GP with the largest count of owned invadable OW provinces '
            'is the OW frontier blocker (strict `>` over running max). A '
            'regression that picked the last encountered GP, the highest '
            'factionId, or any non-plurality owner would shift the '
            'preservation set off the correct frontier.',
      ),
      _BlockerCase(
        label: 'mixed GP + minor ownership: only GP counts contribute',
        // gp3 owns one invadable OW; minor1 owns two. The plurality scan
        // skips minor-owned provinces entirely, so gp3 is the blocker even
        // though it does not own the most invadable OW overall.
        build: () => (
          _gameWithOwProvinces(
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
              Province(
                id: 'oldWorld|gp3_a',
                regionId: 'oldWorld',
                ownerId: _gp3,
              ),
            ],
            minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
          ),
          _expandSnapshot(
            atWarWith: const [_gp2, _gp3],
            invadableOw: const [
              'oldWorld|gp3_a',
              'oldWorld|m1_a',
              'oldWorld|m1_b',
            ],
          ),
        ),
        matcher: _gp3,
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

  // ---------------------------------------------------------------------
  // colonialPhaseGpPeaceTargets guard branches (COLONIAL / NW frontier).
  // ---------------------------------------------------------------------
  _runPeace(
    'colonialPhaseGpPeaceTargets guard branches',
    colonialPhaseGpPeaceTargets,
    <_PeaceCase>[
      _PeaceCase(
        label: 'not in COLONIAL phase → empty (EXPAND fixture)',
        // OW = 7, well below quota → EXPAND.
        gameBuilder: () => _gameWithNwProvinces(
          turnNumber: 50,
          nwProvinces: const [
            Province(id: 'newWorld|gp2_a', regionId: 'newWorld', ownerId: _gp2),
          ],
        ),
        snapshot: const AIWorldSnapshot(
          playerId: _gp1,
          threats: ThreatSummary(atWarWith: [_gp2, _gp3]),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(oldWorldProvincesOwned: 7),
          colonial: ColonialSummary(
            invadableNewWorldProvinceIdsSorted: ['newWorld|gp2_a'],
            adjacentNewWorldOwnerFactionIdsSorted: [_gp2],
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
      _PeaceCase(
        label: 'empty gpWars → empty',
        // COLONIAL phase, but `atWarWith` empty.
        gameBuilder: () => _gameWithNwProvinces(
          turnNumber: 110,
          nwProvinces: const [
            Province(id: 'newWorld|gp2_a', regionId: 'newWorld', ownerId: _gp2),
          ],
        ),
        snapshot: _colonialSnapshot(
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
      _PeaceCase(
        label: 'single GP at war → empty (length <= 1 guard)',
        // SPEC: "when fighting two or more GPs". A one-GP war must keep the
        // front open for the regular war-pursuit path, not silently peace
        // it via the blocker-preservation rule.
        gameBuilder: () => _gameWithNwProvinces(
          turnNumber: 110,
          nwProvinces: const [
            Province(id: 'newWorld|gp2_a', regionId: 'newWorld', ownerId: _gp2),
          ],
        ),
        snapshot: _colonialSnapshot(
          atWarWith: const [_gp2],
          invadableNw: const ['newWorld|gp2_a'],
        ),
        expectedPhase: ObserverGoalPhase.colonial,
        expectedPeace: isEmpty,
        peaceReason:
            'A single-GP war is below the SPEC two-or-more-GPs trigger. The '
            'blocker-preservation rule must not engage here; the lone front '
            'is kept open by returning the empty peace-target list.',
      ),
      _PeaceCase(
        label: 'single GP at war which is the blocker → still empty '
            '(length guard)',
        // Confirms the order of guard checks: `gpWars.length <= 1` runs
        // before the blocker computation, so a single-GP war never reaches
        // the blocker-membership branch.
        gameBuilder: () => _gameWithNwProvinces(
          turnNumber: 110,
          nwProvinces: const [
            Province(id: 'newWorld|gp2_a', regionId: 'newWorld', ownerId: _gp2),
          ],
        ),
        snapshot: _colonialSnapshot(
          atWarWith: const [_gp2],
          invadableNw: const ['newWorld|gp2_a'],
        ),
        blockerFn: primaryColonialGpBlocker,
        blockerExpected: _gp2,
        blockerReason:
            'Sanity check: the blocker resolves to the only at-war GP. '
            'Despite that, the helper must still return empty due to the '
            '`gpWars.length <= 1` guard.',
        expectedPeace: isEmpty,
      ),
      _PeaceCase(
        label: 'two GPs at war but no GP-owned blocker → empty',
        // 2 GPs at war, but all invadable NW are tribe-owned, so
        // `primaryColonialGpBlocker` is null.
        gameBuilder: () => _gameWithNwProvinces(
          turnNumber: 110,
          nwProvinces: const [
            Province(id: 'newWorld|t1_a', regionId: 'newWorld', ownerId: _tribe1),
          ],
        ),
        snapshot: _colonialSnapshot(
          atWarWith: const [_gp2, _gp3],
          invadableNw: const ['newWorld|t1_a'],
          adjacentNw: const [_tribe1],
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
      _PeaceCase(
        label: 'blocker exists but is not among gpWars → empty',
        // gp4 owns the invadable NW (blocker = gp4) but the GP is at war
        // with gp2 and gp3 only.
        gameBuilder: () => _gameWithNwProvinces(
          turnNumber: 110,
          nwProvinces: const [
            Province(id: 'newWorld|gp4_a', regionId: 'newWorld', ownerId: _gp4),
          ],
        ),
        snapshot: _colonialSnapshot(
          atWarWith: const [_gp2, _gp3],
          invadableNw: const ['newWorld|gp4_a'],
          adjacentNw: const [_gp4],
        ),
        expectedPhase: ObserverGoalPhase.colonial,
        blockerFn: primaryColonialGpBlocker,
        blockerExpected: _gp4,
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
      _PeaceCase(
        label: 'three GPs at war with one blocker → other two sorted '
            'ascending',
        // Pins the deterministic ordering for the multi-GP-at-war happy
        // path. gp2 is the blocker; gp3 and gp4 are non-blockers and must
        // appear in stable ascending factionId order.
        gameBuilder: () => _gameWithNwProvinces(
          turnNumber: 110,
          nwProvinces: const [
            Province(id: 'newWorld|gp2_a', regionId: 'newWorld', ownerId: _gp2),
          ],
        ),
        // Provide war list out of sorted order to exercise the sort.
        snapshot: _colonialSnapshot(
          atWarWith: const [_gp4, _gp2, _gp3],
          invadableNw: const ['newWorld|gp2_a'],
          adjacentNw: const [_gp2],
        ),
        expectedPhase: ObserverGoalPhase.colonial,
        blockerFn: primaryColonialGpBlocker,
        blockerExpected: _gp2,
        expectedPeace: const [_gp3, _gp4],
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
  _runPeace(
    'expandPhaseGpPeaceTargets guard branches',
    expandPhaseGpPeaceTargets,
    <_PeaceCase>[
      _PeaceCase(
        label: 'not in EXPAND phase -> empty (DEVELOP fixture)',
        // OW = quota, no colonial targets -> DEVELOP.
        gameBuilder: () => _gameWithOwProvinces(
          turnNumber: 110,
          owProvinces: const [
            Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
          ],
        ),
        snapshot: const AIWorldSnapshot(
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
      _PeaceCase(
        label: 'empty gpWars -> empty',
        // EXPAND phase, but `atWarWith` empty.
        gameBuilder: () => _gameWithOwProvinces(
          turnNumber: 50,
          owProvinces: const [
            Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
          ],
        ),
        snapshot: _expandSnapshot(
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
      _PeaceCase(
        label: 'single GP at war with NO uninvaded minor -> empty '
            '(length guard)',
        // SPEC: "When at war with two or more GPs: peace all non-blocker
        // GP fronts". A one-GP war must keep the front open for the
        // regular war-pursuit path. With no uninvaded minor on the map the
        // minor-first branch is also skipped, so the length guard is the
        // sole gate.
        gameBuilder: () => _gameWithOwProvinces(
          turnNumber: 50,
          owProvinces: const [
            Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
          ],
        ),
        snapshot: _expandSnapshot(
          atWarWith: const [_gp2],
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
      _PeaceCase(
        label: 'mutual-plateau sole GP war on GP-only cleared frontier -> '
            'peace peer',
        gameBuilder: () => _gameWithOwProvinces(
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
        snapshot: _expandSnapshot(
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
      _PeaceCase(
        label: 'minor-first does not engage when the only uninvaded minor '
            'is already at war',
        // The minor-first branch requires `hasUninvadedOldWorldMinor`,
        // which excludes minors that are themselves in `atWarWith`. So a
        // minor that is "the only minor on the map" but currently at war
        // cannot trigger the rule. With a single GP at war and no other
        // minors, the helper must fall through to the `gpWars.length <= 1`
        // guard and return empty.
        gameBuilder: () => _gameWithOwProvinces(
          turnNumber: 50,
          owProvinces: const [
            Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
          ],
          minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
        ),
        snapshot: _expandSnapshot(
          atWarWith: const [_gp2, _minor1],
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
      _PeaceCase(
        label: 'two GPs at war but no GP-owned blocker -> empty '
            '(null blocker)',
        // 2 GPs at war, but all invadable OW are minor-owned, so
        // `primaryInvadableOldWorldGpBlocker` is null. With no uninvaded
        // (non-at-war) minor on the map the minor-first branch is also
        // skipped, and the null-blocker guard returns empty rather than
        // picking an arbitrary non-blocker GP.
        gameBuilder: () => _gameWithOwProvinces(
          turnNumber: 50,
          owProvinces: const [
            Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
          ],
          minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
        ),
        snapshot: _expandSnapshot(
          atWarWith: const [_gp2, _gp3, _minor1],
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
      _PeaceCase(
        label: 'blocker exists but is not among gpWars -> empty',
        // gp4 owns the invadable OW (blocker = gp4) but the GP is at war
        // with gp2 and gp3 only.
        gameBuilder: () => _gameWithOwProvinces(
          turnNumber: 50,
          owProvinces: const [
            Province(id: 'oldWorld|gp4_a', regionId: 'oldWorld', ownerId: _gp4),
          ],
        ),
        snapshot: _expandSnapshot(
          atWarWith: const [_gp2, _gp3],
          invadableOw: const ['oldWorld|gp4_a'],
        ),
        expectedPhase: ObserverGoalPhase.expand,
        blockerFn: primaryInvadableOldWorldGpBlocker,
        blockerExpected: _gp4,
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
      _PeaceCase(
        label: 'minor-first peaces every GP front while a second uninvaded '
            'minor remains and `atWarWith` includes a non-GP faction',
        // Defensive pin for the `gpWars` filter that runs before
        // minor-first: `atWarWith` includes a tribe id, which must be
        // dropped (it is not a player). With two GPs and one tribe in
        // `atWarWith`, plus an uninvaded minor still holding territory,
        // the helper must peace both GPs in ascending factionId order.
        gameBuilder: () => _gameWithOwProvinces(
          turnNumber: 50,
          owProvinces: const [
            Province(id: 'oldWorld|m2_a', regionId: 'oldWorld', ownerId: _minor2),
            Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
          ],
          minorNations: const [MinorNation(id: _minor2, displayName: 'M2')],
        ),
        // Provide war list out of sorted order to exercise the sort.
        snapshot: _expandSnapshot(
          atWarWith: const [_gp3, _tribe1, _gp2],
          invadableOw: const ['oldWorld|gp2_a'],
        ),
        expectedPhase: ObserverGoalPhase.expand,
        expectedPeace: const [_gp2, _gp3],
        peaceReason:
            'Minor-first peaces every GP front in stable ascending '
            'factionId order; non-GP factions in `atWarWith` must be '
            'filtered out of `gpWars` first (Refs #2509 must-have #7 '
            'determinism + EXPAND minor-first rule).',
      ),
      _PeaceCase(
        label: 'three GPs at war with one blocker (no uninvaded minor) -> '
            'other two sorted ascending',
        // Pins the deterministic ordering for the multi-GP-at-war happy
        // path with no minor-first short-circuit. gp2 is the blocker;
        // gp3 and gp4 are non-blockers and must appear in stable
        // ascending factionId order.
        gameBuilder: () => _gameWithOwProvinces(
          turnNumber: 50,
          owProvinces: const [
            Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
          ],
        ),
        // Provide war list out of sorted order to exercise the sort.
        snapshot: _expandSnapshot(
          atWarWith: const [_gp4, _gp2, _gp3],
          invadableOw: const ['oldWorld|gp2_a'],
        ),
        expectedPhase: ObserverGoalPhase.expand,
        blockerFn: primaryInvadableOldWorldGpBlocker,
        blockerExpected: _gp2,
        expectedPeace: const [_gp3, _gp4],
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
      final game = _gameWithOwProvinces(
        turnNumber: 50,
        owProvinces: const [
          Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
        ],
      );
      final snapshot = _expandSnapshot(
        atWarWith: const [_gp4, _gp2, _gp3],
        invadableOw: const ['oldWorld|gp2_a'],
      );
      final first = expandPhaseGpPeaceTargets(game: game, snapshot: snapshot);
      final second = expandPhaseGpPeaceTargets(game: game, snapshot: snapshot);
      expect(second, first);
    });
  });
}
