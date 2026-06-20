// Pins the branch table of `canPivotFromSoleGpWarAfterPeace` from
// `colonial_pressure.dart` at the function-unit boundary (Refs #2509 S10).
//
//   SPEC/ai/ai-architecture.md § Observer goal phases (Full AI), EXPAND:
//     "Below-quota Full AI may peace a sole outgunned Great Power foe
//     only when an alternative pivot exists (minor on map, or invadable
//     minor-owned frontier), otherwise it must hold the war."
//   `unwinnableSoleGpFrontierPeaceTarget` consumes this predicate as the
//   pivot-availability gate before returning a peace target id; a
//   regression here silently flips peace behavior on every below-quota
//   sole-GP-war turn.
//
// The implementation in `colonial_pressure.dart`:
//
//   bool canPivotFromSoleGpWarAfterPeace({
//     required Game game,
//     required AIWorldSnapshot snapshot,
//   }) {
//     if (snapshot.conquest.oldWorldProvincesOwned >=
//         kObserverConquestMinOwProvincesPerGp) {
//       return true;
//     }
//     final minorsOnMap = game.worldState.oldWorld.provinces.any(
//       (p) =>
//           p.ownerId != null &&
//           p.ownerId!.isNotEmpty &&
//           game.minorNations.any((m) => m.id == p.ownerId),
//     );
//     if (minorsOnMap) {
//       return true;
//     }
//     return snapshot.conquest.invadableProvinceIdsSorted.any((pid) {
//       final owner = getProvinceOwnerMap(game)[pid];
//       return owner != null && game.minorNations.any((m) => m.id == owner);
//     });
//   }
//
// The predicate is consumed only by `unwinnableSoleGpFrontierPeaceTarget`
// in `colonial_pressure.dart`, which feeds the observer-goal-phase peace
// pipeline. A regression in this predicate would silently change
// `unwinnableSoleGpFrontierPeaceTarget` outcomes:
//
//   - Dropping the quota-met short-circuit would make a quota-met GP
//     facing an outgunned sole foe (e.g. lone hold-out OW peer) refuse
//     to consider a SPEC-authorized peace pivot when no minor or
//     minor-invadable province remains.
//   - Collapsing the OW minorsOnMap scan would block below-quota GPs
//     from peacing stalemated sole-GP wars to pivot onto a minor —
//     stranding the GP in a war it cannot win and missing the turn-100
//     OW conquest gate (Refs #2509 turn-100 verify exit code 5).
//   - Collapsing the invadable-list minor-owner scan would block the
//     NW-frontier minor pivot (sea-reachable colonial minor with no OW
//     holdings) when no OW minor exists.
//   - Defaulting to true when no pivot exists would peace the only
//     remaining frontier opponent and leave the GP with no SPEC-legal
//     declare-war target, deadlocking the EXPAND-phase strategy.
//
// Sibling coverage that this file complements (but does not duplicate):
//
//   - `diplomacy_planner_below_quota_peace_test.dart` and
//     `diplomacy_planner_stalled_peace_test.dart` exercise
//     `unwinnableSoleGpFrontierPeaceTarget` at the orchestrator boundary
//     and indirectly assume the quota-met / minors-on-map branches; they
//     do not isolate the predicate or pin the no-pivot-false exit.
//   - `expand_phase_planner_peer_peace_basic_test.dart` and
//     `expand_phase_planner_peer_gap_boundary_test.dart` cover other
//     `colonial_pressure` predicates and the peer-gap rule; they do not
//     reference `canPivotFromSoleGpWarAfterPeace`.
//
// Coverage layers:
//
//   - **Quota-met short-circuit (B1):** ownOw >= quota with no minors
//     anywhere → true (the leading `if` returns before any roster scan).
//   - **OW minor present (B2):** ownOw < quota and an OW province has a
//     minor owner → true via the `minorsOnMap` branch (without consulting
//     the invadable list).
//   - **At-war OW minor still counts (B2 at-war subtlety):** the
//     predicate does NOT filter by `snapshot.threats.atWarWith`; an OW
//     minor already in the at-war set still satisfies the OW scan. Pin
//     this so a future refactor cannot silently couple this predicate
//     to the at-war state — that filtering lives in higher-level peace
//     collectors, not here.
//   - **NW-only minor in invadable list (B3):** ownOw < quota, no OW
//     minor presence, but `invadableProvinceIdsSorted` includes an NW
//     province whose owner is a minor → true via the trailing `any`.
//     `getProvinceOwnerMap` scans both regions, so the predicate can
//     reach the minor across the NW boundary even though the
//     `minorsOnMap` gate checked OW only.
//   - **No pivot anywhere (B4 false):** ownOw < quota, no minor in OW,
//     no minor-owner in invadable list (GP-only invadable frontier) →
//     false. The only reachable `return false` exit.
//   - **Empty invadable list + below quota + no minor (B4 false):**
//     empty `invadableProvinceIdsSorted` collapses the trailing `any`
//     to false; with no OW minor either, the predicate falls through
//     to the false exit.
//   - **Determinism (must-have #7):** identical inputs produce identical
//     outputs across repeat invocations.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _minor1 = 'minor1';

