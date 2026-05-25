// Pins the EXPAND default-start Great-Power peace-targeting branches of
// `defaultStartGpPeaceTargets` from issue #2509 S10 at the function-unit
// boundary (Refs #2509).
//
//   SPEC/ai/ai-architecture.md § Observer goal phases (Full AI), EXPAND:
//     "default-start GP peace pivot: when a GP is at the observer
//     default-start size, peace every Great Power war so the GP can
//     open a minor frontier".
//
// The implementation in `colonial_pressure.dart`:
//
//   List<String> defaultStartGpPeaceTargets({
//     required Game game,
//     required AIWorldSnapshot snapshot,
//   }) {
//     final ownOw = snapshot.conquest.oldWorldProvincesOwned;
//     if (!isBelowObserverConquestQuota(ownOw)) return const [];
//     final maxOwForGpPeace = hasUninvadedOldWorldMinor(...)
//         ? kStalledOldWorldProvinceThreshold                 // 9
//         : kObserverDefaultStartOldWorldProvincesPerGp + 1;  // 8
//     if (ownOw > maxOwForGpPeace) return const [];
//     final gpOnlyFrontier = isOldWorldGpOnlyInvadableFrontier(...);
//     final invadableBlocker = gpOnlyFrontier
//         ? primaryInvadableOldWorldGpBlocker(...)
//         : null;
//     final targets = <String>[
//       for (final factionId in snapshot.threats.atWarWith)
//         if (game.playerById(factionId) != null &&
//             factionId != invadableBlocker)
//           factionId,
//     ]..sort();
//     return targets;
//   }
//
// The helper is consumed by `diplomacy_planner_peace_targets.dart` as one
// of the EXPAND-phase peace-target collectors that flows into
// `collectStalledGreatPowerPeaceTargets`. A single regression in this
// helper — for example dropping the quota guard, raising the
// `maxOwForGpPeace` ceiling without the minor-presence precondition, or
// silently leaving the blocker in the peace set on a GP-only frontier —
// would either pull a sole-front EXPAND GP out of its only winnable war
// (regressing the seed-42 turn-100 OW conquest gate) or hold a stalled
// GP-only frontier war while uninvaded minors remain (defeating the
// "open a minor frontier" pivot the rule was added for).
//
// Existing related coverage (not redundant with this pin):
//
//   - `colonial_pressure_test.dart` group `defaultStartGpPeaceTargets` —
//     pins **two** happy-path scenarios:
//       a) `peaces all GP wars at 7–8 OW below observer quota`
//          (single-GP `atWarWith`, no `invadableProvinceIdsSorted`,
//           returns the lone non-blocker GP).
//       b) `keeps invadable blocker war on GP-only frontier at default
//          start` (sole at-war GP owns the only invadable OW frontier
//          → `invadableBlocker` equals the only `atWarWith` entry →
//          returns empty).
//     It does **not** exercise the not-below-quota early return, the
//     `ownOw > maxOwForGpPeace` ceiling (with vs without uninvaded
//     minor), the multi-GP-at-war non-blocker preservation case, the
//     `!gpOnlyFrontier` branch (mixed minor + GP frontier → blocker
//     null → all GPs returned), the non-GP-faction filter on
//     `atWarWith`, the empty `atWarWith` short-circuit, the
//     deterministic ascending sort across a multi-GP roster, or
//     determinism of the helper itself.
//   - `diplomacy_planner_below_quota_peace_part2_test.dart` group
//     `nearQuotaHoldPeaceTargets` — pins a sibling helper with a
//     similar GP-only-frontier blocker rule but at a different OW
//     band (8–9 OW), so it cannot stand in for the default-start
//     7–8 OW window this helper governs.
//
// Coverage layers in this file:
//
//   - **Quota guard:** OW = `kObserverConquestMinOwProvincesPerGp` (10)
//     → not below quota → empty (the helper must not engage the
//     pivot once the GP is at quota or above; the EXPAND→COLONIAL
//     phase transition takes over from here).
//   - **`maxOwForGpPeace` ceiling without uninvaded minor:** OW = 9,
//     no minors on the map → `maxOwForGpPeace = 8` → `ownOw > maxOw`
//     → empty (the rule does not engage at OW=9 without a minor
//     because a minor pivot is the only justification for peace at
//     that OW; without one, hold the GP wars).
//   - **`maxOwForGpPeace` ceiling with uninvaded minor:** OW = 9,
//     uninvaded minor on the map → `maxOwForGpPeace = 9` → `ownOw <=
//     maxOw` → eligible → returns the lone non-blocker GP. A
//     regression that flipped the ceiling to the no-minor value
//     would silently hold every GP war at OW=9 even with a minor
//     pivot available.
//   - **`!gpOnlyFrontier`:** mixed minor + GP frontier (a minor owns
//     an invadable OW province) → `gpOnlyFrontier = false` →
//     `invadableBlocker = null` → **all** at-war GPs returned. The
//     blocker preservation rule only applies when the frontier is
//     entirely held by Great Powers; with a minor pivot still
//     available there is no GP frontier to preserve.
//   - **`gpOnlyFrontier` with multiple GPs at war:** only the
//     blocker is excluded; the remaining at-war GPs are returned in
//     ascending factionId order. Pinned because the existing
//     happy-path test exercises only the single-GP `atWarWith`
//     case, which cannot detect a regression that mistakenly
//     filtered every GP (or only the lowest-id GP) when multiple
//     fronts exist.
//   - **Non-GP factions in `atWarWith`:** tribes/minors must be
//     filtered out by the `game.playerById(factionId) != null`
//     guard before the sort — a regression that left them in the
//     output would feed a non-Great-Power id to downstream
//     `offerPeace` validation.
//   - **Empty `atWarWith`:** the helper must short-circuit to empty
//     without touching the blocker scan or sort.
//   - **Deterministic sort across a multi-GP `atWarWith` roster:**
//     the input list is supplied out of order and the result must
//     come back ascending (Refs #2509 must-have #7 determinism).
//   - **Repeat-call determinism:** identical inputs must produce
//     identical outputs across two consecutive calls (function-unit
//     determinism guard mirroring sibling pins).

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/colonial_pressure.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _gp4 = 'gp4';
const String _tribe1 = 'tribe1';
const String _minor1 = 'minor1';

