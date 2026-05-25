// Pins the canonical home in `expand_phase_planner.dart` for the
// EXPAND-phase critical-collapse and zero-regiment survival peace
// aggregator `survivalGreatPowerPeaceTargets` (Refs #2509 S1).
//
// The aggregator was relocated from the previously private
// `_survivalGreatPowerPeaceTargets` in
// `diplomacy_planner_peace_targets.dart` so it survives the planned
// S1 deletion of that file. The canonical implementation lives in
// `expand_phase_planner.dart` alongside the five canonicalized
// survival deciders it composes; `diplomacy_planner_peace_targets.dart`
// retains a thin private `_survivalGreatPowerPeaceTargets` delegating
// stub forwarding into the canonical aggregator so the in-file
// `collectStalledGreatPowerPeaceTargets` consumer chain resolves to
// the same target stream until the planned deletion.
//
// Sibling deciders the aggregator fans across (each already pinned by
// its own canonical-home suite — this file only pins the aggregator
// composition, not the sub-decider semantics):
//
//   1. `criticalWeakGpSurvivalPeaceTargets` — band-dependent
//      stronger-GP peace at `oldWorldProvincesOwned <=
//      kFewOldWorldProvincesDefendThreshold`. Sibling pin:
//      `expand_phase_planner_critical_peace_test.dart`.
//   2. `stalledZeroRegimentAllFactionPeaceTargets` — peace every
//      at-war minor/tribe when stalled below quota with zero
//      regiments. Sibling pin:
//      `expand_phase_planner_zero_regiment_gp_peace_test.dart` covers
//      the GP arm; the all-faction arm is exercised here as part of
//      the order pin.
//   3. `mutualZeroRegimentGpStalematePeaceTargets` — peace a sole GP
//      enemy when both sides have zero regiments. Sibling pin:
//      `expand_phase_planner_zero_regiment_gp_peace_test.dart`.
//   4. `stalledZeroRegimentGpPeaceTargets` — peace every at-war Great
//      Power when stalled with zero regiments. Sibling pin:
//      `expand_phase_planner_zero_regiment_gp_peace_test.dart`.
//   5. `mutualExhaustedBelowQuotaGpStalematePeaceTargets` — peace the
//      sole at-war GP when both sides are mutual-plateau peers below
//      quota and mutually exhausted. Sibling pin:
//      `expand_phase_planner_survival_multi_front_peace_test.dart`.
//
// Behavioral invariants pinned at the canonical entry point:
//
//   1. Empty iterable on a pristine `(Game, AIWorldSnapshot)` with no
//      at-war factions and no enemy GP / minor / tribe provinces — a
//      regression that incorrectly composed the sub-deciders (for
//      example yielded a sentinel before the first short-circuit
//      check) would surface immediately at the aggregator boundary
//      without needing every sub-decider's own pristine guard test
//      to flip first.
//   2. Single-fire path: when only the critical-survival arm fires
//      under a stronger-GP fixture inside the defend band, the
//      aggregator yields exactly the stronger-GP `factionId` and
//      nothing else.
//   3. Single-fire path: when only the zero-regiment all-faction arm
//      fires under a zero-regiment + at-war-minor fixture, the
//      aggregator yields exactly the minor `factionId` and nothing
//      else.
//   4. Yield-order pin: when both the critical-survival arm and the
//      zero-regiment all-faction arm fire on the same input, the
//      `criticalWeakGpSurvivalPeaceTargets` yield precedes the
//      `stalledZeroRegimentAllFactionPeaceTargets` yield in the
//      aggregator's iteration order. The yield-order pin guards the
//      `LinkedHashSet` insertion-order contract that
//      `collectStalledGreatPowerPeaceTargets` relies on when it
//      merges the aggregator output into its public peace-target
//      set.
//   5. Must-have #7 determinism: identical inputs produce identical
//      output across repeated invocations (pinned via
//      `.toList()` materialisation of the `Iterable` so the
//      `sync*` generator is re-driven from scratch on each call).

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gpOwn = 'gp_own';
const String _gpStronger = 'gp_stronger';
const String _minor1 = 'minor1';

