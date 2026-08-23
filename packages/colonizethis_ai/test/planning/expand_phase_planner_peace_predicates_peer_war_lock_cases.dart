// Case bodies for `expand_phase_planner_peace_predicates_test.dart` (Refs #4602 Slice B).

// Predicate-level unit tests for EXPAND-phase peace helpers in
// `expand_phase_planner.dart` (Refs #2847 § H4-a / § H2).
//
// `planExpandPeace` integration pins live in
// `expand_phase_planner_peace_test.dart`.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'test_game_factories.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _minor1 = 'minor1';

void registerPeacePredicatesPeerWarLockCases() {
  group('expandIsGeographicPeerWarLock', () {
    test('adjacency collapses to the at-war peer -> true', () {
      // Canonical seed-42 turn-99 shape: adjacency is exactly the sole
      // peer GP. The helper must return true so the H4-a planner arm
      // fires.
      final snapshot = buildExpandSnapshot(
        atWarWith: const [_gp2],
        adjacentOwners: const [_gp2],
      );
      expect(
        expandIsGeographicPeerWarLock(snapshot: snapshot, peerGpId: _gp2),
        isTrue,
        reason:
            'adjacentOwnerFactionIdsSorted is exactly [_gp2] -> the '
            'predicate confirms the geographic peer-war lock signal.',
      );
    });

    test('adjacency contains the peer plus a second faction -> false', () {
      // A minor or other GP is also an OW neighbor -> the active player
      // has an alternative pivot route. The predicate must reject.
      final snapshot = buildExpandSnapshot(
        atWarWith: const [_gp2],
        adjacentOwners: const [_gp2, _minor1],
      );
      expect(
        expandIsGeographicPeerWarLock(snapshot: snapshot, peerGpId: _gp2),
        isFalse,
        reason:
            'Adjacency has 2 entries; the active player has another OW '
            'neighbor so the lock is not "geographic" -> predicate '
            'rejects.',
      );
    });

    test('adjacency is empty -> false', () {
      // No OW adjacency at all (landlocked or no OW provinces yet) ->
      // there is no lock to break. Predicate rejects.
      final snapshot = buildExpandSnapshot(
        atWarWith: const [_gp2],
        adjacentOwners: const [],
      );
      expect(
        expandIsGeographicPeerWarLock(snapshot: snapshot, peerGpId: _gp2),
        isFalse,
        reason:
            'Empty adjacency -> length != 1 -> predicate rejects '
            '(no geographic lock signal).',
      );
    });

    test('adjacency single entry but not the peer GP -> false', () {
      // Sole adjacency entry is a minor or some other faction, not the
      // queried peer GP. The predicate must reject because the active
      // player can still pivot against that adjacent faction.
      final snapshot = buildExpandSnapshot(
        atWarWith: const [_gp2],
        adjacentOwners: const [_minor1],
      );
      expect(
        expandIsGeographicPeerWarLock(snapshot: snapshot, peerGpId: _gp2),
        isFalse,
        reason:
            'Adjacency is [_minor1], not the queried peer [_gp2] -> '
            'predicate rejects (the adjacent faction is reachable and '
            'not the at-war peer).',
      );
    });

    test('determinism: identical inputs yield identical results', () {
      final snapshot = buildExpandSnapshot(
        atWarWith: const [_gp2],
        adjacentOwners: const [_gp2],
      );
      final first = expandIsGeographicPeerWarLock(
        snapshot: snapshot,
        peerGpId: _gp2,
      );
      final second = expandIsGeographicPeerWarLock(
        snapshot: snapshot,
        peerGpId: _gp2,
      );
      expect(
        second,
        first,
        reason: 'Pure predicate -> identical inputs yield identical results.',
      );
    });
  });

  // Refs #2847 § H2 predicate-level pins for
  // `expandRecentlyPeacedWithGreatPower`. These tests are scoped to the
  // predicate itself; integration with `planExpandDeclareWar` arm 3 is
  // pinned in `expand_phase_planner_declare_war_test.dart`.
}
