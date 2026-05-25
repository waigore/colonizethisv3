// Pins canonical homes in `expand_phase_planner.dart` for
// `stalledZeroRegimentAllFactionPeaceTargets`,
// `stalledZeroRegimentGpPeaceTargets`,
// `mutualZeroRegimentGpStalematePeaceTargets`,
// `mutualExhaustedBelowQuotaGpStalematePeaceTargets`, and
// `multiFrontNonBlockerGpPeaceTargets` (Refs #2509 S1). Also covers
// `stalledZeroRegimentGpPeaceTargets` and
// `mutualZeroRegimentGpStalematePeaceTargets` EXPAND-phase zero-regiment
// survival peace deciders at their new home in `expand_phase_planner.dart`
// (Refs #2509 S1).
//
// Both deciders were relocated from `diplomacy_planner_peace_targets.dart`
// so they survive the planned S1 deletion of that file. The canonical
// implementations live in `expand_phase_planner.dart`;
// `diplomacy_planner_peace_targets.dart` retains thin delegating stubs
// for the legacy `diplomacy_planner_below_quota_peace_part3_test.dart`
// § "all GP wars when stalled" fixture and the in-file
// `_survivalGreatPowerPeaceTargets` /
// `collectStalledGreatPowerPeaceTargets` `zeroRegimentBlockerPeace` /
// `stalledOwExpansionNeedsPeacePass` consumer chains until the planned
// deletion.
//
// Live consumers (post-relocation):
//   * `stalledZeroRegimentGpPeaceTargets` is the broad EXPAND
//     zero-regiment rebuild shortcut from
//     `SPEC/ai/ai-architecture.md` § Diplomacy targeting — "when
//     stalled below quota with zero regiments, peace every at-war
//     Great Power so rebuild is not blocked by futile fronts". It
//     peaces every at-war GP once the active player is inside the
//     stalled OW band and holds zero standing regiments, sorted
//     ascending by `factionId` for downstream offer-peace
//     determinism.
//   * `mutualZeroRegimentGpStalematePeaceTargets` is the sole-GP
//     mutual-stalemate carve-out. It peaces the lone GP enemy when
//     both sides have zero standing regiments and the active player
//     is stalled — the only path that exits an army-exhausted GP-only
//     frontier where the broader `stalledZeroRegimentGpPeaceTargets`
//     arm is overridden by the `collectStalledGreatPowerPeaceTargets`
//     GP-only-frontier carve-out re-adding the canonical OW frontier
//     blocker to the keep-at-war set.
//
// Sibling test coverage that this file complements (but does not duplicate):
//
//   * `diplomacy_planner_below_quota_peace_part3_test.dart` § "all GP
//     wars when stalled" exercises the broader arm through the legacy
//     `diplomacy_planner_peace_targets.dart` entry point and pins the
//     "filters minors out of GP results" invariant. Both legacy
//     fixtures depend on the delegating stubs and continue to pass
//     unchanged after the canonical bodies relocated here.
//   * `domain_planner_orchestrator_*_two_gp_peace_test.dart` exercise
//     the deciders through the orchestrator's `runDiplomacyPlanner`
//     pass under EXPAND / COLONIAL / DEVELOP phases. Those flows rely
//     on the same post-delegation return values pinned here.
//
// Behavioral invariants pinned at the canonical entry points:
//
//   1. `stalledZeroRegimentGpPeaceTargets` short-circuits to `const []`
//      when the active player's `oldWorldProvincesOwned` exceeds
//      `kStalledOldWorldProvinceThreshold` — outside the stalled band
//      the rebuild-peace arm does not engage.
//   2. `stalledZeroRegimentGpPeaceTargets` short-circuits to `const []`
//      when the active player still holds at least one standing
//      regiment — the rebuild-peace arm is a zero-regiment shortcut.
//   3. `stalledZeroRegimentGpPeaceTargets` filters minors and tribes
//      from `threats.atWarWith` so only Great Powers appear in the
//      returned list; the companion `stalledZeroRegimentAllFactionPeaceTargets`
//      owns the minor/tribe arm.
//   4. `stalledZeroRegimentGpPeaceTargets` sorts the GP list ascending
//      so the downstream offer-peace pass observes a stable order
//      regardless of the iteration order of `threats.atWarWith`.
//   5. `mutualZeroRegimentGpStalematePeaceTargets` short-circuits to
//      `const []` when the active player's `oldWorldProvincesOwned`
//      is outside the stalled band, when the active player still has
//      at least one standing regiment, when the GP-war set is empty,
//      when the GP-war set has 2+ entries (multi-front shape handled
//      by `multiFrontNonBlockerGpPeaceTargets`), or when the sole GP
//      enemy still has at least one standing regiment.
//   6. `mutualZeroRegimentGpStalematePeaceTargets` returns the
//      single-element list with the lone GP enemy's `factionId` when
//      all guards pass.
//   7. The delegating stubs in `diplomacy_planner_peace_targets.dart`
//      return the same value as the canonical helpers for every
//      representative input — required so the legacy fixtures and the
//      in-file consumer paths agree on the deciders.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/diplomacy_planner_peace_targets.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gpOwn = 'gp_own';
const String _gpEnemy = 'gp_enemy';
const String _gpThird = 'gp_third';
const String _minor1 = 'minor1';
const String _tribe1 = 'tribe1';