/// Builds a minimal `Game` where:
///
///   * `gp_own` owns [ownProvinces] OW provinces plus a home province.
///   * If [enemyGpId] is non-null, that GP owns [enemyOwProvinces] OW
///     provinces plus a home province (so the GP exists via
///     `game.playerById` and the lead-table arms of
///     `criticalWeakGpSurvivalPeaceTargets` can compute a deterministic
///     lead).
///   * If [minorId] is non-null, that minor owns one OW province (so
///     it routes through the
///     `stalledZeroRegimentAllFactionPeaceTargets` minor/tribe arm
///     when at war).
///   * `gp_own`'s home army carries [ownRegimentCount] regiments;
///     each enemy GP's home army carries [enemyRegimentCount]
///     regiments. `0` exercises the zero-regiment guard arms.
///   * Diplomacy: `gp_own` is at war with every faction in
///     [atWarFactionIds].
Game _survivalGame({
  required int ownProvinces,
  required int ownRegimentCount,
  String? enemyGpId,
  int enemyOwProvinces = 0,
  int enemyRegimentCount = 0,
  String? minorId,
  List<String> atWarFactionIds = const [],
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
    if (enemyGpId != null) ...[
      Province(
        id: 'oldWorld|${enemyGpId}_home',
        regionId: 'oldWorld',
        ownerId: enemyGpId,
      ),
      for (var i = 1; i <= enemyOwProvinces; i++)
        Province(
          id: 'oldWorld|${enemyGpId}_$i',
          regionId: 'oldWorld',
          ownerId: enemyGpId,
        ),
    ],
    if (minorId != null)
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
    if (enemyGpId != null)
      Army(
        id: homeArmyIdFor(enemyGpId),
        ownerId: enemyGpId,
        regionId: 'oldWorld',
        stationedProvinceId: 'oldWorld|${enemyGpId}_home',
        regimentUnitIds: List<String>.unmodifiable(
          List<String>.generate(
            enemyRegimentCount,
            (i) => 'u_${enemyGpId}_${i + 1}',
          ),
        ),
        isHomeArmy: true,
      ),
  ];

  final players = <Player>[
    const Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
    if (enemyGpId != null)
      Player(
        id: enemyGpId,
        displayName: enemyGpId.toUpperCase(),
        isHuman: false,
      ),
  ];

  final minorNations = <MinorNation>[
    if (minorId != null) MinorNation(id: minorId, displayName: minorId),
  ];

  final relations = <DiplomacyRelation>[
    for (final id in atWarFactionIds)
      DiplomacyRelation(
        factionId1: _gpOwn,
        factionId2: id,
        state: RelationState.atWar,
        score: 30,
      ),
  ];

  return Game(
    id:
        'g-2509-survival-aggregator-canonical-'
        'own${ownProvinces}_${ownRegimentCount}_'
        'enemy${enemyGpId ?? 'none'}_${enemyOwProvinces}_${enemyRegimentCount}_'
        'minor${minorId ?? 'none'}',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
      armies: armies,
    ),
    players: players,
    minorNations: minorNations,
    tribes: const [],
    diplomacyRelations: relations,
  );
}

