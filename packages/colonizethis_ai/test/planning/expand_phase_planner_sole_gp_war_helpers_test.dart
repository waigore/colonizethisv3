// Pins the canonical `soleAtWarGreatPowerId` and
// `canPivotFromSoleGpWarAfterPeace` sole-GP-war helpers in
// `expand_phase_planner.dart` (Refs #2509 S1).
//
// Both helpers were relocated from `colonial_pressure.dart` so they survive
// the now-completed S1 deletion of that file. The canonical implementations
// live in `expand_phase_planner.dart`.
//
// Live consumers (post-relocation):
//   * `soleAtWarGreatPowerId` is consumed inside `expand_phase_planner.dart`
//     by `belowQuotaPeerGpPeaceTargets` (peer-stalled peace pivot fork),
//     `unwinnableSoleGpFrontierPeaceTarget` (below-quota outgunned sole-GP
//     peace), and `consolidateGainsSoleGpPeaceTarget` (quota-met
//     consolidate peace). All three short-circuit to the default
//     no-peace path when the helper returns `null`.
//   * `canPivotFromSoleGpWarAfterPeace` is consumed by
//     `unwinnableSoleGpFrontierPeaceTarget` as the pivot-availability gate
//     before returning a peace target id — peace is only worthwhile if
//     the active GP can immediately resume EXPAND against a minor rather
//     than idle while the lone GP rebuilds.
//
// Behavioral invariants pinned here (all deterministic — Must-have #7):
//
//   1. `soleAtWarGreatPowerId` returns `null` for an empty at-war list,
//      a minor-only at-war list, an unknown-faction-only at-war list, or
//      any list resolving to more than one Great Power after the
//      `playerById` filter.
//   2. `soleAtWarGreatPowerId` returns the lone Great Power id when
//      exactly one current Great Power remains after filtering; minor
//      and tribe ids in the same `atWarWith` list do not contribute to
//      the length count.
//   3. `canPivotFromSoleGpWarAfterPeace` returns `true` via the leading
//      `>=` short-circuit when the active player is at or above
//      [kObserverConquestMinOwProvincesPerGp] OW provinces (no longer
//      EXPAND territory).
//   4. `canPivotFromSoleGpWarAfterPeace` returns `true` via the
//      `minorsOnMap` arm when any OW province has a minor owner — even
//      when that minor is already in the active player's at-war set
//      (the helper does NOT filter by `snapshot.threats.atWarWith`; the
//      at-war filtering lives in higher-level peace collectors).
//   5. `canPivotFromSoleGpWarAfterPeace` returns `true` via the trailing
//      `any` arm when no OW minor exists but the invadable list contains
//      a province whose current owner is a minor (cross-region pivot —
//      typical of NW colonial minor frontiers when the active GP has
//      lost all OW minor neighbours).
//   6. `canPivotFromSoleGpWarAfterPeace` returns `false` only when the
//      active player is strictly below quota AND no minor owns any OW
//      province AND the invadable list contains no minor-owned
//      province. This is the EXPAND-trap deadlock the helper exists to
//      report.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _minor1 = 'minor1';
const String _tribe1 = 'tribe1';

Game _gameWithGpsAndMinors({
  List<String> playerIds = const [_gp1, _gp2, _gp3],
  List<String> minorIds = const [_minor1],
}) {
  return Game(
    id: 'g-2509-sole-gp-war-helpers-canonical',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 60, phase: TurnPhase.orders),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: [
      for (final id in playerIds)
        Player(id: id, displayName: id.toUpperCase(), isHuman: false),
    ],
    minorNations: [
      for (final id in minorIds) MinorNation(id: id, displayName: id),
    ],
  );
}

AIWorldSnapshot _snapshotAtWarWith(List<String> atWarWith) {
  return AIWorldSnapshot(
    playerId: _gp1,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

Game _gameWithProvinces({
  required List<Province> owProvinces,
  List<Province> nwProvinces = const [],
  List<MinorNation> minorNations = const [],
}) {
  return Game(
    id: 'g-2509-can-pivot-from-sole-gp-war-canonical',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 80, phase: TurnPhase.orders),
      oldWorld: RegionData(provinces: owProvinces),
      newWorld: RegionData(provinces: nwProvinces),
    ),
    players: const [
      Player(id: _gp1, displayName: 'GP1', isHuman: false),
      Player(id: _gp2, displayName: 'GP2', isHuman: false),
    ],
    minorNations: minorNations,
  );
}