/// Builds a minimal `Game` where:
///
///   * `gp_own` owns [ownProvinces] OW provinces.
///   * The named enemy GPs in [enemyGpIds] each own a single OW
///     province (so they exist via `game.playerById`).
///   * Minors named in [minorIds] each own a single OW province (so
///     they appear in `game.minorNations` and route to the
///     `stalledZeroRegimentAllFactionPeaceTargets` minor/tribe arm
///     rather than this GP arm).
///   * Tribes named in [tribeIds] each appear in `game.tribes`.
///   * Each GP gets a home army; `gp_own`'s home army carries
///     [ownRegimentCount] regiments, each enemy GP's home army
///     carries [enemyRegimentCount] regiments. Both `ownRegimentCount`
///     and `enemyRegimentCount` may be `0` to exercise the
///     zero-regiment guard arms.
///   * Diplomacy: `gp_own` is at war with every enemy GP in
///     [enemyGpIds] (so the canonical helpers and the GP-war filter
///     see them), and at war with every minor / tribe id supplied in
///     [atWarMinorIds] / [atWarTribeIds].
Game _zeroRegimentGame({
  required int ownProvinces,
  required int ownRegimentCount,
  required List<String> enemyGpIds,
  required int enemyRegimentCount,
  List<String> minorIds = const [],
  List<String> tribeIds = const [],
  List<String> atWarMinorIds = const [],
  List<String> atWarTribeIds = const [],
}) {
  final provinces = <Province>[
    Province(
      id: 'oldWorld|${_gpOwn}_home',
      regionId: 'oldWorld',
      ownerId: _gpOwn,
    ),
    for (var i = 1; i <= ownProvinces; i++)
      Province(
        id: 'oldWorld|${_gpOwn}_$i',
        regionId: 'oldWorld',
        ownerId: _gpOwn,
      ),
    for (final enemyId in enemyGpIds)
      Province(
        id: 'oldWorld|${enemyId}_home',
        regionId: 'oldWorld',
        ownerId: enemyId,
      ),
    for (final minorId in minorIds)
      Province(
        id: 'oldWorld|${minorId}_home',
        regionId: 'oldWorld',
        ownerId: minorId,
      ),
  ];

  final armies = <Army>[
    Army(
      id: homeArmyIdFor(_gpOwn),
      ownerId: _gpOwn,
      regionId: 'oldWorld',
      stationedProvinceId: 'oldWorld|${_gpOwn}_home',
      regimentUnitIds: List<String>.unmodifiable(
        List<String>.generate(ownRegimentCount, (i) => 'u_${_gpOwn}_${i + 1}'),
      ),
      isHomeArmy: true,
    ),
    for (final enemyId in enemyGpIds)
      Army(
        id: homeArmyIdFor(enemyId),
        ownerId: enemyId,
        regionId: 'oldWorld',
        stationedProvinceId: 'oldWorld|${enemyId}_home',
        regimentUnitIds: List<String>.unmodifiable(
          List<String>.generate(
            enemyRegimentCount,
            (i) => 'u_${enemyId}_${i + 1}',
          ),
        ),
        isHomeArmy: true,
      ),
  ];

  final players = <Player>[
    const Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
    for (final enemyId in enemyGpIds)
      Player(id: enemyId, displayName: enemyId.toUpperCase(), isHuman: false),
  ];

  final minorNations = <MinorNation>[
    for (final minorId in minorIds)
      MinorNation(id: minorId, displayName: minorId),
  ];

  final tribes = <Tribe>[
    for (final tribeId in tribeIds) Tribe(id: tribeId, displayName: tribeId),
  ];

  final relations = <DiplomacyRelation>[
    for (final enemyId in enemyGpIds)
      DiplomacyRelation(
        factionId1: _gpOwn,
        factionId2: enemyId,
        state: RelationState.atWar,
        score: 30,
      ),
    for (final minorId in atWarMinorIds)
      DiplomacyRelation(
        factionId1: _gpOwn,
        factionId2: minorId,
        state: RelationState.atWar,
        score: 30,
      ),
    for (final tribeId in atWarTribeIds)
      DiplomacyRelation(
        factionId1: _gpOwn,
        factionId2: tribeId,
        state: RelationState.atWar,
        score: 30,
      ),
  ];

  return Game(
    id:
        'g-2509-zero-regiment-gp-peace-canonical-'
        '${ownProvinces}_${ownRegimentCount}_${enemyRegimentCount}_'
        '${enemyGpIds.join("-")}',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
      armies: armies,
    ),
    players: players,
    minorNations: minorNations,
    tribes: tribes,
    diplomacyRelations: relations,
  );
}

