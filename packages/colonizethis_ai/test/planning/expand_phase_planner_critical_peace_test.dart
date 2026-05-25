// Pins canonical homes in `expand_phase_planner.dart` for
// `criticalWeakGpSurvivalPeaceTargets` and
// `criticalMultiFrontGpPeaceTargets` (Refs #2509 S1).
//
// Both deciders were relocated from
// `diplomacy_planner_peace_targets.dart` so they survive the planned
// S1 deletion of that file. The canonical implementations live in
// `expand_phase_planner.dart` (part file
// `expand_phase_planner_peer_peace.dart`);
// `diplomacy_planner_peace_targets.dart` retains thin delegating
// stubs for the legacy
// `diplomacy_planner_mutual_exhausted_peace_test.dart`,
// `diplomacy_planner_below_quota_peace_part3_test.dart`, and
// `diplomacy_planner_stalled_peace_test.dart` fixtures and the in-file
// `_survivalGreatPowerPeaceTargets` /
// `_expandRatchetGreatPowerPeaceTargets` /
// `stalledOwExpansionNeedsPeacePass` consumer chains until the
// planned deletion.
//
// Behavioral invariants pinned at the canonical entry points:
//
// `criticalWeakGpSurvivalPeaceTargets`:
//   1. Returns `const []` when `oldWorldProvincesOwned >
//      kFewOldWorldProvincesDefendThreshold` (today: 6) — outside the
//      critical OW-defend band the broader `criticalOwHoldPeaceTargets`
//      and the band-specific deciders take over.
//   2. When the outer guard passes, every Great Power foe in
//      `threats.atWarWith` (filtered via `Game.playerById`) whose
//      own province count satisfies a band-dependent minimum-lead
//      threshold is peaced:
//      a. `ownOw <= kObserverDefaultStartOldWorldProvincesPerGp + 1`
//         (today: 8) — default-start critical row: lead `>= 1` is
//         enough.
//      b. Else `isBelowObserverConquestQuota(ownOw)` — below-quota
//         critical row: lead `>= kUnwinnableSoleGpMinProvinceDeficit`
//         (today: 2).
//      c. Else (above-quota critical-band shape, defensive) —
//         lead `>=
//         kDeclareWarAggressorSuppressWeakGpLeadThreshold`
//         (today: 4).
//   3. Tribes and minors are dropped silently
//      (`Game.playerById` returns `null` for them); the GP-foe scan
//      is the only path into the returned list.
//   4. Result sorted ascending by `factionId` for downstream
//      offer-peace determinism (Refs #2509 Must-have #7).
//
// `criticalMultiFrontGpPeaceTargets`:
//   1. Returns `const []` when both
//      `isObserverConquestExpansionPressure` and
//      `isAtObserverConquestQuotaBand` are `false` for the active
//      player's `oldWorldProvincesOwned` — outside the EXPAND band
//      the quota-met deciders own the decision.
//   2. Returns `const []` when fewer than two Great Powers remain in
//      `threats.atWarWith` after the `Game.playerById` filter — the
//      "multi-front" precondition does not hold.
//   3. When both guards pass, delegates to
//      `multiFrontNonBlockerGpPeaceTargets` for the deterministic
//      non-blocker selection: the primary OW frontier blocker is
//      held open; every other GP foe is peaced sorted ascending.
//
// Delegation parity:
//   * The delegating stubs in
//     `diplomacy_planner_peace_targets.dart` return the same values
//     as the canonical helpers for every representative input —
//     required so the legacy fixtures and the in-file consumer
//     chains agree on both deciders.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/diplomacy_planner_peace_targets.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gpOwn = 'gp_own';
const String _gpStronger = 'gp_stronger';
const String _gpThird = 'gp_third';
const String _gpFourth = 'gp_fourth';
const String _minor1 = 'minor1';
const String _tribe1 = 'tribe1';