AIWorldSnapshot _pivotSnapshotFor({
  required int oldWorldProvincesOwned,
  List<String> invadableProvinceIdsSorted = const [],
  List<String> atWarWith = const [_gp2],
}) {
  return AIWorldSnapshot(
    playerId: _gp1,
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

List<Province> _gp1OwProvinces(int count) {
  return [
    for (var i = 1; i <= count; i++)
      Province(id: 'oldWorld|gp1_$i', regionId: 'oldWorld', ownerId: _gp1),
  ];
}

void main() {
  group('soleAtWarGreatPowerId', () {
    test('returns null when at-war list is empty', () {
      final game = _gameWithGpsAndMinors();
      final snapshot = _snapshotAtWarWith(const []);
      expect(
        soleAtWarGreatPowerId(game: game, snapshot: snapshot),
        isNull,
        reason:
            'No active wars means no sole-GP foe; the predicate must '
            'short-circuit so the sole-GP peace deciders skip their '
            'candidate scans on peaceful turns.',
      );
    });

    test('returns null when at-war list contains only a minor', () {
      final game = _gameWithGpsAndMinors();
      final snapshot = _snapshotAtWarWith(const [_minor1]);
      expect(
        soleAtWarGreatPowerId(game: game, snapshot: snapshot),
        isNull,
        reason:
            'The `playerById` filter drops minor ids; a minor-only at-war '
            'list collapses the post-filter length to 0 and yields null. '
            'A regression that included minors would elect a non-GP foe.',
      );
    });

    test('returns null when at-war list contains only an unknown tribe id', () {
      final game = _gameWithGpsAndMinors(minorIds: const []);
      final snapshot = _snapshotAtWarWith(const [_tribe1]);
      expect(
        soleAtWarGreatPowerId(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Unknown faction ids (tribes / removed players) are filtered '
            'out by `playerById` so the canonical-home helper agrees with '
            'the EXPAND-phase peace deciders that only ever act on '
            'current Great Power ids.',
      );
    });

    test('returns the lone GP id when exactly one GP is at war', () {
      final game = _gameWithGpsAndMinors();
      final snapshot = _snapshotAtWarWith(const [_gp2]);
      expect(
        soleAtWarGreatPowerId(game: game, snapshot: snapshot),
        _gp2,
        reason:
            'The canonical sole-GP-foe happy path: a single Great Power '
            'entry in `atWarWith` resolves to a known player and the '
            'predicate returns that GP id.',
      );
    });

    test(
      'returns the lone GP id when the at-war list mixes one GP and a minor',
      () {
        final game = _gameWithGpsAndMinors();
        final snapshot = _snapshotAtWarWith(const [_gp2, _minor1]);
        expect(
          soleAtWarGreatPowerId(game: game, snapshot: snapshot),
          _gp2,
          reason:
              'Minor ids are filtered out before the length-one guard, so '
              'a GP + minor mix collapses to a one-element GP list and '
              'returns the GP. A regression that counted minors in the '
              'GP list would refuse to elect the GP whenever a concurrent '
              'minor war existed.',
        );
      },
    );

    test('returns null when two Great Powers are at war (length guard)', () {
      final game = _gameWithGpsAndMinors();
      final snapshot = _snapshotAtWarWith(const [_gp2, _gp3]);
      expect(
        soleAtWarGreatPowerId(game: game, snapshot: snapshot),
        isNull,
        reason:
            'The `length != 1` guard refuses to elect a sole-GP foe on a '
            'multi-front war turn. A regression that returned '
            '`gpWars.first` would peace the wrong GP and leave an '
            'unpinned blocker on the OW frontier (Refs #2509 turn-100 '
            'verify exit code 5).',
      );
    });

    test(
      'returns null when two GPs and a minor are at war (length guard + filter)',
      () {
        final game = _gameWithGpsAndMinors();
        final snapshot = _snapshotAtWarWith(const [_gp2, _gp3, _minor1]);
        expect(
          soleAtWarGreatPowerId(game: game, snapshot: snapshot),
          isNull,
          reason:
              'The minor filter must not collapse a two-GP war into a '
              'sole-GP-foe outcome; after filtering the minor, two GPs '
              'still remain and the length guard refuses to elect a foe.',
        );
      },
    );

    test('is deterministic across repeated calls (Must-have #7)', () {
      final game = _gameWithGpsAndMinors();
      final snapshot = _snapshotAtWarWith(const [_gp2, _minor1]);
      final first = soleAtWarGreatPowerId(game: game, snapshot: snapshot);
      final second = soleAtWarGreatPowerId(game: game, snapshot: snapshot);
      final third = soleAtWarGreatPowerId(game: game, snapshot: snapshot);
      expect(first, _gp2);
      expect(second, first);
      expect(third, first);
    });
  });

  group('canPivotFromSoleGpWarAfterPeace', () {
    test('returns true via the quota short-circuit with no minor pivot', () {
      final game = _gameWithProvinces(
        owProvinces: _gp1OwProvinces(kObserverConquestMinOwProvincesPerGp),
      );
      final snapshot = _pivotSnapshotFor(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
      );
      expect(
        canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot),
        isTrue,
        reason:
            'A GP at the observer OW quota satisfies the leading `>=` '
            'short-circuit regardless of pivot availability; the '
            'consolidate-gains caller can then still consider a sole '
            'outgunned-GP peace target.',
      );
    });

    test('returns true above quota even with no minor pivot', () {
      final game = _gameWithProvinces(
        owProvinces: _gp1OwProvinces(kObserverConquestMinOwProvincesPerGp + 5),
      );
      final snapshot = _pivotSnapshotFor(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp + 5,
      );
      expect(
        canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot),
        isTrue,
        reason:
            'Above-quota totals must keep returning true so consolidate '
            'callers see the same pivot availability the leading short '
            'circuit advertises.',
      );
    });

    test('returns true via the OW minorsOnMap arm when below quota', () {
      final game = _gameWithProvinces(
        owProvinces: [
          ..._gp1OwProvinces(8),
          const Province(
            id: 'oldWorld|minor1_a',
            regionId: 'oldWorld',
            ownerId: _minor1,
          ),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _pivotSnapshotFor(
        oldWorldProvincesOwned: 8,
        invadableProvinceIdsSorted: const ['oldWorld|minor1_a'],
      );
      expect(
        canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot),
        isTrue,
        reason:
            'An OW-owning minor on the map provides the SPEC-authorized '
            'minor pivot when the GP peaces its sole GP foe. The '
            'predicate must return true via the `minorsOnMap` branch '
            'without consulting the invadable list.',
      );
    });

    test(
      'returns true via minorsOnMap even when that minor is already in atWarWith',
      () {
        // The pivot helper deliberately does NOT filter by
        // `snapshot.threats.atWarWith`; the at-war filtering lives in the
        // higher-level peace collectors. Pinning this contract prevents a
        // future refactor from silently coupling pivot availability to
        // the at-war set.
        final game = _gameWithProvinces(
          owProvinces: [
            ..._gp1OwProvinces(8),
            const Province(
              id: 'oldWorld|minor1_a',
              regionId: 'oldWorld',
              ownerId: _minor1,
            ),
          ],
          minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
        );
        final snapshot = _pivotSnapshotFor(
          oldWorldProvincesOwned: 8,
          invadableProvinceIdsSorted: const ['oldWorld|minor1_a'],
          atWarWith: const [_gp2, _minor1],
        );
        expect(
          canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot),
          isTrue,
          reason:
              'The helper is a pivot-availability check; whether the '
              'minor is currently in the at-war set is the higher-level '
              "collector's concern. Pinning this contract keeps that "
              'separation explicit.',
        );
      },
    );

    test(
      'returns true via the invadable-list arm when only an NW minor frontier exists',
      () {
        // No minor owns any OW province (so the `minorsOnMap` arm is
        // false), but `invadableProvinceIdsSorted` includes an NW
        // province owned by a minor. `getProvinceOwnerMap` scans both
        // regions, so the trailing `any` reaches the minor across the
        // NW boundary.
        final game = _gameWithProvinces(
          owProvinces: _gp1OwProvinces(8),
          nwProvinces: const [
            Province(
              id: 'newWorld|minor1_a',
              regionId: 'newWorld',
              ownerId: _minor1,
            ),
          ],
          minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
        );
        final snapshot = _pivotSnapshotFor(
          oldWorldProvincesOwned: 8,
          invadableProvinceIdsSorted: const ['newWorld|minor1_a'],
        );
        expect(
          canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot),
          isTrue,
          reason:
              'When no OW minor exists, an invadable-list province with '
              'a minor owner still satisfies the pivot check via the '
              'trailing `any`. Pinning this preserves the NW colonial '
              'minor frontier pivot path.',
        );
      },
    );

    test(
      'returns false when below quota with a GP-only invadable frontier and no minors',
      () {
        final game = _gameWithProvinces(
          owProvinces: [
            ..._gp1OwProvinces(8),
            for (var i = 1; i <= 3; i++)
              Province(
                id: 'oldWorld|gp2_$i',
                regionId: 'oldWorld',
                ownerId: _gp2,
              ),
          ],
        );
        final snapshot = _pivotSnapshotFor(
          oldWorldProvincesOwned: 8,
          invadableProvinceIdsSorted: const [
            'oldWorld|gp2_1',
            'oldWorld|gp2_2',
          ],
        );
        expect(
          canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot),
          isFalse,
          reason:
              'No minor anywhere and a GP-only invadable frontier means '
              'peacing the sole GP foe leaves no SPEC-legal pivot target. '
              "A regression that defaulted to true would peace the GP's "
              'only opponent and deadlock the EXPAND strategy.',
        );
      },
    );

    test(
      'returns false with empty invadable list and no minors when below quota',
      () {
        final game = _gameWithProvinces(owProvinces: _gp1OwProvinces(8));
        final snapshot = _pivotSnapshotFor(oldWorldProvincesOwned: 8);
        expect(
          canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot),
          isFalse,
          reason:
              'An empty invadable list combined with no OW minor on the '
              'map provides no pivot; the trailing `any` is false and the '
              'predicate must reach the `return false` exit.',
        );
      },
    );

    test(
      'returns false just below quota with no pivot (boundary at quota - 1)',
      () {
        final owCount = kObserverConquestMinOwProvincesPerGp - 1;
        final game = _gameWithProvinces(owProvinces: _gp1OwProvinces(owCount));
        final snapshot = _pivotSnapshotFor(oldWorldProvincesOwned: owCount);
        expect(
          canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot),
          isFalse,
          reason:
              'The quota comparison is `>=`, so ownOw = quota - 1 must '
              'NOT short-circuit to true. With no minor pivot, the '
              'predicate must reach the trailing `return false` exit.',
        );
      },
    );

    test('is deterministic across repeated calls (Must-have #7)', () {
      final game = _gameWithProvinces(
        owProvinces: [
          ..._gp1OwProvinces(8),
          const Province(
            id: 'oldWorld|minor1_a',
            regionId: 'oldWorld',
            ownerId: _minor1,
          ),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _pivotSnapshotFor(
        oldWorldProvincesOwned: 8,
        invadableProvinceIdsSorted: const ['oldWorld|minor1_a'],
      );
      final first = canPivotFromSoleGpWarAfterPeace(
        game: game,
        snapshot: snapshot,
      );
      final second = canPivotFromSoleGpWarAfterPeace(
        game: game,
        snapshot: snapshot,
      );
      final third = canPivotFromSoleGpWarAfterPeace(
        game: game,
        snapshot: snapshot,
      );
      expect(first, isTrue);
      expect(second, first);
      expect(third, first);
    });
  });
}
