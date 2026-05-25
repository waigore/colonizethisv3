// Pins the **critical OW hold peace** branch table at the
// `criticalOwHoldPeaceTargets` function boundary (Refs #2509 §
// `SPEC/ai/ai-architecture.md` § Diplomacy targeting — "when OW holdings
// are at or below `kFewOldWorldProvincesDefendThreshold` and any OW
// minor remains (peace all GP wars)").
//
// The function has the following decision points:
//
//   1. **At-war faction filter.** `snapshot.threats.atWarWith` is
//      filtered to factions where `game.playerById(...) != null` —
//      tribes and minors are skipped. When the filtered list is empty
//      the helper returns `const []` immediately (no peace targets to
//      emit even if OW holdings are critical).
//   2. **Own-OW critical band.** The helper fires only when
//      `isBelowObserverConquestQuota(ownOw)` (i.e. `ownOw < 10`) **and**
//      `ownOw <= kFewOldWorldProvincesDefendThreshold` (i.e. `ownOw <=
//      6`). Outside this band — at or above the observer quota, or
//      below the quota but above the defend threshold — the helper
//      returns `const []`.
//   3. **Sort determinism.** The returned list is `..sort()`-ed on
//      `factionId` so the downstream offer-peace pass observes a stable
//      order regardless of `atWarWith` iteration order.
//
// Sibling coverage that this file complements (but does not duplicate):
//
//   - `colonial_pressure_test.dart` contains a **single** happy-path
//     test (`'includes GP wars at exactly six OW provinces'`) that
//     covers the at-threshold fire path (`own == 6`) and the GP filter
//     against an empty atWarWith implicitly. **All other branches are
//     unpinned** prior to this file: the empty-after-filter shape, the
//     above-threshold-below-quota no-fire shape, the at-quota no-fire
//     shape, the strictly-below-threshold extreme fire shape, and the
//     ascending sort with multiple GP targets.
//   - `colonial_pressure_below_quota_peace_treasury_recovery_branches_test.dart`
//     and `colonial_pressure_below_quota_peace_insufficient_regiments_test.dart`
//     pin sibling below-quota peace families that share part of the
//     OW critical band; they do **not** read this helper.
//   - `diplomacy_planner_peace_targets.dart` invokes
//     `criticalOwHoldPeaceTargets` from two sites (the eligibility
//     guard and the peace-target stream). Both depend on the table
//     pinned here.
//
// What this file pins:
//
//   1. **At-war filter — empty after filter.** With `atWarWith`
//      containing only a minor (no GP) and `ownOw == 5` (well inside
//      the critical band), the helper must return `const []`. A
//      regression that dropped the `game.playerById(...) != null`
//      guard would silently leak a minor war into the GP-only peace
//      family and consume the offer-peace cap intended for GPs.
//   2. **Above-threshold-below-quota no-fire (`own == 7`).** With a
//      single GP at war and `ownOw == 7` (above the defend threshold
//      but still below the observer quota), the helper must return
//      `const []`. A regression that flipped `<=` to `<` on the
//      threshold would silently expand the critical-hold peace family
//      one province beyond the SPEC envelope and weaken the OW
//      conquest pressure the seed-42 observer gate requires.
//   3. **At-quota no-fire (`own == kObserverConquestMinOwProvincesPerGp`).**
//      With a single GP at war and `ownOw == 10`, the helper must
//      return `const []`. A regression that flipped `<` to `<=` on
//      `isBelowObserverConquestQuota` would silently engage critical-
//      hold peace exactly when the GP reached its observer quota.
//   4. **Strictly-below-threshold fire (`own == 5`).** With a single
//      GP at war and `ownOw == 5` (one province inside the defend
//      threshold), the helper must return `[gp_enemy]`. This pins the
//      strictly-`<` interior branch of the
//      `ownOw <= kFewOldWorldProvincesDefendThreshold` predicate so a
//      regression that narrowed the band (for example to `==`
//      threshold only) is caught.
//   5. **Sort determinism with multiple GP targets.** With two GP
//      enemies inserted into `atWarWith` in descending lexical order
//      (`gp_z` before `gp_a`) and `ownOw == 6`, the returned list must
//      be `['gp_a', 'gp_z']`. A regression that omitted `..sort()` or
//      iterated `atWarWith` directly would surface a stable but
//      input-dependent order downstream offer-peace scoring should not
//      depend on.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Builds a Game whose OW region contains the requested per-faction
/// province counts. Each entry of [provincesByOwner] becomes that many
/// `oldWorld|<owner>_<i>` provinces; ownership is the only OW signal
/// `criticalOwHoldPeaceTargets` reads (indirectly via `game.playerById`
/// for the at-war GP filter — the actual `ownOw` comes from the
/// snapshot, not the province count, so OW provinces here exist purely
/// to back the player roster and make the world shape realistic).
Game _buildGame({
  required Map<String, int> provincesByOwner,
  required List<Player> players,
  List<MinorNation> minorNations = const [],
}) {
  final provinces = <Province>[];
  provincesByOwner.forEach((owner, count) {
    for (var i = 0; i < count; i++) {
      provinces.add(
        Province(
          id: 'oldWorld|${owner}_$i',
          regionId: 'oldWorld',
          ownerId: owner,
        ),
      );
    }
  });
  return Game(
    id: 'g-critical-ow-hold-pin',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
      oldWorld: RegionData(provinces: provinces, units: const []),
      newWorld: const RegionData(provinces: [], units: []),
    ),
    players: players,
    minorNations: minorNations,
  );
}