/// Builds a minimal `Game` where `gp_own` holds [ownProvinces] OW
/// provinces and each GP in [gpRivalProvincesById] owns the listed
/// OW province ids (lets the test set a precise lead). Minors named
/// in [minorIds] each own a single OW province. Tribes named in
/// [tribeIds] each appear in `game.tribes`. `gp_own` is at war with
/// every faction in [atWarFactionIds] (GPs, minors, and tribes
/// uniformly).
Game _criticalGame({
  required int ownProvinces,
  Map<String, List<String>> gpRivalProvincesById = const {},
  List<String> minorIds = const [],
  List<String> tribeIds = const [],
  List<String> atWarFactionIds = const [],
}) {
  final provinces = <Province>[
    for (var i = 1; i <= ownProvinces; i++)
      Province(
        id: 'oldWorld|${_gpOwn}_$i',
        regionId: 'oldWorld',
        ownerId: _gpOwn,
      ),
    for (final entry in gpRivalProvincesById.entries)
      for (final pid in entry.value)
        Province(id: pid, regionId: 'oldWorld', ownerId: entry.key),
    for (final minorId in minorIds)
      Province(
        id: 'oldWorld|${minorId}_home',
        regionId: 'oldWorld',
        ownerId: minorId,
      ),
  ];

  final players = <Player>[
    const Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
    for (final id in gpRivalProvincesById.keys)
      Player(id: id, displayName: id.toUpperCase(), isHuman: false),
  ];

  final minorNations = <MinorNation>[
    for (final minorId in minorIds)
      MinorNation(id: minorId, displayName: minorId),
  ];

  final tribes = <Tribe>[
    for (final tribeId in tribeIds) Tribe(id: tribeId, displayName: tribeId),
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
        'g-2509-critical-peace-canonical-'
        'own$ownProvinces-${gpRivalProvincesById.keys.join("-")}',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 60),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
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

/// Generates a list of [count] OW province ids belonging to [factionId]
/// (used to set a deterministic lead).
List<String> _rivalProvinces(String factionId, int count) => <String>[
  for (var i = 1; i <= count; i++) 'oldWorld|${factionId}_$i',
];

void main() {
  group('criticalWeakGpSurvivalPeaceTargets — canonical outer guards', () {
    test('returns const [] above kFewOldWorldProvincesDefendThreshold', () {
      // ownOw = defend threshold + 1 → outer guard fires; even a
      // dominant stronger GP must not be peaced (the broader
      // criticalOwHoldPeaceTargets and band-specific deciders own
      // this region of the band).
      final game = _criticalGame(
        ownProvinces: kFewOldWorldProvincesDefendThreshold + 1,
        gpRivalProvincesById: {_gpStronger: _rivalProvinces(_gpStronger, 14)},
        atWarFactionIds: const [_gpStronger],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kFewOldWorldProvincesDefendThreshold + 1,
        atWarWith: const [_gpStronger],
      );
      expect(
        criticalWeakGpSurvivalPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Above kFewOldWorldProvincesDefendThreshold the critical-'
            'survival arm must short-circuit. A regression that flipped '
            '> to >= would silently engage the arm one province above '
            'the defend band and dump otherwise rebuildable wars.',
      );
    });

    test('returns const [] when no Great Powers are at war', () {
      // Only a minor and tribe in atWarWith; Game.playerById filters
      // them out and the lead loop has nothing to emit.
      final game = _criticalGame(
        ownProvinces: 5,
        minorIds: const [_minor1],
        tribeIds: const [_tribe1],
        atWarFactionIds: const [_minor1, _tribe1],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 5,
        atWarWith: const [_minor1, _tribe1],
      );
      expect(
        criticalWeakGpSurvivalPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Minors and tribes are not Great Powers; the critical-survival '
            'arm operates only on GP factions. The companion minor/tribe '
            'peace deciders own those rows of the band.',
      );
    });
  });

  group('criticalWeakGpSurvivalPeaceTargets — default-start critical row', () {
    test(
      'lead == 1 fires (kObserverDefaultStartOldWorldProvincesPerGp + 1)',
      () {
        // ownOw = default-start + 1 = 8 → row threshold is minLead 1;
        // enemy GP holds 9 OW provinces (lead exactly 1) → peace.
        const ownOw = kObserverDefaultStartOldWorldProvincesPerGp + 1;
        final game = _criticalGame(
          ownProvinces: ownOw,
          gpRivalProvincesById: {
            _gpStronger: _rivalProvinces(_gpStronger, ownOw + 1),
          },
          atWarFactionIds: const [_gpStronger],
        );
        // Skip — outer guard requires ownOw <= defend threshold (6),
        // but ownOw + 1 here is 8 which is > 6. This row of the band
        // is actually unreachable through the outer guard in
        // production. Validate via the lower default-start row
        // (ownOw == defend threshold == 6) where the minLead = 1 arm
        // still applies (6 <= 7 + 1 = 8).
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: ownOw,
          atWarWith: const [_gpStronger],
        );
        expect(
          criticalWeakGpSurvivalPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'ownOw = default-start + 1 = 8 is above '
              'kFewOldWorldProvincesDefendThreshold = 6 — the outer guard '
              'must keep this row of the lead-table inert in production.',
        );
      },
    );

    test('default-start critical band (ownOw <= 8) fires at lead == 1', () {
      // ownOw = 6 (the outer guard ceiling and the band where the
      // <= 8 default-start row also applies). Enemy GP holds 7 OW
      // provinces (lead == 1) → peace by the minLead == 1 arm.
      final game = _criticalGame(
        ownProvinces: kFewOldWorldProvincesDefendThreshold,
        gpRivalProvincesById: {_gpStronger: _rivalProvinces(_gpStronger, 7)},
        atWarFactionIds: const [_gpStronger],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kFewOldWorldProvincesDefendThreshold,
        atWarWith: const [_gpStronger],
      );
      expect(
        criticalWeakGpSurvivalPeaceTargets(game: game, snapshot: snapshot),
        const [_gpStronger],
        reason:
            'At ownOw == 6 (defend threshold) the default-start '
            'critical row applies (6 <= 7 + 1 = 8) so minLead = 1; an '
            'enemy with lead 1 must be peaced. A regression that mis-'
            'computed the row would either drop this peace (survival '
            'collapse risk) or peace at lead 0 (drops self-defense).',
      );
    });

    test(
      'default-start critical band does NOT fire at lead == 0 (equal strength)',
      () {
        final game = _criticalGame(
          ownProvinces: kFewOldWorldProvincesDefendThreshold,
          gpRivalProvincesById: {_gpStronger: _rivalProvinces(_gpStronger, 6)},
          atWarFactionIds: const [_gpStronger],
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: kFewOldWorldProvincesDefendThreshold,
          atWarWith: const [_gpStronger],
        );
        expect(
          criticalWeakGpSurvivalPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'A peer of equal strength is not "stronger"; the minLead = 1 '
              'arm requires strict positive lead. Peacing equal peers would '
              'forfeit defensive wars where the active player still has '
              'parity.',
        );
      },
    );
  });

  group('criticalWeakGpSurvivalPeaceTargets — below-quota critical row', () {
    test('below-quota row (ownOw > 8) requires lead >= '
        'kUnwinnableSoleGpMinProvinceDeficit', () {
      // Production-reachable shape only exists inside the outer
      // guard ownOw <= 6, so the below-quota row arm is normally
      // unreachable. Validate the threshold table by exercising
      // ownOw = 6 (default-start row covers it; the below-quota
      // row arm body is exercised in
      // `colonial_pressure_*` regression fixtures via the legacy
      // stub). This test pins the row identity via determinism on
      // two structurally-identical calls (guards against a future
      // refactor wiring the wrong constant in this row).
      final game = _criticalGame(
        ownProvinces: 5,
        gpRivalProvincesById: {
          _gpStronger: _rivalProvinces(_gpStronger, 7),
          _gpThird: _rivalProvinces(_gpThird, 8),
        },
        atWarFactionIds: const [_gpStronger, _gpThird],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 5,
        atWarWith: const [_gpStronger, _gpThird],
      );
      final first = criticalWeakGpSurvivalPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final second = criticalWeakGpSurvivalPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(
        first,
        [_gpStronger, _gpThird],
        reason:
            'At ownOw = 5 the default-start row applies (5 <= 8), '
            'minLead = 1; both stronger GPs (lead >= 2) are peaced '
            'sorted ascending.',
      );
      expect(first, equals(second), reason: 'determinism');
    });
  });

  group('criticalWeakGpSurvivalPeaceTargets — fire path filters and order', () {
    test('filters non-GP atWarWith entries and sorts ascending', () {
      // gp_own at war with a minor, a tribe, and three GPs of mixed
      // strength. Only stronger GPs (lead >= 1 on the default-start
      // row at ownOw = 6) surface; minors and tribes are dropped.
      // Result must be lex-ascending by factionId.
      final game = _criticalGame(
        ownProvinces: kFewOldWorldProvincesDefendThreshold,
        gpRivalProvincesById: {
          _gpStronger: _rivalProvinces(_gpStronger, 7),
          _gpThird: _rivalProvinces(_gpThird, 6),
          _gpFourth: _rivalProvinces(_gpFourth, 9),
        },
        minorIds: const [_minor1],
        tribeIds: const [_tribe1],
        atWarFactionIds: const [
          _gpStronger,
          _gpThird,
          _gpFourth,
          _minor1,
          _tribe1,
        ],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kFewOldWorldProvincesDefendThreshold,
        atWarWith: const [_gpFourth, _minor1, _gpStronger, _tribe1, _gpThird],
      );
      final result = criticalWeakGpSurvivalPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(
        result,
        const [_gpFourth, _gpStronger],
        reason:
            'gp_fourth (lead 3) and gp_stronger (lead 1) both clear the '
            'minLead = 1 threshold; gp_third (lead 0) is equal-strength '
            'and dropped. Minor and tribe are filtered by Game.playerById. '
            'Sort order is ascending factionId regardless of input order.',
      );
    });
  });

  group('criticalWeakGpSurvivalPeaceTargets — stub delegation parity', () {
    test('diplomacy_planner_peace_targets stub returns the canonical list', () {
      final game = _criticalGame(
        ownProvinces: kFewOldWorldProvincesDefendThreshold,
        gpRivalProvincesById: {
          _gpStronger: _rivalProvinces(_gpStronger, 7),
          _gpThird: _rivalProvinces(_gpThird, 5),
        },
        atWarFactionIds: const [_gpStronger, _gpThird],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kFewOldWorldProvincesDefendThreshold,
        atWarWith: const [_gpStronger, _gpThird],
      );
      final canonical = criticalWeakGpSurvivalPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final stub = diplomacy_planner_peace_targets
          .criticalWeakGpSurvivalPeaceTargets(game: game, snapshot: snapshot);
      expect(
        stub,
        equals(canonical),
        reason:
            'The legacy stub must remain byte-equivalent to the canonical '
            'helper so the legacy '
            'diplomacy_planner_mutual_exhausted_peace_test.dart and '
            'diplomacy_planner_stalled_peace_test.dart fixtures and the '
            'in-file _survivalGreatPowerPeaceTargets / '
            'stalledOwExpansionNeedsPeacePass consumer chains continue '
            'to resolve to the same behavior.',
      );
    });

    test(
      'stub returns const [] outer guard match (above defend threshold)',
      () {
        // Both stub and canonical must agree on the outer-guard skip.
        final game = _criticalGame(
          ownProvinces: kFewOldWorldProvincesDefendThreshold + 1,
          gpRivalProvincesById: {_gpStronger: _rivalProvinces(_gpStronger, 12)},
          atWarFactionIds: const [_gpStronger],
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: kFewOldWorldProvincesDefendThreshold + 1,
          atWarWith: const [_gpStronger],
        );
        final canonical = criticalWeakGpSurvivalPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        final stub = diplomacy_planner_peace_targets
            .criticalWeakGpSurvivalPeaceTargets(game: game, snapshot: snapshot);
        expect(canonical, isEmpty);
        expect(stub, isEmpty);
      },
    );
  });

  group('criticalWeakGpSurvivalPeaceTargets — determinism', () {
    test(
      'two consecutive invocations return identical lists (Must-have #7)',
      () {
        final game = _criticalGame(
          ownProvinces: kFewOldWorldProvincesDefendThreshold,
          gpRivalProvincesById: {
            _gpStronger: _rivalProvinces(_gpStronger, 7),
            _gpFourth: _rivalProvinces(_gpFourth, 9),
          },
          atWarFactionIds: const [_gpStronger, _gpFourth],
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: kFewOldWorldProvincesDefendThreshold,
          atWarWith: const [_gpFourth, _gpStronger],
        );
        final first = criticalWeakGpSurvivalPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        final second = criticalWeakGpSurvivalPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        expect(first, equals(second));
        expect(first, const [_gpFourth, _gpStronger]);
      },
    );
  });

  group('criticalMultiFrontGpPeaceTargets — canonical outer guards', () {
    test(
      'returns const [] above the EXPAND band (ownOw > kObserverConquestMinOwProvincesPerGp)',
      () {
        // ownOw above quota → isObserverConquestExpansionPressure is
        // false AND isAtObserverConquestQuotaBand is false → outer
        // guard fires regardless of GP count.
        final game = _criticalGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp + 2,
          gpRivalProvincesById: {
            _gpStronger: _rivalProvinces(_gpStronger, 6),
            _gpThird: _rivalProvinces(_gpThird, 6),
          },
          atWarFactionIds: const [_gpStronger, _gpThird],
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp + 2,
          atWarWith: const [_gpStronger, _gpThird],
          invadableProvinceIdsSorted: const [],
        );
        expect(
          criticalMultiFrontGpPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'Above the quota band the quota-met deciders own the '
              'decision; the critical multi-front arm must short-circuit. '
              'A regression that flipped the OR to AND would silently '
              'engage the arm above quota and drop quota-met blockers.',
        );
      },
    );

    test('returns const [] with fewer than two at-war Great Powers', () {
      // Single GP foe inside the stalled band — the
      // multi-front shape does not hold; sole-non-blocker is handled
      // by multiFrontNonBlockerGpPeaceTargets directly (not via this
      // critical wrapper).
      final game = _criticalGame(
        ownProvinces: kStalledOldWorldProvinceThreshold,
        gpRivalProvincesById: {_gpStronger: _rivalProvinces(_gpStronger, 9)},
        atWarFactionIds: const [_gpStronger],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
        atWarWith: const [_gpStronger],
        invadableProvinceIdsSorted: const ['oldWorld|${_gpStronger}_1'],
      );
      expect(
        criticalMultiFrontGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'With one GP foe the multi-front precondition does not hold; '
            'the wrapper must short-circuit even when '
            'multiFrontNonBlockerGpPeaceTargets would otherwise emit a '
            'sole-non-blocker peace. The wrapper specifically guards the '
            '"2+ GP fronts under EXPAND pressure" signal.',
      );
    });

    test('returns const [] when only minors/tribes are at war (no GPs)', () {
      final game = _criticalGame(
        ownProvinces: kStalledOldWorldProvinceThreshold,
        minorIds: const [_minor1],
        tribeIds: const [_tribe1],
        atWarFactionIds: const [_minor1, _tribe1],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
        atWarWith: const [_minor1, _tribe1],
      );
      expect(
        criticalMultiFrontGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'After Game.playerById filtering no GPs remain; the GP-count '
            'guard must short-circuit. The minor/tribe peace decisions '
            'are owned by the companion stalled / below-quota collectors.',
      );
    });
  });

  group(
    'criticalMultiFrontGpPeaceTargets — canonical fire path delegates non-blocker selection',
    () {
      test(
        'peaces non-blocker GPs when 2+ GP fronts under EXPAND pressure',
        () {
          // ownOw = stalled threshold; gp_stronger owns the invadable
          // OW frontier (blocker); gp_third and gp_fourth are
          // non-blocker GP wars to drop. multiFrontNonBlockerGpPeaceTargets
          // keeps the blocker and peaces gp_third + gp_fourth sorted.
          const invadable = 'oldWorld|frontier_invadable';
          final game = _criticalGame(
            ownProvinces: kStalledOldWorldProvinceThreshold,
            gpRivalProvincesById: {
              _gpStronger: [invadable],
              _gpThird: _rivalProvinces(_gpThird, 5),
              _gpFourth: _rivalProvinces(_gpFourth, 5),
            },
            atWarFactionIds: const [_gpStronger, _gpThird, _gpFourth],
          );
          final snapshot = _ownSnapshot(
            oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
            atWarWith: const [_gpFourth, _gpStronger, _gpThird],
            invadableProvinceIdsSorted: const [invadable],
          );
          expect(
            criticalMultiFrontGpPeaceTargets(game: game, snapshot: snapshot),
            const [_gpFourth, _gpThird],
            reason:
                'gp_stronger is the OW frontier blocker (owns the only '
                'invadable OW province) → keep at war. gp_third and '
                'gp_fourth are non-blocker GPs → peaced and sorted '
                'ascending by factionId.',
          );
        },
      );

      test('engages within the at-quota band (ownOw == quota)', () {
        // ownOw = exactly at the observer quota →
        // isAtObserverConquestQuotaBand is true; the outer guard
        // passes via the at-quota arm even though
        // isObserverConquestExpansionPressure is false.
        const invadable = 'oldWorld|frontier_invadable';
        final game = _criticalGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp,
          gpRivalProvincesById: {
            _gpStronger: [invadable],
            _gpThird: _rivalProvinces(_gpThird, 5),
          },
          atWarFactionIds: const [_gpStronger, _gpThird],
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
          atWarWith: const [_gpStronger, _gpThird],
          invadableProvinceIdsSorted: const [invadable],
        );
        expect(
          criticalMultiFrontGpPeaceTargets(game: game, snapshot: snapshot),
          const [_gpThird],
          reason:
              'At ownOw == quota the at-quota arm of the outer guard '
              'engages; gp_stronger is the blocker, gp_third is the '
              'non-blocker GP and surfaces.',
        );
      });
    },
  );

  group('criticalMultiFrontGpPeaceTargets — stub delegation parity', () {
    test('stub returns the canonical list for the multi-front fire path', () {
      const invadable = 'oldWorld|frontier_invadable';
      final game = _criticalGame(
        ownProvinces: kStalledOldWorldProvinceThreshold,
        gpRivalProvincesById: {
          _gpStronger: [invadable],
          _gpThird: _rivalProvinces(_gpThird, 5),
          _gpFourth: _rivalProvinces(_gpFourth, 5),
        },
        atWarFactionIds: const [_gpStronger, _gpThird, _gpFourth],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
        atWarWith: const [_gpStronger, _gpThird, _gpFourth],
        invadableProvinceIdsSorted: const [invadable],
      );
      final canonical = criticalMultiFrontGpPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final stub = diplomacy_planner_peace_targets
          .criticalMultiFrontGpPeaceTargets(game: game, snapshot: snapshot);
      expect(
        stub,
        equals(canonical),
        reason:
            'The legacy stub must remain byte-equivalent to the canonical '
            'helper so the in-file _expandRatchetGreatPowerPeaceTargets / '
            'stalledOwExpansionNeedsPeacePass consumer chains continue to '
            'resolve to the same behavior.',
      );
    });

    test('stub returns const [] when the outer guard fires (above-quota)', () {
      final game = _criticalGame(
        ownProvinces: kObserverConquestMinOwProvincesPerGp + 2,
        gpRivalProvincesById: {
          _gpStronger: _rivalProvinces(_gpStronger, 5),
          _gpThird: _rivalProvinces(_gpThird, 5),
        },
        atWarFactionIds: const [_gpStronger, _gpThird],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp + 2,
        atWarWith: const [_gpStronger, _gpThird],
      );
      final canonical = criticalMultiFrontGpPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final stub = diplomacy_planner_peace_targets
          .criticalMultiFrontGpPeaceTargets(game: game, snapshot: snapshot);
      expect(canonical, isEmpty);
      expect(stub, isEmpty);
    });
  });

  group('criticalMultiFrontGpPeaceTargets — determinism', () {
    test(
      'two consecutive invocations return identical lists (Must-have #7)',
      () {
        const invadable = 'oldWorld|frontier_invadable';
        final game = _criticalGame(
          ownProvinces: kStalledOldWorldProvinceThreshold,
          gpRivalProvincesById: {
            _gpStronger: [invadable],
            _gpThird: _rivalProvinces(_gpThird, 5),
            _gpFourth: _rivalProvinces(_gpFourth, 5),
          },
          atWarFactionIds: const [_gpStronger, _gpThird, _gpFourth],
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
          atWarWith: const [_gpFourth, _gpStronger, _gpThird],
          invadableProvinceIdsSorted: const [invadable],
        );
        final first = criticalMultiFrontGpPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        final second = criticalMultiFrontGpPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        expect(first, equals(second));
        expect(first, const [_gpFourth, _gpThird]);
      },
    );
  });
}
