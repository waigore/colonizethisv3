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
// It also folds in two further peace-target guard suites that share the
// same `({required Game game, required AIWorldSnapshot snapshot}) ->
// List<String>` signature, so they reuse the same peace-target case
// runner:
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
// All six functions share the exact signature
// `({required Game game, required AIWorldSnapshot snapshot})` returning
// `String?` (blocker) or `List<String>` (peace targets), so the two
// blocker contracts collapse into one shared truth-table runner and the
// four peace-target guard ladders collapse into one shared case runner.
// Coverage is preserved 1:1 — every former `test(...)` becomes one matrix
// row with the same fixture and the verbatim regression `reason` — while
// the duplicated per-file fixtures and scaffolding collapse into four
// shared fixture families (COLONIAL/NW, EXPAND/OW, DEVELOP, and the
// own-vs-partner stalled-lead family). The EXPAND family keeps its unique
// minor-first and mutual-plateau arms as explicit rows; the COLONIAL
// family has no minor-first branch.
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

// --- DEVELOP fixture family ---------------------------------------------

/// Game scaffold with a configurable turn number and roster.
///
/// Defaults to a 4-GP roster (no minors / tribes mounted) so tests can
/// freely add `atWarWith` entries that resolve to GP players for the
/// inline `game.playerById(factionId) != null` filter. Tests that need
/// minor / tribe filtering supply their own minor / tribe lists.
Game _developGame({
  required int turnNumber,
  List<Player> players = const [
    Player(id: _gp1, displayName: 'GP1', isHuman: false),
    Player(id: _gp2, displayName: 'GP2', isHuman: false),
    Player(id: _gp3, displayName: 'GP3', isHuman: false),
    Player(id: _gp4, displayName: 'GP4', isHuman: false),
  ],
  List<Tribe> tribes = const [],
  List<MinorNation> minorNations = const [],
}) {
  return Game(
    id: 'g-2509-develop-peace-target-branches-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(
        turnNumber: turnNumber,
        phase: TurnPhase.orders,
      ),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: players,
    tribes: tribes,
    minorNations: minorNations,
  );
}

/// Snapshot fixing the GP **at** the OW quota (10) with an empty
/// colonial summary -- no invadable NW, no adjacent NW owners -- so
/// `observerGoalPhaseFor` returns DEVELOP and
/// `developPhaseGpPeaceTargets` is the helper under test.
AIWorldSnapshot _developSnapshot({
  required List<String> atWarWith,
  int oldWorldProvincesOwned = kObserverConquestMinOwProvincesPerGp,
  String playerId = _gp1,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
    ),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

// --- Stalled below-quota lead fixture family ----------------------------

/// Own-vs-partner OW roster fixture for `stalledBelowQuotaGpLeadPeaceTargets`.
///
/// `gp_own` holds [ownProvinces]; [partnerId] holds [partnerProvinces].
/// Optional [extraGpId] / [invadableOwnerId] / [minorId] layer in the
/// multi-GP, GP-only-blocker, and collection-guard branches.
Game _ownVsPartnerGame({
  required int ownProvinces,
  required int partnerProvinces,
  required String partnerId,
  String? extraGpId,
  int extraGpProvinces = 0,
  String? invadableOwnerId,
  String? minorId,
  bool atWarWithPartner = true,
  bool atWarWithExtraGp = true,
  bool atWarWithMinor = false,
}) {
  final provinces = <Province>[
    for (var i = 1; i <= ownProvinces; i++)
      Province(
        id: 'oldWorld|gp_own_$i',
        regionId: 'oldWorld',
        ownerId: 'gp_own',
      ),
    for (var i = 1; i <= partnerProvinces; i++)
      Province(
        id: 'oldWorld|${partnerId}_$i',
        regionId: 'oldWorld',
        ownerId: partnerId,
      ),
    if (extraGpId != null)
      for (var i = 1; i <= extraGpProvinces; i++)
        Province(
          id: 'oldWorld|${extraGpId}_$i',
          regionId: 'oldWorld',
          ownerId: extraGpId,
        ),
    if (invadableOwnerId != null)
      Province(
        id: 'oldWorld|frontier',
        regionId: 'oldWorld',
        ownerId: invadableOwnerId,
      ),
    if (minorId != null)
      const Province(
        id: 'oldWorld|minor_hold',
        regionId: 'oldWorld',
        ownerId: 'minor1',
      ),
  ];

  final players = <Player>[
    const Player(id: 'gp_own', displayName: 'GP_OWN', isHuman: false),
    Player(id: partnerId, displayName: partnerId, isHuman: false),
    if (extraGpId != null)
      Player(id: extraGpId, displayName: extraGpId, isHuman: false),
  ];

  final minorNations = <MinorNation>[
    if (minorId != null) MinorNation(id: minorId, displayName: minorId),
  ];

  final relations = <DiplomacyRelation>[
    if (atWarWithPartner)
      DiplomacyRelation(
        factionId1: 'gp_own',
        factionId2: partnerId,
        state: RelationState.atWar,
        score: 30,
      ),
    if (extraGpId != null && atWarWithExtraGp)
      DiplomacyRelation(
        factionId1: 'gp_own',
        factionId2: extraGpId,
        state: RelationState.atWar,
        score: 30,
      ),
    if (minorId != null && atWarWithMinor)
      DiplomacyRelation(
        factionId1: 'gp_own',
        factionId2: minorId,
        state: RelationState.atWar,
        score: 30,
      ),
  ];

  return Game(
    id: 'g-stalled-below-quota-${ownProvinces}_vs_$partnerProvinces',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
    ),
    players: players,
    minorNations: minorNations,
    diplomacyRelations: relations,
  );
}

