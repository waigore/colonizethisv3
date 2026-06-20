import 'package:colonizethis_map/src/map_region_dispatch.dart';
import 'package:colonizethis_map/src/map_validation_exception.dart';
import 'package:colonizethis_map/src/region_constants.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('selectByMapRegionId (Refs #3574)', () {
    test('old world id selects the old-world branch', () {
      final result = selectByMapRegionId(
        kRegionOldWorld,
        oldWorld: () => 'ow',
        newWorld: () => 'nw',
      );
      expect(result, 'ow');
    });

    test('new world id selects the new-world branch', () {
      final result = selectByMapRegionId(
        kRegionNewWorld,
        oldWorld: () => 'ow',
        newWorld: () => 'nw',
      );
      expect(result, 'nw');
    });

    test('only the selected branch is evaluated', () {
      var owCalls = 0;
      var nwCalls = 0;
      selectByMapRegionId(
        kRegionOldWorld,
        oldWorld: () {
          owCalls++;
          return 0;
        },
        newWorld: () {
          nwCalls++;
          return 0;
        },
      );
      expect(owCalls, 1);
      expect(nwCalls, 0);
    });

    test('unknown id throws MapValidationException with the canonical message', () {
      expect(
        () => selectByMapRegionId(
          'middleWorld',
          oldWorld: () => 'ow',
          newWorld: () => 'nw',
        ),
        throwsA(
          isA<MapValidationException>().having(
            (e) => e.message,
            'message',
            contains('unknown region id "middleWorld"'),
          ),
        ),
      );
    });
  });

  group('selectByMapRegionIdOrNull (Refs #3574)', () {
    test('selects the matching branch for known ids', () {
      expect(
        selectByMapRegionIdOrNull(
          kRegionOldWorld,
          oldWorld: () => 'ow',
          newWorld: () => 'nw',
        ),
        'ow',
      );
      expect(
        selectByMapRegionIdOrNull(
          kRegionNewWorld,
          oldWorld: () => 'ow',
          newWorld: () => 'nw',
        ),
        'nw',
      );
    });

    test('returns null (no throw) for an unknown id', () {
      expect(
        selectByMapRegionIdOrNull(
          'middleWorld',
          oldWorld: () => 'ow',
          newWorld: () => 'nw',
        ),
        isNull,
      );
    });
  });

  group('isOldWorldRegionId (Refs #3574)', () {
    test('matches the old world constant only', () {
      expect(isOldWorldRegionId(kRegionOldWorld), isTrue);
      expect(isOldWorldRegionId(kRegionNewWorld), isFalse);
      expect(isOldWorldRegionId('middleWorld'), isFalse);
    });
  });
}
