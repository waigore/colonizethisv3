import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

/// Overture-clear helper coverage split from densified dedup suite (Refs #4341 AC5).
void main() {
  group('clearOverturesBetweenGpAndFaction (AC1)', () {
    test('positive: directional clear removes only (gpId -> factionId)', () {
      final game = diplomacyGameWithOvertures(const [
        OvertureState(gpId: 'gp1', targetId: 'minor1'),
        OvertureState(gpId: 'gp1', targetId: 'minor2'),
        OvertureState(gpId: 'gp2', targetId: 'gp1'),
      ]);

      final result = clearOverturesBetweenGpAndFaction(game, 'gp1', 'minor1');

      expect(result.removed, hasLength(1));
      expect(result.removed.single.targetId, 'minor1');
      expect(result.game.overtureStates.map((o) => '${o.gpId}|${o.targetId}'), [
        'gp1|minor2',
        'gp2|gp1',
      ]);
    });

    test('negative: directional clear ignores the reverse direction', () {
      final game = diplomacyGameWithOvertures(const [
        OvertureState(gpId: 'gp2', targetId: 'gp1'),
      ]);

      final result = clearOverturesBetweenGpAndFaction(game, 'gp1', 'gp2');

      expect(result.removed, isEmpty);
      expect(identical(result.game, game), isTrue);
    });

    test('positive: bidirectional clear removes both directions', () {
      final game = diplomacyGameWithOvertures(const [
        OvertureState(gpId: 'gp1', targetId: 'gp2'),
        OvertureState(gpId: 'gp2', targetId: 'gp1'),
        OvertureState(gpId: 'gp1', targetId: 'minor1'),
      ]);

      final result = clearOverturesBetweenGpAndFaction(
        game,
        'gp1',
        'gp2',
        bidirectional: true,
      );

      expect(result.removed, hasLength(2));
      expect(result.game.overtureStates, hasLength(1));
      expect(result.game.overtureStates.single.targetId, 'minor1');
    });

    test('positive: removed list preserves original overtureStates order', () {
      final game = diplomacyGameWithOvertures(const [
        OvertureState(gpId: 'gp2', targetId: 'gp1'),
        OvertureState(gpId: 'gp1', targetId: 'minor1'),
        OvertureState(gpId: 'gp1', targetId: 'gp2'),
      ]);

      final result = clearOverturesBetweenGpAndFaction(
        game,
        'gp1',
        'gp2',
        bidirectional: true,
      );

      expect(result.removed.map((o) => '${o.gpId}|${o.targetId}'), [
        'gp2|gp1',
        'gp1|gp2',
      ]);
    });

    test('negative: empty overtures yields no removals and same game', () {
      final game = diplomacyGameWithOvertures(const []);
      final result = clearOverturesBetweenGpAndFaction(game, 'gp1', 'minor1');
      expect(result.removed, isEmpty);
      expect(identical(result.game, game), isTrue);
    });
  });

  group('clearOverturesInvolvingFaction (AC1, full-faction teardown)', () {
    test(
      'positive: removes overtures involving the faction on either side',
      () {
        final game = diplomacyGameWithOvertures(const [
          OvertureState(gpId: 'gp1', targetId: 'minor1'),
          OvertureState(gpId: 'gp2', targetId: 'gp1'),
          OvertureState(gpId: 'gp2', targetId: 'minor2'),
        ]);

        final result = clearOverturesInvolvingFaction(game, 'gp1');

        expect(result.removed, hasLength(2));
        expect(result.removed.map((o) => '${o.gpId}|${o.targetId}'), [
          'gp1|minor1',
          'gp2|gp1',
        ]);
        expect(
          result.game.overtureStates.map((o) => '${o.gpId}|${o.targetId}'),
          ['gp2|minor2'],
        );
      },
    );

    test(
      'positive: minor/tribe target equivalence (only appears as targetId)',
      () {
        final game = diplomacyGameWithOvertures(const [
          OvertureState(gpId: 'gp1', targetId: 'minor1'),
          OvertureState(gpId: 'gp2', targetId: 'minor1'),
          OvertureState(gpId: 'gp1', targetId: 'minor2'),
        ]);

        final result = clearOverturesInvolvingFaction(game, 'minor1');

        expect(result.removed, hasLength(2));
        expect(
          result.game.overtureStates.map((o) => '${o.gpId}|${o.targetId}'),
          ['gp1|minor2'],
        );
      },
    );

    test(
      'negative: no matching faction leaves the game instance unchanged',
      () {
        final game = diplomacyGameWithOvertures(const [
          OvertureState(gpId: 'gp1', targetId: 'minor1'),
        ]);

        final result = clearOverturesInvolvingFaction(game, 'gp9');

        expect(result.removed, isEmpty);
        expect(identical(result.game, game), isTrue);
      },
    );

    test('negative: empty overtures yields no removals and same game', () {
      final game = diplomacyGameWithOvertures(const []);
      final result = clearOverturesInvolvingFaction(game, 'gp1');
      expect(result.removed, isEmpty);
      expect(identical(result.game, game), isTrue);
    });
  });
}