AIWorldSnapshot _focusSnapshot({
  required int focusOw,
  required List<String> atWarWith,
}) {
  return AIWorldSnapshot(
    playerId: 'focus',
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(oldWorldProvincesOwned: focusOw),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

void main() {
  group('criticalOwHoldPeaceTargets — at-war filter', () {
    test('returns const [] when atWarWith contains only a minor', () {
      final game = _buildGame(
        provincesByOwner: const {'focus': 5},
        players: const [
          Player(id: 'focus', displayName: 'Focus', isHuman: false),
        ],
        minorNations: const [MinorNation(id: 'minor_a', displayName: 'M')],
      );
      final snapshot = _focusSnapshot(focusOw: 5, atWarWith: const ['minor_a']);

      expect(
        criticalOwHoldPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Minors are not part of the GP-only critical-hold peace family. '
            'Even with `ownOw == 5` well inside the defend threshold the '
            'helper must short-circuit when `game.playerById(...) != null` '
            'filters the at-war list to empty. A regression that dropped '
            'the GP filter would sweep a minor war into the GP peace cap '
            'reserved for the survival-peace family.',
      );
    });
  });

  group('criticalOwHoldPeaceTargets — own-OW critical band', () {
    test('returns const [] above the defend threshold but below quota '
        '(own == kFewOldWorldProvincesDefendThreshold + 1)', () {
      final game = _buildGame(
        provincesByOwner: const {'focus': 7, 'gp_enemy': 6},
        players: const [
          Player(id: 'focus', displayName: 'Focus', isHuman: false),
          Player(id: 'gp_enemy', displayName: 'E', isHuman: false),
        ],
      );
      final snapshot = _focusSnapshot(
        focusOw: kFewOldWorldProvincesDefendThreshold + 1,
        atWarWith: const ['gp_enemy'],
      );

      expect(
        criticalOwHoldPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Above kFewOldWorldProvincesDefendThreshold (6) the helper '
            'must NOT fire even while still below the observer quota. A '
            'regression that flipped `<=` to `<` on the threshold check '
            'would silently widen the critical-hold peace band to OW 7 '
            'and trade away conquest pressure inside the seed-42 turn-100 '
            'gate window.',
      );
    });

    test('returns const [] at the observer quota '
        '(own == kObserverConquestMinOwProvincesPerGp)', () {
      final game = _buildGame(
        provincesByOwner: const {'focus': 10, 'gp_enemy': 6},
        players: const [
          Player(id: 'focus', displayName: 'Focus', isHuman: false),
          Player(id: 'gp_enemy', displayName: 'E', isHuman: false),
        ],
      );
      final snapshot = _focusSnapshot(
        focusOw: kObserverConquestMinOwProvincesPerGp,
        atWarWith: const ['gp_enemy'],
      );

      expect(
        criticalOwHoldPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'At kObserverConquestMinOwProvincesPerGp (10) the GP has met '
            'the observer quota and `isBelowObserverConquestQuota` is '
            'false. The helper must return const []. A regression that '
            'flipped `<` to `<=` inside `isBelowObserverConquestQuota` '
            'would silently engage critical-hold peace exactly when the '
            'observer turn-100 gate clears.',
      );
    });

    test('fires toward a sole GP enemy strictly below the defend threshold '
        '(own == kFewOldWorldProvincesDefendThreshold - 1)', () {
      final game = _buildGame(
        provincesByOwner: const {'focus': 5, 'gp_enemy': 10},
        players: const [
          Player(id: 'focus', displayName: 'Focus', isHuman: false),
          Player(id: 'gp_enemy', displayName: 'E', isHuman: false),
        ],
      );
      final snapshot = _focusSnapshot(
        focusOw: kFewOldWorldProvincesDefendThreshold - 1,
        atWarWith: const ['gp_enemy'],
      );

      expect(
        criticalOwHoldPeaceTargets(game: game, snapshot: snapshot),
        ['gp_enemy'],
        reason:
            'Strictly below kFewOldWorldProvincesDefendThreshold (6) with '
            'a sole GP enemy at war the helper must surface that enemy '
            'as a peace target so the survival-peace family fires. This '
            'pins the interior `<` branch of the band so a regression '
            'that narrowed the band to exactly the threshold value is '
            'caught.',
      );
    });
  });

  group('criticalOwHoldPeaceTargets — sort determinism', () {
    test('returns ascending factionId order when atWarWith lists GP enemies '
        'in descending lexical order', () {
      final game = _buildGame(
        provincesByOwner: const {'focus': 6, 'gp_a': 6, 'gp_z': 6},
        players: const [
          Player(id: 'focus', displayName: 'Focus', isHuman: false),
          Player(id: 'gp_a', displayName: 'A', isHuman: false),
          Player(id: 'gp_z', displayName: 'Z', isHuman: false),
        ],
      );
      // Insert 'gp_z' first so the unsorted view would surface gp_z
      // before gp_a downstream; the helper must ..sort() the result.
      final snapshot = _focusSnapshot(
        focusOw: kFewOldWorldProvincesDefendThreshold,
        atWarWith: const ['gp_z', 'gp_a'],
      );

      expect(
        criticalOwHoldPeaceTargets(game: game, snapshot: snapshot),
        ['gp_a', 'gp_z'],
        reason:
            'The returned list is `..sort()`-ed so downstream offer-peace '
            'scoring observes a stable order regardless of the iteration '
            'order of `snapshot.threats.atWarWith`. A regression that '
            'omitted `..sort()` (or iterated atWarWith directly) would '
            'leak input ordering into the diplomacy pass and break '
            'deterministic ordering (Refs #2509 must-have #7).',
      );
    });
  });
}