/// Builds a fixture with the listed Old World provinces. Defaults provide a
/// 4-GP roster + 1 tribe so individual tests can flip ownership without
/// rewiring the roster. Tests that need an uninvaded minor pass an explicit
/// `minorNations` list (and either own at least one OW province with that
/// minor or rely on the existing province ownership).
Game _gameWithOwProvinces({
  required List<Province> owProvinces,
  List<Player> players = const [
    Player(id: _gp1, displayName: 'GP1', isHuman: false),
    Player(id: _gp2, displayName: 'GP2', isHuman: false),
    Player(id: _gp3, displayName: 'GP3', isHuman: false),
    Player(id: _gp4, displayName: 'GP4', isHuman: false),
  ],
  List<Tribe> tribes = const [Tribe(id: _tribe1, displayName: 'T1')],
  List<MinorNation> minorNations = const [],
}) {
  return Game(
    id: 'g-2509-default-start-gp-peace-branches',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 50, phase: TurnPhase.orders),
      oldWorld: RegionData(provinces: owProvinces),
      newWorld: const RegionData(),
    ),
    players: players,
    tribes: tribes,
    minorNations: minorNations,
  );
}

/// Snapshot for the planning GP `gp1`. Tests vary `oldWorldProvincesOwned`,
/// `atWarWith`, and `invadableProvinceIdsSorted` to exercise individual
/// branches.
AIWorldSnapshot _snapshot({
  required int oldWorldProvincesOwned,
  required List<String> atWarWith,
  List<String> invadableOw = const [],
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
  group('defaultStartGpPeaceTargets quota and ceiling guards', () {
    test('not below quota -> empty (OW = quota)', () {
      // OW at quota == `kObserverConquestMinOwProvincesPerGp` (10) is no
      // longer "below quota", so the helper short-circuits before the
      // ceiling / blocker / sort logic. A regression that dropped the
      // `!isBelowObserverConquestQuota` early return would peace GPs
      // post-quota during the EXPAND→COLONIAL handoff.
      final game = _gameWithOwProvinces(
        owProvinces: const [
          Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
        ],
      );
      final snapshot = _snapshot(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
        atWarWith: const [_gp2],
        invadableOw: const ['oldWorld|gp2_a'],
      );
      expect(
        defaultStartGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'At quota the EXPAND default-start pivot is no longer in scope; '
            'the helper must return empty so the COLONIAL/COLONIAL-lite '
            'peace rules govern post-quota wars.',
      );
    });

    test('ownOw above ceiling with no uninvaded minor -> empty', () {
      // OW = 9, no minors on the map → `maxOwForGpPeace =
      // kObserverDefaultStartOldWorldProvincesPerGp + 1` (8) → `ownOw > 8`
      // → empty. A regression that raised the ceiling to 9 without the
      // minor precondition would silently peace GPs at 9 OW with no minor
      // pivot available, defeating the rule's own justification.
      final game = _gameWithOwProvinces(
        owProvinces: const [
          Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
        ],
      );
      final snapshot = _snapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
        atWarWith: const [_gp2],
        invadableOw: const ['oldWorld|gp2_a'],
      );
      expect(
        defaultStartGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Without an uninvaded minor on the map the ceiling is 8 OW, '
            'so OW=9 must NOT engage the pivot — there is no minor front '
            'to pivot to.',
      );
    });

    test(
      'ownOw at ceiling WITH uninvaded minor -> non-blocker GPs returned',
      () {
        // OW = 9, uninvaded minor (m1) holds an OW province →
        // `hasUninvadedOldWorldMinor` true → ceiling = 9 → eligible. GP-only
        // frontier is **false** here because the only invadable OW (the
        // minor's province) is not GP-owned, so `invadableBlocker = null`
        // and every at-war GP is returned (single GP -> single entry).
        final game = _gameWithOwProvinces(
          owProvinces: const [
            Province(
              id: 'oldWorld|m1_a',
              regionId: 'oldWorld',
              ownerId: _minor1,
            ),
          ],
          minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
        );
        final snapshot = _snapshot(
          oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
          atWarWith: const [_gp2],
          invadableOw: const ['oldWorld|m1_a'],
        );
        expect(
          defaultStartGpPeaceTargets(game: game, snapshot: snapshot),
          const [_gp2],
          reason:
              'With an uninvaded minor on the map the ceiling extends to 9 '
              'OW and the lone non-blocker GP must be returned. A '
              'regression that kept the ceiling at 8 in this case would '
              'block the minor-frontier pivot the rule was added for.',
        );
      },
    );
  });

  group('defaultStartGpPeaceTargets blocker / frontier branches', () {
    test('!gpOnlyFrontier -> blocker null -> all GPs returned', () {
      // Mixed frontier: minor1 owns one invadable OW province, gp2 owns
      // another. `isOldWorldGpOnlyInvadableFrontier` is false because
      // a minor still holds an invadable OW (per its definition); so
      // `invadableBlocker = null` and **every** at-war GP appears in
      // the result. With OW=8 (default ceiling) the helper engages.
      final game = _gameWithOwProvinces(
        owProvinces: const [
          Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _snapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp + 1,
        atWarWith: const [_gp2, _gp3],
        invadableOw: const ['oldWorld|gp2_a', 'oldWorld|m1_a'],
      );
      expect(
        defaultStartGpPeaceTargets(game: game, snapshot: snapshot),
        const [_gp2, _gp3],
        reason:
            'When the frontier mixes GP and minor owners no GP qualifies '
            'as the blocker (the minor pivot is available), so every '
            'at-war GP is peaced in ascending factionId order.',
      );
    });

    test(
      'gpOnlyFrontier with multiple GPs at war -> only blocker excluded',
      () {
        // Pure GP frontier: gp2 owns the sole invadable OW; gp3 also at
        // war but owns nothing on the frontier. The helper must drop
        // gp2 (blocker) and return gp3.
        final game = _gameWithOwProvinces(
          owProvinces: const [
            Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
          ],
        );
        final snapshot = _snapshot(
          oldWorldProvincesOwned:
              kObserverDefaultStartOldWorldProvincesPerGp + 1,
          atWarWith: const [_gp2, _gp3],
          invadableOw: const ['oldWorld|gp2_a'],
        );
        expect(
          defaultStartGpPeaceTargets(game: game, snapshot: snapshot),
          const [_gp3],
          reason:
              'On a GP-only frontier the blocker (gp2) holds the only '
              'winnable OW front and must be preserved; remaining GP '
              'wars (gp3) are peaced.',
        );
      },
    );
  });

  group('defaultStartGpPeaceTargets atWarWith filter / sort', () {
    test('non-GP factions filtered out of returned list', () {
      // `atWarWith` mixes a tribe with a Great Power; the tribe must
      // be dropped because `game.playerById(tribe1) == null`. With no
      // GP-owned invadable OW the frontier is not GP-only, so gp2 is
      // returned without blocker exclusion.
      final game = _gameWithOwProvinces(
        owProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _snapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [_gp2, _tribe1],
        invadableOw: const ['oldWorld|m1_a'],
      );
      expect(
        defaultStartGpPeaceTargets(game: game, snapshot: snapshot),
        const [_gp2],
        reason:
            'Tribes and minors are not Great Powers; the helper is the '
            'GP arm of the EXPAND default-start peace pivot and must '
            'pass non-GP factions through to their own sibling helpers '
            '(e.g. `defaultStartFutileMinorPeaceTargets`).',
      );
    });

    test('empty atWarWith -> empty', () {
      // No active wars: the loop body never runs and the sort is a no-op.
      // Pinned to guard against a regression that returned a default
      // synthetic target (e.g. all GPs in the player roster) when
      // `atWarWith` is empty.
      final game = _gameWithOwProvinces(
        owProvinces: const [
          Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
        ],
      );
      final snapshot = _snapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [],
        invadableOw: const ['oldWorld|gp2_a'],
      );
      expect(
        defaultStartGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Empty `atWarWith` means there is nothing to peace, even at '
            'default start size — the helper must not synthesize new '
            'peace targets out of the player roster.',
      );
    });

    test('atWarWith returned in ascending factionId order', () {
      // Three GPs at war with the planning GP, supplied out of sorted
      // order. With no invadable OW (`gpOnlyFrontier = false` →
      // `invadableBlocker = null`) every GP appears in the result and
      // must come back ascending. Refs #2509 must-have #7 determinism.
      final game = _gameWithOwProvinces(
        owProvinces: const [
          Province(id: 'oldWorld|gp1_a', regionId: 'oldWorld', ownerId: _gp1),
        ],
      );
      final snapshot = _snapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [_gp4, _gp2, _gp3],
      );
      expect(
        defaultStartGpPeaceTargets(game: game, snapshot: snapshot),
        const [_gp2, _gp3, _gp4],
        reason:
            'The helper must sort returned faction ids ascending so '
            'downstream order generation is deterministic for a fixed '
            'seed. A regression that emitted insertion order would '
            'destabilize the merged turn-order set across runs.',
      );
    });
  });

  group('defaultStartGpPeaceTargets determinism', () {
    test('identical inputs produce identical peace target list', () {
      // Function-unit determinism guard mirroring sibling pins. The
      // multi-GP fixture exercises the player filter, blocker scan,
      // and sort, so repeating the call must yield the same list.
      final game = _gameWithOwProvinces(
        owProvinces: const [
          Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
        ],
      );
      final snapshot = _snapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [_gp2, _gp3, _gp4],
        invadableOw: const ['oldWorld|gp2_a'],
      );
      final first = defaultStartGpPeaceTargets(game: game, snapshot: snapshot);
      final second = defaultStartGpPeaceTargets(game: game, snapshot: snapshot);
      expect(second, first);
      expect(first, const [_gp3, _gp4]);
    });
  });
}
