import 'package:colonizethis_world/src/world/player_view.dart'
    show VisibilityLevel;
import 'package:colonizethis_world/src/world/visibility_map_helpers.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  final fullyVisible = VisibilityLevel.fullyVisible.name;
  final fogged = VisibilityLevel.fogged.name;
  final unknown = VisibilityLevel.unknown.name;

  group('setTilesFullyVisible', () {
    test('sets every listed tile to fullyVisible (positive)', () {
      final vis = <String, String>{'t0': fogged};

      setTilesFullyVisible(vis, const ['t0', 't1', 't2']);

      expect(vis['t0'], fullyVisible);
      expect(vis['t1'], fullyVisible);
      expect(vis['t2'], fullyVisible);
    });

    test('leaves the map unchanged for an empty tile list (negative)', () {
      final vis = <String, String>{'t0': fogged};

      setTilesFullyVisible(vis, const <String>[]);

      expect(vis, {'t0': fogged});
    });
  });

  group('downgradeFullyVisibleToFogged', () {
    test('downgrades only fullyVisible tiles and counts them (positive)', () {
      final vis = <String, String>{'t0': fullyVisible, 't1': fullyVisible};

      final downgraded = downgradeFullyVisibleToFogged(vis, const ['t0', 't1']);

      expect(downgraded, 2);
      expect(vis['t0'], fogged);
      expect(vis['t1'], fogged);
    });

    test(
      'leaves fogged/unknown/missing tiles untouched, count 0 (negative)',
      () {
        final vis = <String, String>{'t0': fogged, 't1': unknown};

        final downgraded = downgradeFullyVisibleToFogged(vis, const [
          't0',
          't1',
          'missing',
        ]);

        expect(downgraded, 0);
        expect(vis['t0'], fogged);
        expect(vis['t1'], unknown);
        expect(vis.containsKey('missing'), isFalse);
      },
    );
  });

  group('setTilesFullyVisibleForPlayer', () {
    test(
      'returns a new outer map and copies the player inner map (positive)',
      () {
        final original = <String, Map<String, String>>{
          'a': {'t0': fogged},
          'b': {'t0': fogged},
        };

        final out = setTilesFullyVisibleForPlayer(original, 'a', const [
          't0',
          't1',
        ]);

        expect(identical(out, original), isFalse);
        expect(out['a'], {'t0': fullyVisible, 't1': fullyVisible});
        // Other player untouched.
        expect(out['b'], {'t0': fogged});
        // Original input not mutated.
        expect(original['a'], {'t0': fogged});
      },
    );

    test(
      'returns the original reference when tile list is empty (negative)',
      () {
        final original = <String, Map<String, String>>{
          'a': {'t0': fogged},
        };

        final out = setTilesFullyVisibleForPlayer(
          original,
          'a',
          const <String>[],
        );

        expect(identical(out, original), isTrue);
      },
    );
  });
}