AIWorldSnapshot _ownSnapshot({
  required int oldWorldProvincesOwned,
  required List<String> atWarWith,
  List<String> invadableProvinceIdsSorted = const [],
}) {
  return AIWorldSnapshot(
    playerId: 'gp_own',
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      invadableProvinceIdsSorted: invadableProvinceIdsSorted,
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

  // ---------------------------------------------------------------------
  // developPhaseGpPeaceTargets guard branches (DEVELOP phase, GP-vs-GP
  // peace-all rule). No blocker preservation and no minor-first
  // short-circuit (unlike EXPAND / COLONIAL).
  // ---------------------------------------------------------------------
  _runPeace(
    'developPhaseGpPeaceTargets guard branches',
    developPhaseGpPeaceTargets,
    <_PeaceCase>[
      _PeaceCase(
        label: 'not in DEVELOP phase (EXPAND fixture) -> empty',
        // Below OW quota -> EXPAND. EXPAND has its own peace-target
        // helper (`expandPhaseGpPeaceTargets`) with a different rule
        // (minor-first + blocker preservation), so the DEVELOP helper
        // must abstain here. A regression that dropped the phase guard
        // would silently flatten "peace all GPs" onto EXPAND fronts and
        // collapse the SPEC EXPAND minor-first / blocker preservation
        // contract.
        gameBuilder: () => _developGame(turnNumber: 50),
        snapshot: const AIWorldSnapshot(
          playerId: _gp1,
          threats: ThreatSummary(atWarWith: [_gp2, _gp3]),
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
      _PeaceCase(
        label: 'not in DEVELOP phase (COLONIAL fixture) -> empty',
        // OW at quota plus visible invadable NW -> COLONIAL. COLONIAL
        // preserves the colonial-blocker GP front via
        // `colonialPhaseGpPeaceTargets`. A regression that dropped the
        // phase guard would peace every at-war GP in COLONIAL and
        // collapse the blocker preservation rule.
        gameBuilder: () => _developGame(turnNumber: 110),
        snapshot: const AIWorldSnapshot(
          playerId: _gp1,
          threats: ThreatSummary(atWarWith: [_gp2, _gp3]),
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
      _PeaceCase(
        label: 'DEVELOP with empty atWarWith -> empty',
        // DEVELOP phase entry confirmed below; the loop body never runs
        // and the sort on an empty list is a no-op. A regression that
        // returned the at-peace GP roster would generate spurious
        // `offerPeace` orders toward neutral powers.
        gameBuilder: () => _developGame(turnNumber: 140),
        snapshot: _developSnapshot(atWarWith: const []),
        expectedPhase: ObserverGoalPhase.develop,
        phaseReason: 'Fixture must place GP in DEVELOP.',
        expectedPeace: isEmpty,
        peaceReason:
            'Empty `atWarWith` means there are no live war fronts; '
            'the helper must return empty without iterating the GP '
            'roster.',
      ),
      _PeaceCase(
        label: 'DEVELOP with only minors/tribes in atWarWith -> empty',
        // The inline `game.playerById(factionId) != null` filter must
        // drop every non-GP faction. DEVELOP is GP-vs-GP peace only --
        // minor / tribe wars are pursued through other diplomacy paths
        // (war pursuit, embassy chain, purchase_land). A regression
        // that returned tribe / minor ids here would emit `offerPeace`
        // toward non-GP factions and break downstream order
        // validation.
        gameBuilder: () => _developGame(
          turnNumber: 140,
          tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
          minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
        ),
        snapshot: _developSnapshot(atWarWith: const [_tribe1, _minor1]),
        expectedPhase: ObserverGoalPhase.develop,
        phaseReason: 'Fixture must place GP in DEVELOP.',
        expectedPeace: isEmpty,
        peaceReason:
            'Non-GP factions (tribes / minors) are filtered out of '
            'the peace-target list by `game.playerById` returning '
            'null for non-player ids. With only non-GP wars present, '
            'the helper must return empty.',
      ),
      _PeaceCase(
        label: 'DEVELOP with single GP at war -> [that GP]',
        // Unlike EXPAND / COLONIAL, DEVELOP has **no** `gpWars.length
        // <= 1` guard -- a single GP front must be peaced too. A
        // regression that copied the EXPAND / COLONIAL length guard
        // would leave a lone GP war open and starve the
        // improvement-first DEVELOP civilian work (turn-150
        // `--verify-colonial-expansion` 70% extractable-tile
        // improvement gate).
        gameBuilder: () => _developGame(turnNumber: 140),
        snapshot: _developSnapshot(atWarWith: const [_gp2]),
        expectedPhase: ObserverGoalPhase.develop,
        phaseReason: 'Fixture must place GP in DEVELOP.',
        expectedPeace: const [_gp2],
        peaceReason:
            'DEVELOP peace rule covers every at-war GP, including a '
            'single GP front. The helper must return a one-element '
            'list, not empty.',
      ),
      _PeaceCase(
        label: 'DEVELOP with three GPs at war (unsorted input) -> '
            'ascending sorted',
        // Pins the `..sort()` contract: the helper must return GP
        // fronts in stable ascending `factionId` order so downstream
        // order generation is deterministic for a fixed seed
        // (Must-have #7). Input order shuffled to gp3 / gp4 / gp2 so
        // a regression that dropped the sort (or replaced it with
        // input-order preservation) would surface here.
        gameBuilder: () => _developGame(turnNumber: 140),
        snapshot: _developSnapshot(atWarWith: const [_gp3, _gp4, _gp2]),
        expectedPhase: ObserverGoalPhase.develop,
        phaseReason: 'Fixture must place GP in DEVELOP.',
        expectedPeace: const [_gp2, _gp3, _gp4],
        peaceReason:
            'All at-war GPs returned in ascending `factionId` order '
            'regardless of `snapshot.threats.atWarWith` order '
            '(Refs #2509 must-have #7 determinism).',
      ),
      _PeaceCase(
        label: 'DEVELOP with mixed GP + non-GP atWarWith -> only GPs, sorted',
        // Defensive pin: the filter and the sort must compose so that
        // tribe / minor ids in `atWarWith` are dropped **before** the
        // sort runs. The shuffled input order (gp3, tribe1, gp2,
        // minor1) exercises both the filter (drops tribe1, minor1)
        // and the sort (gp3, gp2 -> gp2, gp3) in one fixture. A
        // regression that sorted first and filtered after would
        // still pass; a regression that left non-GP ids in the
        // output list would break downstream `offerPeace` validation.
        gameBuilder: () => _developGame(
          turnNumber: 140,
          tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
          minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
        ),
        snapshot: _developSnapshot(
          atWarWith: const [_gp3, _tribe1, _gp2, _minor1],
        ),
        expectedPhase: ObserverGoalPhase.develop,
        phaseReason: 'Fixture must place GP in DEVELOP.',
        expectedPeace: const [_gp2, _gp3],
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
      final game = _developGame(
        turnNumber: 140,
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _developSnapshot(
        atWarWith: const [_gp3, _tribe1, _gp2, _minor1],
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
  _runPeace(
    'stalledBelowQuotaGpLeadPeaceTargets branches',
    stalledBelowQuotaGpLeadPeaceTargets,
    <_PeaceCase>[
      _PeaceCase(
        label: 'quota guard: empty at the observer OW quota even when '
            'enemy leads by 3+',
        gameBuilder: () => _ownVsPartnerGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp,
          partnerProvinces: kObserverConquestMinOwProvincesPerGp + 3,
          partnerId: 'gp_enemy',
        ),
        snapshot: _ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
          atWarWith: const ['gp_enemy'],
        ),
        expectedPeace: isEmpty,
        peaceReason:
            'At kObserverConquestMinOwProvincesPerGp the below-quota lead-peace '
            'shortcut must not run (COLONIAL/DEVELOP paths own mop-up).',
      ),
      _PeaceCase(
        label: 'minLeadDeficit: default-start empty when enemy leads by '
            'only 1 (needs 2)',
        gameBuilder: () => _ownVsPartnerGame(
          ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
          partnerProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 1,
          partnerId: 'gp_enemy',
          invadableOwnerId: 'minor1',
        ),
        snapshot: _ownSnapshot(
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
      _PeaceCase(
        label: 'minLeadDeficit: default-start returns enemy when lead is '
            'exactly 2',
        gameBuilder: () => _ownVsPartnerGame(
          ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
          partnerProvinces: kObserverDefaultStartOldWorldProvincesPerGp +
              kUnwinnableSoleGpMinProvinceDeficit,
          partnerId: 'gp_enemy',
          invadableOwnerId: 'minor1',
        ),
        snapshot: _ownSnapshot(
          oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
          atWarWith: const ['gp_enemy'],
          invadableProvinceIdsSorted: const ['oldWorld|frontier'],
        ),
        expectedPeace: const ['gp_enemy'],
      ),
      _PeaceCase(
        label: 'minLeadDeficit: post-default empty when enemy ties OW '
            'count (needs 1)',
        gameBuilder: () => _ownVsPartnerGame(
          ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 1,
          partnerProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 1,
          partnerId: 'gp_enemy',
        ),
        snapshot: _ownSnapshot(
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
      _PeaceCase(
        label: 'minLeadDeficit: post-default returns enemy when lead is '
            'exactly 1',
        gameBuilder: () => _ownVsPartnerGame(
          ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 1,
          partnerProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 2,
          partnerId: 'gp_enemy',
        ),
        snapshot: _ownSnapshot(
          oldWorldProvincesOwned:
              kObserverDefaultStartOldWorldProvincesPerGp + 1,
          atWarWith: const ['gp_enemy'],
          invadableProvinceIdsSorted: const ['oldWorld|inv1'],
        ),
        expectedPeace: const ['gp_enemy'],
      ),
      _PeaceCase(
        label: 'GP-only blocker: skips invadable blocker but keeps '
            'non-blocker GP with sufficient lead',
        gameBuilder: () => _ownVsPartnerGame(
          ownProvinces: 8,
          partnerProvinces: 9,
          partnerId: 'gp_blocker',
          extraGpId: 'gp_enemy',
          extraGpProvinces: 11,
          invadableOwnerId: 'gp_blocker',
        ),
        snapshot: _ownSnapshot(
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
      _PeaceCase(
        label: 'GP-only blocker: empty when sole at-war GP is the '
            'invadable blocker with lead 1',
        gameBuilder: () => _ownVsPartnerGame(
          ownProvinces: 8,
          partnerProvinces: 9,
          partnerId: 'gp_blocker',
          invadableOwnerId: 'gp_blocker',
        ),
        snapshot: _ownSnapshot(
          oldWorldProvincesOwned: 8,
          atWarWith: const ['gp_blocker'],
          invadableProvinceIdsSorted: const ['oldWorld|frontier'],
        ),
        expectedPeace: isEmpty,
      ),
      _PeaceCase(
        label: 'collection guard: skips minors in atWarWith',
        gameBuilder: () => _ownVsPartnerGame(
          ownProvinces: 8,
          partnerProvinces: 12,
          partnerId: 'gp_enemy',
          minorId: 'minor1',
          atWarWithMinor: true,
        ),
        snapshot: _ownSnapshot(
          oldWorldProvincesOwned: 8,
          atWarWith: const ['gp_enemy', 'minor1'],
          invadableProvinceIdsSorted: const ['oldWorld|inv1'],
        ),
        expectedPeace: const ['gp_enemy'],
      ),
      _PeaceCase(
        label: 'collection guard: returns sorted GP targets that each '
            'meet the deficit',
        gameBuilder: () => _ownVsPartnerGame(
          ownProvinces: 6,
          partnerProvinces: 8,
          partnerId: 'gp_b',
          extraGpId: 'gp_a',
          extraGpProvinces: 9,
        ),
        snapshot: _ownSnapshot(
          oldWorldProvincesOwned: 6,
          atWarWith: const ['gp_a', 'gp_b'],
          invadableProvinceIdsSorted: const ['oldWorld|inv1'],
        ),
        expectedPeace: const ['gp_a', 'gp_b'],
        peaceReason:
            'Default-start minLeadDeficit=2: gp_b at +2 qualifies; gp_a at +3 '
            'qualifies; result must be sorted.',
      ),
      _PeaceCase(
        label: 'collection guard: omits GP that leads by less than '
            'minLeadDeficit',
        gameBuilder: () => _ownVsPartnerGame(
          ownProvinces: 8,
          partnerProvinces: 8,
          partnerId: 'gp_weak',
          extraGpId: 'gp_strong',
          extraGpProvinces: 10,
        ),
        snapshot: _ownSnapshot(
          oldWorldProvincesOwned: 8,
          atWarWith: const ['gp_weak', 'gp_strong'],
          invadableProvinceIdsSorted: const ['oldWorld|inv1'],
        ),
        expectedPeace: const ['gp_strong'],
      ),
    ],
  );
}