/// Builds a Game fixture for `canPivotFromSoleGpWarAfterPeace`.
///
/// Only the OW and (optionally) NW province lists and the minor roster
/// vary across cases; the predicate does not read diplomacy relations,
/// turn phase, or stockpiles, so they stay at their defaults.
Game _gameWith({
  required List<Province> owProvinces,
  List<Province> nwProvinces = const [],
  List<MinorNation> minorNations = const [],
}) {
  return Game(
    id: 'g-2509-can-pivot-from-sole-gp-war-branches',
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

/// Builds an AIWorldSnapshot fixture limited to the conquest summary
/// fields the predicate reads (`oldWorldProvincesOwned`,
/// `invadableProvinceIdsSorted`). All other summaries default.
AIWorldSnapshot _snapshotFor({
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

List<Province> _gpOnlyOwProvinces(int count) {
  return [
    for (var i = 1; i <= count; i++)
      Province(id: 'oldWorld|gp1_$i', regionId: 'oldWorld', ownerId: _gp1),
  ];
}

void main() {
  group('canPivotFromSoleGpWarAfterPeace branch table', () {
    test('quota-met short-circuit returns true even with no minor pivot', () {
      final game = _gameWith(
        owProvinces: _gpOnlyOwProvinces(kObserverConquestMinOwProvincesPerGp),
      );
      final snapshot = _snapshotFor(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
      );
      expect(
        canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot),
        isTrue,
        reason:
            'A GP at the observer OW quota satisfies the leading short '
            'circuit regardless of pivot availability; '
            '`unwinnableSoleGpFrontierPeaceTarget` can then still consider '
            'a sole outgunned-GP peace target. A regression that dropped '
            'this short-circuit would refuse the SPEC-authorized peace '
            'pivot whenever quota-met GPs hold a sole foe without any '
            'remaining minor or invadable-minor frontier.',
      );
    });

    test('quota-exceeded with no minor pivot still returns true', () {
      final game = _gameWith(
        owProvinces: _gpOnlyOwProvinces(
          kObserverConquestMinOwProvincesPerGp + 5,
        ),
      );
      final snapshot = _snapshotFor(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp + 5,
      );
      expect(
        canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot),
        isTrue,
        reason:
            'The quota-met branch is a `>=` short circuit; OW totals '
            'above quota must keep returning true so consolidate-gains '
            'callers see the same pivot availability.',
      );
    });

    test('below quota with an OW-owning uninvaded minor returns true', () {
      final game = _gameWith(
        owProvinces: [
          ..._gpOnlyOwProvinces(8),
          const Province(
            id: 'oldWorld|minor1_a',
            regionId: 'oldWorld',
            ownerId: _minor1,
          ),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _snapshotFor(
        oldWorldProvincesOwned: 8,
        invadableProvinceIdsSorted: const ['oldWorld|minor1_a'],
      );
      expect(
        canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot),
        isTrue,
        reason:
            'An OW minor on the map provides the SPEC-authorized minor '
            'pivot when the GP peaces its sole GP foe. A regression '
            'that collapsed the OW `minorsOnMap` scan would strand '
            'below-quota GPs in stalemated sole-GP wars (Refs #2509 '
            'turn-100 verify exit code 5).',
      );
    });

    test(
      'OW minor already in atWarWith still counts as a pivot (no at-war filter)',
      () {
        // The predicate intentionally does NOT filter by at-war state; the
        // at-war pivot filtering lives in higher-level peace collectors
        // (`expandPhaseGpPeaceTargets`, `belowQuotaPeerGpPeaceTargets`,
        // etc.). Pinning this prevents a future refactor from silently
        // coupling the pivot-availability check to the at-war filter.
        final game = _gameWith(
          owProvinces: [
            ..._gpOnlyOwProvinces(8),
            const Province(
              id: 'oldWorld|minor1_a',
              regionId: 'oldWorld',
              ownerId: _minor1,
            ),
          ],
          minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
        );
        final snapshot = _snapshotFor(
          oldWorldProvincesOwned: 8,
          invadableProvinceIdsSorted: const ['oldWorld|minor1_a'],
          atWarWith: const [_gp2, _minor1],
        );
        expect(
          canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot),
          isTrue,
          reason:
              'The function is a pivot-availability check; whether the '
              'minor is currently in the at-war set is the higher-level '
              'collector\'s concern. Pinning this contract keeps that '
              'separation explicit.',
        );
      },
    );

    test(
      'below quota with NW-only minor in invadable list returns true (B3)',
      () {
        // No minor owns any OW province (so `minorsOnMap` is false), but
        // `invadableProvinceIdsSorted` contains an NW province owned by a
        // minor. `getProvinceOwnerMap` scans both regions, so the trailing
        // `any` reaches the minor across the NW boundary and confirms a
        // pivot is available.
        final game = _gameWith(
          owProvinces: _gpOnlyOwProvinces(8),
          nwProvinces: const [
            Province(
              id: 'newWorld|minor1_a',
              regionId: 'newWorld',
              ownerId: _minor1,
            ),
          ],
          minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
        );
        final snapshot = _snapshotFor(
          oldWorldProvincesOwned: 8,
          invadableProvinceIdsSorted: const ['newWorld|minor1_a'],
        );
        expect(
          canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot),
          isTrue,
          reason:
              'When no OW minor exists, an invadable-list province with '
              'a minor owner still satisfies the pivot check via the '
              'trailing `any`. A regression that collapsed this scan '
              'would refuse peace whenever the only pivot is an NW '
              'colonial minor frontier.',
        );
      },
    );

    test(
      'below quota with GP-only invadable frontier and no minors returns false',
      () {
        // ownOw < quota, no minor on map, invadable list non-empty but
        // owned only by another GP. The only reachable false exit.
        final game = _gameWith(
          owProvinces: [
            ..._gpOnlyOwProvinces(8),
            for (var i = 1; i <= 3; i++)
              Province(
                id: 'oldWorld|gp2_$i',
                regionId: 'oldWorld',
                ownerId: _gp2,
              ),
          ],
        );
        final snapshot = _snapshotFor(
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
              'A regression that defaulted to true here would peace the '
              'GP\'s only opponent and deadlock the EXPAND strategy '
              '(Refs #2509 § Observer goal phases (Full AI), EXPAND).',
        );
      },
    );

    test(
      'below quota with empty invadable list and no minors returns false',
      () {
        // Empty `invadableProvinceIdsSorted` collapses the trailing `any`
        // to false without ever consulting `getProvinceOwnerMap`; with no
        // OW minor either, the predicate exits via `return false`.
        final game = _gameWith(owProvinces: _gpOnlyOwProvinces(8));
        final snapshot = _snapshotFor(oldWorldProvincesOwned: 8);
        expect(
          canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot),
          isFalse,
          reason:
              'An empty invadable list combined with no OW minor on the '
              'map provides no pivot; the trailing `any` is false and '
              'the predicate must return false. A regression that '
              'short-circuited the empty-invadable branch to true would '
              'spuriously authorize peace pivots when no pivot exists.',
        );
      },
    );

    test(
      'just below quota with no minor and no invadable minor returns false',
      () {
        // Boundary: ownOw = quota - 1. The leading `if` is strict `>=`,
        // so this case must miss the short-circuit and fall through to
        // the minor/invadable scans, which then return false.
        final owCount = kObserverConquestMinOwProvincesPerGp - 1;
        final game = _gameWith(owProvinces: _gpOnlyOwProvinces(owCount));
        final snapshot = _snapshotFor(oldWorldProvincesOwned: owCount);
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

    test(
      'determinism: identical inputs produce identical outputs (must-have #7)',
      () {
        final game = _gameWith(
          owProvinces: [
            ..._gpOnlyOwProvinces(8),
            const Province(
              id: 'oldWorld|minor1_a',
              regionId: 'oldWorld',
              ownerId: _minor1,
            ),
          ],
          minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
        );
        final snapshot = _snapshotFor(
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
      },
    );
  });
}