AIWorldSnapshot _ownSnapshot({
  required int oldWorldProvincesOwned,
  required List<String> atWarWith,
  List<String> invadableProvinceIdsSorted = const [],
}) {
  return AIWorldSnapshot(
    playerId: _gpOwn,
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

void main() {
  group('survivalGreatPowerPeaceTargets — canonical home', () {
    test('pristine state — every sub-decider short-circuits to empty', () {
      // ownOw above kStalledOldWorldProvinceThreshold so the
      // zero-regiment arms cannot engage; no at-war factions so the
      // critical-survival and mutual-stalemate arms also cannot
      // engage. The aggregator must therefore yield nothing.
      final game = _survivalGame(ownProvinces: 9, ownRegimentCount: 2);
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold + 1,
        atWarWith: const [],
      );
      expect(
        survivalGreatPowerPeaceTargets(game: game, snapshot: snapshot).toList(),
        isEmpty,
        reason:
            'A pristine state with no at-war factions and no zero-'
            'regiment / critical-band shape must trigger zero peace '
            'yields. A regression that emitted before the first '
            'sub-decider short-circuit (for example a stray yield in '
            'sync*) would surface here without any sub-decider pin '
            'needing to flip first.',
      );
    });

    test('critical-survival single fire — yields only the stronger GP', () {
      // ownOw = 6 (kFewOldWorldProvincesDefendThreshold) is inside the
      // critical-survival defend band and the default-start row
      // applies (6 <= kObserverDefaultStartOldWorldProvincesPerGp + 1
      // = 8) so minLead = 1. Enemy GP holds 7 OW (lead == 1) →
      // criticalWeakGpSurvivalPeaceTargets yields [_gpStronger]. Both
      // sides carry 1 regiment so the zero-regiment arms must not
      // engage; no minors / tribes at war so the
      // stalledZeroRegimentAllFactionPeaceTargets arm is also empty.
      final game = _survivalGame(
        ownProvinces: kFewOldWorldProvincesDefendThreshold - 1,
        ownRegimentCount: 1,
        enemyGpId: _gpStronger,
        enemyOwProvinces: 6,
        enemyRegimentCount: 1,
        atWarFactionIds: const [_gpStronger],
      );
      expect(
        survivalGreatPowerPeaceTargets(
          game: game,
          snapshot: _ownSnapshot(
            oldWorldProvincesOwned: kFewOldWorldProvincesDefendThreshold,
            atWarWith: const [_gpStronger],
          ),
        ).toList(),
        const [_gpStronger],
        reason:
            'criticalWeakGpSurvivalPeaceTargets must be the only '
            'sub-decider that fires when both sides hold 1 regiment '
            'and ownOw is inside the defend band with a stronger GP '
            'foe. A regression that wired the wrong constant into the '
            'lead table or omitted the critical-survival yield from '
            'the aggregator would change this output.',
      );
    });

    test('zero-regiment all-faction single fire — yields only the minor', () {
      // ownOw = 6 in the stalled band (6 <=
      // kStalledOldWorldProvinceThreshold = 9) and own carries zero
      // regiments. minor1 is at war and owns an invadable OW
      // province. No GPs at war — neither the critical-survival arm
      // nor any of the GP zero-regiment / mutual-exhausted arms can
      // fire. stalledZeroRegimentAllFactionPeaceTargets is the only
      // arm that yields, returning [_minor1].
      final game = _survivalGame(
        ownProvinces: 5,
        ownRegimentCount: 0,
        minorId: _minor1,
        atWarFactionIds: const [_minor1],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 6,
        atWarWith: const [_minor1],
        invadableProvinceIdsSorted: const ['oldWorld|${_minor1}_home'],
      );
      expect(
        survivalGreatPowerPeaceTargets(game: game, snapshot: snapshot).toList(),
        const [_minor1],
        reason:
            'stalledZeroRegimentAllFactionPeaceTargets must be the '
            'only sub-decider that fires when own is zero-regiment '
            'in the stalled band with an at-war minor on an '
            'invadable frontier and no GPs in atWarWith. A regression '
            'that dropped the zero-regiment all-faction yield from '
            'the aggregator (or swapped it for the GP arm) would '
            'change this output.',
      );
    });

    test('yield-order pin — critical-survival precedes zero-regiment '
        'all-faction', () {
      // Both arms fire on the same input:
      //   * ownOw = 6 (defend band ceiling) with own at 0 regiments.
      //   * Enemy GP at 7 OW with 0 regiments → critical-survival
      //     yields [_gpStronger] (default-start row, lead 1 >= 1).
      //   * Minor1 at war owning an invadable OW province → zero-
      //     regiment all-faction yields [_minor1].
      //
      // We assert that gp_stronger's index in the materialised list
      // is strictly less than minor1's index; this pins the yield
      // ordering through the LinkedHashSet insertion contract that
      // collectStalledGreatPowerPeaceTargets relies on.
      final game = _survivalGame(
        ownProvinces: kFewOldWorldProvincesDefendThreshold - 1,
        ownRegimentCount: 0,
        enemyGpId: _gpStronger,
        enemyOwProvinces: 6,
        enemyRegimentCount: 0,
        minorId: _minor1,
        atWarFactionIds: const [_gpStronger, _minor1],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kFewOldWorldProvincesDefendThreshold,
        atWarWith: const [_gpStronger, _minor1],
        invadableProvinceIdsSorted: const ['oldWorld|${_minor1}_home'],
      );
      final yielded = survivalGreatPowerPeaceTargets(
        game: game,
        snapshot: snapshot,
      ).toList();
      expect(
        yielded,
        containsAll(const [_gpStronger, _minor1]),
        reason:
            'Both sub-deciders must fire on this fixture; otherwise '
            'the order pin below is vacuous. If a sub-decider stopped '
            'firing here, audit the canonical helper that owns that '
            'arm first.',
      );
      final strongerFirstIndex = yielded.indexOf(_gpStronger);
      final minorFirstIndex = yielded.indexOf(_minor1);
      expect(
        strongerFirstIndex,
        lessThan(minorFirstIndex),
        reason:
            'The aggregator must yield criticalWeakGpSurvivalPeaceTargets '
            'before stalledZeroRegimentAllFactionPeaceTargets. Reordering '
            'the yield* sequence in the canonical body would break the '
            'LinkedHashSet insertion order that '
            'collectStalledGreatPowerPeaceTargets relies on for its '
            'public peace-target set iteration order.',
      );
    });

    test(
      'Must-have #7 determinism — identical inputs yield identical lists',
      () {
        final game = _survivalGame(
          ownProvinces: kFewOldWorldProvincesDefendThreshold - 1,
          ownRegimentCount: 0,
          enemyGpId: _gpStronger,
          enemyOwProvinces: 6,
          enemyRegimentCount: 0,
          minorId: _minor1,
          atWarFactionIds: const [_gpStronger, _minor1],
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: kFewOldWorldProvincesDefendThreshold,
          atWarWith: const [_gpStronger, _minor1],
          invadableProvinceIdsSorted: const ['oldWorld|${_minor1}_home'],
        );
        final first = survivalGreatPowerPeaceTargets(
          game: game,
          snapshot: snapshot,
        ).toList();
        final second = survivalGreatPowerPeaceTargets(
          game: game,
          snapshot: snapshot,
        ).toList();
        expect(
          first,
          equals(second),
          reason:
              'Identical inputs must yield identical materialised '
              'iterables across consecutive calls (Refs #2509 Must-have '
              '#7). The Iterable is a sync* generator so each call '
              're-drives the sub-deciders from scratch; both runs must '
              'see the same composition.',
        );
      },
    );
  });
}