AIWorldSnapshot _ownSnapshot({
  required int oldWorldProvincesOwned,
  required List<String> atWarWith,
}) {
  return AIWorldSnapshot(
    playerId: _gpOwn,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(oldWorldProvincesOwned: oldWorldProvincesOwned),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

void main() {
  group('stalledZeroRegimentGpPeaceTargets — canonical outer guards', () {
    test('returns const [] when ownOw exceeds the stalled band '
        '(ownOw > kStalledOldWorldProvinceThreshold)', () {
      final game = _zeroRegimentGame(
        ownProvinces: kStalledOldWorldProvinceThreshold + 1,
        ownRegimentCount: 0,
        enemyGpIds: const [_gpEnemy],
        enemyRegimentCount: 0,
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold + 1,
        atWarWith: const [_gpEnemy],
      );
      expect(
        stalledZeroRegimentGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Above the stalled OW band the canonical helper must NOT '
            'engage the zero-regiment rebuild-peace arm even with zero '
            'standing regiments. The broader EXPAND deciders own this '
            'region of the band and a regression that widened the band '
            'would peace pressing-quota GPs that still hold rebuild-ready '
            'frontier wars.',
      );
    });

    test(
      'returns const [] when the active player has at least one regiment',
      () {
        final game = _zeroRegimentGame(
          ownProvinces: 6,
          ownRegimentCount: 1,
          enemyGpIds: const [_gpEnemy],
          enemyRegimentCount: 0,
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: 6,
          atWarWith: const [_gpEnemy],
        );
        expect(
          stalledZeroRegimentGpPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'With at least one standing regiment the planner can still '
              'press existing GP wars; the zero-regiment shortcut must not '
              'fire. A regression that flipped `> 0` to `>= 0` would peace '
              'every GP front at non-zero regiment counts and collapse '
              'EXPAND pressure.',
        );
      },
    );

    test('returns const [] when no Great Powers are at war', () {
      final game = _zeroRegimentGame(
        ownProvinces: 6,
        ownRegimentCount: 0,
        enemyGpIds: const [],
        enemyRegimentCount: 0,
        minorIds: const [_minor1],
        atWarMinorIds: const [_minor1],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 6,
        atWarWith: const [_minor1],
      );
      expect(
        stalledZeroRegimentGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Only a minor is in threats.atWarWith; `game.playerById(...)` '
            'filters it out and the canonical helper must return an empty '
            'list. The minor/tribe peace pivot is owned by the companion '
            'stalledZeroRegimentAllFactionPeaceTargets — a regression '
            'leaking the minor into this GP arm would double-count the '
            'minor across both decider families.',
      );
    });
  });

  group('stalledZeroRegimentGpPeaceTargets — canonical firing path', () {
    test('peaces all at-war Great Powers at the stalled boundary', () {
      final game = _zeroRegimentGame(
        ownProvinces: kStalledOldWorldProvinceThreshold,
        ownRegimentCount: 0,
        enemyGpIds: const [_gpEnemy],
        enemyRegimentCount: 0,
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
        atWarWith: const [_gpEnemy],
      );
      expect(
        stalledZeroRegimentGpPeaceTargets(game: game, snapshot: snapshot),
        [_gpEnemy],
        reason:
            'At the stalled boundary (ownOw == '
            'kStalledOldWorldProvinceThreshold) the canonical helper '
            'must fire when standing regiments == 0. The `<=` boundary '
            'belongs inside the stalled band; a regression that flipped '
            '`<=` to `<` would refuse to peace at the band ceiling where '
            'rebuild is most critical (seed-42 gp6 plateau).',
      );
    });

    test('filters minors and tribes out of the GP-only result', () {
      final game = _zeroRegimentGame(
        ownProvinces: 6,
        ownRegimentCount: 0,
        enemyGpIds: const [_gpEnemy],
        enemyRegimentCount: 0,
        minorIds: const [_minor1],
        tribeIds: const [_tribe1],
        atWarMinorIds: const [_minor1],
        atWarTribeIds: const [_tribe1],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 6,
        atWarWith: const [_minor1, _gpEnemy, _tribe1],
      );
      expect(
        stalledZeroRegimentGpPeaceTargets(game: game, snapshot: snapshot),
        [_gpEnemy],
        reason:
            'Only the Great Power must appear in the canonical result; '
            'minors and tribes route to the companion '
            'stalledZeroRegimentAllFactionPeaceTargets arm. A regression '
            'that dropped the `game.playerById(...) != null` filter would '
            'leak minors and tribes into the GP peace family.',
      );
    });

    test('sorts multiple Great Power enemies ascending regardless of '
        'atWarWith iteration order', () {
      final game = _zeroRegimentGame(
        ownProvinces: 6,
        ownRegimentCount: 0,
        enemyGpIds: const [_gpThird, _gpEnemy],
        enemyRegimentCount: 0,
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 6,
        atWarWith: const [_gpThird, _gpEnemy],
      );
      expect(
        stalledZeroRegimentGpPeaceTargets(game: game, snapshot: snapshot),
        [_gpEnemy, _gpThird],
        reason:
            'The canonical helper must `..sort()` the GP list so the '
            'downstream offer-peace pass observes a stable order '
            'regardless of the iteration order of threats.atWarWith. A '
            'regression that omitted the sort would leak iteration '
            'order into the diplomacy pass and break Refs #2509 '
            "Must-have #7 (determinism).",
      );
    });
  });

  group(
    'mutualZeroRegimentGpStalematePeaceTargets — canonical outer guards',
    () {
      test('returns const [] when ownOw exceeds the stalled band '
          '(ownOw > kStalledOldWorldProvinceThreshold)', () {
        final game = _zeroRegimentGame(
          ownProvinces: kStalledOldWorldProvinceThreshold + 1,
          ownRegimentCount: 0,
          enemyGpIds: const [_gpEnemy],
          enemyRegimentCount: 0,
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold + 1,
          atWarWith: const [_gpEnemy],
        );
        expect(
          mutualZeroRegimentGpStalematePeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          isEmpty,
          reason:
              'Outside the stalled band the mutual-stalemate reset must '
              'not engage even when both sides hold zero regiments. The '
              'broader EXPAND consolidate-gains decider owns the '
              'post-stalled band.',
        );
      });

      test(
        'returns const [] when the active player has at least one regiment',
        () {
          final game = _zeroRegimentGame(
            ownProvinces: 6,
            ownRegimentCount: 1,
            enemyGpIds: const [_gpEnemy],
            enemyRegimentCount: 0,
          );
          final snapshot = _ownSnapshot(
            oldWorldProvincesOwned: 6,
            atWarWith: const [_gpEnemy],
          );
          expect(
            mutualZeroRegimentGpStalematePeaceTargets(
              game: game,
              snapshot: snapshot,
            ),
            isEmpty,
            reason:
                'A non-zero standing regiment on the active player means '
                'the planner can still press the war; the mutual-stalemate '
                'reset is exclusively a zero-regiment carve-out.',
          );
        },
      );

      test('returns const [] when the sole at-war GP still has regiments', () {
        final game = _zeroRegimentGame(
          ownProvinces: 6,
          ownRegimentCount: 0,
          enemyGpIds: const [_gpEnemy],
          enemyRegimentCount: 2,
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: 6,
          atWarWith: const [_gpEnemy],
        );
        expect(
          mutualZeroRegimentGpStalematePeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          isEmpty,
          reason:
              'The mutual stalemate requires BOTH sides to be exhausted. '
              'Pins the enemy-regiment gate against a regression that '
              'collapsed the `mutualZeroRegimentGpStalemate` carve-out '
              'into the broader `stalledZeroRegimentGpPeaceTargets` arm.',
        );
      });

      test('returns const [] when no Great Power is at war', () {
        final game = _zeroRegimentGame(
          ownProvinces: 6,
          ownRegimentCount: 0,
          enemyGpIds: const [],
          enemyRegimentCount: 0,
          minorIds: const [_minor1],
          atWarMinorIds: const [_minor1],
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: 6,
          atWarWith: const [_minor1],
        );
        expect(
          mutualZeroRegimentGpStalematePeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          isEmpty,
          reason:
              'Zero GP wars cannot return a peace target — only minors / '
              'tribes are at war here so the canonical helper short-'
              'circuits without selecting a peace partner.',
        );
      });

      test('returns const [] when multiple Great Powers are at war', () {
        final game = _zeroRegimentGame(
          ownProvinces: 6,
          ownRegimentCount: 0,
          enemyGpIds: const [_gpEnemy, _gpThird],
          enemyRegimentCount: 0,
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: 6,
          atWarWith: const [_gpEnemy, _gpThird],
        );
        expect(
          mutualZeroRegimentGpStalematePeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          isEmpty,
          reason:
              'Multi-front shape (2+ GPs at war) is handled by '
              'multiFrontNonBlockerGpPeaceTargets — the sole-GP '
              'mutual-stalemate reset does not apply. A regression that '
              'dropped the `gpWars.length != 1` guard would double-peace '
              'across both decider families.',
        );
      });
    },
  );

  group(
    'mutualZeroRegimentGpStalematePeaceTargets — canonical firing path',
    () {
      test('peaces the sole GP enemy when both sides are exhausted', () {
        final game = _zeroRegimentGame(
          ownProvinces: kStalledOldWorldProvinceThreshold,
          ownRegimentCount: 0,
          enemyGpIds: const [_gpEnemy],
          enemyRegimentCount: 0,
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
          atWarWith: const [_gpEnemy],
        );
        expect(
          mutualZeroRegimentGpStalematePeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          [_gpEnemy],
          reason:
              'Both guards (own and enemy regiments == 0) + stalled '
              'band + exactly one GP war must peace the lone enemy. '
              'Pins the firing path so the carve-out can never be '
              'silently retired by an outer-guard refactor on the '
              'broader stalledZeroRegimentGpPeaceTargets arm.',
        );
      });

      test('still peaces when minors are also at war (GP-only filter keeps '
          'the carve-out tight on the lone GP enemy)', () {
        final game = _zeroRegimentGame(
          ownProvinces: kStalledOldWorldProvinceThreshold,
          ownRegimentCount: 0,
          enemyGpIds: const [_gpEnemy],
          enemyRegimentCount: 0,
          minorIds: const [_minor1],
          atWarMinorIds: const [_minor1],
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
          atWarWith: const [_minor1, _gpEnemy],
        );
        expect(
          mutualZeroRegimentGpStalematePeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          [_gpEnemy],
          reason:
              'The mutual-stalemate carve-out filters minors out of the '
              'GP-war set, so a co-belligerent minor at war does not '
              'switch the helper to the multi-front guard. A regression '
              'that counted minors in `gpWars.length` would silently '
              'abandon zero-regiment GPs trapped on mixed-frontier wars.',
        );
      });
    },
  );

  group('Determinism (Must-have #7)', () {
    test('stalledZeroRegimentGpPeaceTargets is byte-equivalent across '
        'two consecutive invocations on the same inputs', () {
      final game = _zeroRegimentGame(
        ownProvinces: 7,
        ownRegimentCount: 0,
        enemyGpIds: const [_gpThird, _gpEnemy],
        enemyRegimentCount: 0,
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [_gpThird, _gpEnemy],
      );
      final first = stalledZeroRegimentGpPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final second = stalledZeroRegimentGpPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(
        second,
        first,
        reason:
            'Pure-function determinism is Refs #2509 Must-have #7. '
            'Identical (Game, AIWorldSnapshot) inputs must return '
            'identical (and ascending-sorted) lists on every '
            'invocation; pinned independently of the firing-path '
            'expectations so a future regression that introduced a '
            'set-iteration leak would surface here.',
      );
    });

    test('mutualZeroRegimentGpStalematePeaceTargets is byte-equivalent '
        'across two consecutive invocations on the same inputs', () {
      final game = _zeroRegimentGame(
        ownProvinces: 7,
        ownRegimentCount: 0,
        enemyGpIds: const [_gpEnemy],
        enemyRegimentCount: 0,
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [_gpEnemy],
      );
      final first = mutualZeroRegimentGpStalematePeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final second = mutualZeroRegimentGpStalematePeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(second, first);
    });
  });

  group('Delegating stubs match canonical', () {
    test('diplomacy_planner_peace_targets.stalledZeroRegimentGpPeaceTargets '
        'matches canonical across band + filter + sort fixtures', () {
      // Pin delegator parity across: above-band guard, regiment-count
      // guard, firing path with multi-GP sort, and minor/tribe filter
      // path (only GP returned).
      final scenarios = <({Game game, AIWorldSnapshot snapshot})>[
        // 1. Above stalled band → const [].
        (
          game: _zeroRegimentGame(
            ownProvinces: kStalledOldWorldProvinceThreshold + 1,
            ownRegimentCount: 0,
            enemyGpIds: const [_gpEnemy],
            enemyRegimentCount: 0,
          ),
          snapshot: _ownSnapshot(
            oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold + 1,
            atWarWith: const [_gpEnemy],
          ),
        ),
        // 2. Active player still has regiments → const [].
        (
          game: _zeroRegimentGame(
            ownProvinces: 6,
            ownRegimentCount: 1,
            enemyGpIds: const [_gpEnemy],
            enemyRegimentCount: 0,
          ),
          snapshot: _ownSnapshot(
            oldWorldProvincesOwned: 6,
            atWarWith: const [_gpEnemy],
          ),
        ),
        // 3. Inside stalled band, zero regiments, multi-GP sort.
        (
          game: _zeroRegimentGame(
            ownProvinces: 6,
            ownRegimentCount: 0,
            enemyGpIds: const [_gpThird, _gpEnemy],
            enemyRegimentCount: 0,
          ),
          snapshot: _ownSnapshot(
            oldWorldProvincesOwned: 6,
            atWarWith: const [_gpThird, _gpEnemy],
          ),
        ),
        // 4. Minor / tribe filter — GP-only result.
        (
          game: _zeroRegimentGame(
            ownProvinces: 6,
            ownRegimentCount: 0,
            enemyGpIds: const [_gpEnemy],
            enemyRegimentCount: 0,
            minorIds: const [_minor1],
            tribeIds: const [_tribe1],
            atWarMinorIds: const [_minor1],
            atWarTribeIds: const [_tribe1],
          ),
          snapshot: _ownSnapshot(
            oldWorldProvincesOwned: 6,
            atWarWith: const [_minor1, _gpEnemy, _tribe1],
          ),
        ),
      ];
      for (final scenario in scenarios) {
        final canonical = stalledZeroRegimentGpPeaceTargets(
          game: scenario.game,
          snapshot: scenario.snapshot,
        );
        final delegated = diplomacy_planner_peace_targets
            .stalledZeroRegimentGpPeaceTargets(
              game: scenario.game,
              snapshot: scenario.snapshot,
            );
        expect(
          delegated,
          canonical,
          reason:
              'diplomacy_planner_peace_targets.stalledZeroRegimentGpPeaceTargets '
              'must agree with the canonical expand_phase_planner '
              'implementation across the band guard, regiment-count '
              'guard, the multi-GP sort firing path, and the '
              'minor/tribe filter — the delegating stub is the only '
              'live caller path the legacy diplomacy_planner_below_quota_peace_part3_test.dart '
              "fixture and the in-file _survivalGreatPowerPeaceTargets / "
              'collectStalledGreatPowerPeaceTargets / '
              'stalledOwExpansionNeedsPeacePass consumer chains '
              'reach until the planned S1 deletion of '
              'diplomacy_planner_peace_targets.dart.',
        );
      }
    });

    test(
      'diplomacy_planner_peace_targets.mutualZeroRegimentGpStalematePeaceTargets '
      'matches canonical across each outer guard + firing path',
      () {
        // Pin delegator parity across the outer guard table:
        //  1. Above stalled band → const [].
        //  2. Active player has regiments → const [].
        //  3. Enemy has regiments → const [].
        //  4. Zero GP wars → const [].
        //  5. Multi-GP wars → const [].
        //  6. Firing path: sole GP, both sides exhausted, stalled band.
        final scenarios = <({Game game, AIWorldSnapshot snapshot})>[
          (
            game: _zeroRegimentGame(
              ownProvinces: kStalledOldWorldProvinceThreshold + 1,
              ownRegimentCount: 0,
              enemyGpIds: const [_gpEnemy],
              enemyRegimentCount: 0,
            ),
            snapshot: _ownSnapshot(
              oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold + 1,
              atWarWith: const [_gpEnemy],
            ),
          ),
          (
            game: _zeroRegimentGame(
              ownProvinces: 6,
              ownRegimentCount: 1,
              enemyGpIds: const [_gpEnemy],
              enemyRegimentCount: 0,
            ),
            snapshot: _ownSnapshot(
              oldWorldProvincesOwned: 6,
              atWarWith: const [_gpEnemy],
            ),
          ),
          (
            game: _zeroRegimentGame(
              ownProvinces: 6,
              ownRegimentCount: 0,
              enemyGpIds: const [_gpEnemy],
              enemyRegimentCount: 2,
            ),
            snapshot: _ownSnapshot(
              oldWorldProvincesOwned: 6,
              atWarWith: const [_gpEnemy],
            ),
          ),
          (
            game: _zeroRegimentGame(
              ownProvinces: 6,
              ownRegimentCount: 0,
              enemyGpIds: const [],
              enemyRegimentCount: 0,
              minorIds: const [_minor1],
              atWarMinorIds: const [_minor1],
            ),
            snapshot: _ownSnapshot(
              oldWorldProvincesOwned: 6,
              atWarWith: const [_minor1],
            ),
          ),
          (
            game: _zeroRegimentGame(
              ownProvinces: 6,
              ownRegimentCount: 0,
              enemyGpIds: const [_gpEnemy, _gpThird],
              enemyRegimentCount: 0,
            ),
            snapshot: _ownSnapshot(
              oldWorldProvincesOwned: 6,
              atWarWith: const [_gpEnemy, _gpThird],
            ),
          ),
          (
            game: _zeroRegimentGame(
              ownProvinces: kStalledOldWorldProvinceThreshold,
              ownRegimentCount: 0,
              enemyGpIds: const [_gpEnemy],
              enemyRegimentCount: 0,
            ),
            snapshot: _ownSnapshot(
              oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
              atWarWith: const [_gpEnemy],
            ),
          ),
        ];
        for (final scenario in scenarios) {
          final canonical = mutualZeroRegimentGpStalematePeaceTargets(
            game: scenario.game,
            snapshot: scenario.snapshot,
          );
          final delegated = diplomacy_planner_peace_targets
              .mutualZeroRegimentGpStalematePeaceTargets(
                game: scenario.game,
                snapshot: scenario.snapshot,
              );
          expect(
            delegated,
            canonical,
            reason:
                'diplomacy_planner_peace_targets.mutualZeroRegimentGpStalematePeaceTargets '
                'must agree with the canonical expand_phase_planner '
                'implementation across the band guard, regiment guards '
                'for both sides, the multi-front guard, and the '
                'firing path — the delegating stub is the only live '
                'caller path the in-file _survivalGreatPowerPeaceTargets / '
                'collectStalledGreatPowerPeaceTargets / '
                'stalledOwExpansionNeedsPeacePass consumer chains '
                'reach until the planned S1 deletion of '
                'diplomacy_planner_peace_targets.dart.',
          );
        }
      },
    );
  });

  group('stalledZeroRegimentAllFactionPeaceTargets — canonical', () {
    test('peaces minors and tribes only when stalled with zero regiments', () {
      final game = _zeroRegimentGame(
        ownProvinces: 8,
        ownRegimentCount: 0,
        enemyGpIds: const [],
        enemyRegimentCount: 0,
        minorIds: const [_minor1],
        atWarMinorIds: const [_minor1, 'minor2'],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 8,
        atWarWith: const [_minor1, 'minor2'],
      );
      expect(
        stalledZeroRegimentAllFactionPeaceTargets(game: game, snapshot: snapshot),
        const [_minor1, 'minor2'],
      );
    });

    test('delegating stub matches canonical implementation', () {
      final game = _zeroRegimentGame(
        ownProvinces: 8,
        ownRegimentCount: 0,
        enemyGpIds: const [_gpEnemy],
        enemyRegimentCount: 0,
        atWarMinorIds: const [_minor1],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 8,
        atWarWith: const [_minor1, _gpEnemy],
      );
      expect(
        diplomacy_planner_peace_targets.stalledZeroRegimentAllFactionPeaceTargets(
          game: game,
          snapshot: snapshot,
        ),
        stalledZeroRegimentAllFactionPeaceTargets(game: game, snapshot: snapshot),
      );
    });
  });

  group('mutualExhaustedBelowQuotaGpStalematePeaceTargets — stub delegation', () {
    test('delegating stub matches canonical on exhausted-plateau fixture', () {
      final game = Game(
        id: 'g-mutual-exhausted-delegation',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 100),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 8; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
              for (var i = 1; i <= 9; i++)
                Province(
                  id: 'oldWorld|gp3_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
            ],
          ),
          newWorld: const RegionData(),
          armies: const [],
        ),
        players: const [
          Player(id: 'gp4', displayName: 'GP4', isHuman: false, treasury: 0),
          Player(id: 'gp3', displayName: 'GP3', isHuman: false, treasury: 0),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp4',
            factionId2: 'gp3',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp4',
        threats: ThreatSummary(atWarWith: ['gp3']),
        opportunities: const OpportunitySummary(),
        conquest: ConquestSummary(oldWorldProvincesOwned: 8),
        colonial: const ColonialSummary(),
        economy: const EconomySummary(),
        relations: const {},
      );
      expect(
        diplomacy_planner_peace_targets
            .mutualExhaustedBelowQuotaGpStalematePeaceTargets(
          game: game,
          snapshot: snapshot,
        ),
        mutualExhaustedBelowQuotaGpStalematePeaceTargets(
          game: game,
          snapshot: snapshot,
        ),
      );
      expect(
        mutualExhaustedBelowQuotaGpStalematePeaceTargets(
          game: game,
          snapshot: snapshot,
        ),
        ['gp3'],
      );
    });
  });

  group('multiFrontNonBlockerGpPeaceTargets — canonical', () {
    test('three GP wars peaces non-blocker GPs sorted', () {
      final game = Game(
        id: 'g-multi-front-canonical',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
          oldWorld: RegionData(
            provinces: const [
              Province(
                id: 'oldWorld|a',
                regionId: 'oldWorld',
                ownerId: 'gp4',
              ),
              Province(
                id: 'oldWorld|b',
                regionId: 'oldWorld',
                ownerId: 'gp1',
              ),
              Province(
                id: 'oldWorld|c',
                regionId: 'oldWorld',
                ownerId: 'gp2',
              ),
              Province(
                id: 'oldWorld|d',
                regionId: 'oldWorld',
                ownerId: 'gp3',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp4', displayName: 'GP4', isHuman: false),
          Player(id: 'gp1', displayName: 'GP1', isHuman: false),
          Player(id: 'gp2', displayName: 'GP2', isHuman: false),
          Player(id: 'gp3', displayName: 'GP3', isHuman: false),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp4',
            factionId2: 'gp1',
            state: RelationState.atWar,
            score: 30,
          ),
          DiplomacyRelation(
            factionId1: 'gp4',
            factionId2: 'gp2',
            state: RelationState.atWar,
            score: 30,
          ),
          DiplomacyRelation(
            factionId1: 'gp4',
            factionId2: 'gp3',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp4',
        threats: ThreatSummary(atWarWith: ['gp1', 'gp2', 'gp3']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 11,
          invadableProvinceIdsSorted: ['oldWorld|b', 'oldWorld|c', 'oldWorld|d'],
        ),
        economy: EconomySummary(),
        relations: const {},
      );
      final canonical = multiFrontNonBlockerGpPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(canonical.length, 2);
      expect(canonical, isNot(contains('gp1')));
      expect(
        diplomacy_planner_peace_targets.multiFrontNonBlockerGpPeaceTargets(
          game: game,
          snapshot: snapshot,
        ),
        canonical,
      );
    });
  });
}
