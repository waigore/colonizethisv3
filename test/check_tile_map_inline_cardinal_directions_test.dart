import 'package:test/test.dart';

import '../tool/check_tile_map_inline_cardinal_directions.dart';

void main() {
  group('findTileMapInlineCardinalDirectionViolations', () {
    test('flags inline north delta tuple outside tile_map_directions.dart', () {
      const src = '''
const dirs = <(int, int)>[
  (0, -1),
  (0, 1),
];
''';
      final v = findTileMapInlineCardinalDirectionViolations(
        relativePath: 'packages/colonizethis_map/lib/src/foo.dart',
        source: src,
      );
      expect(v, isNotEmpty);
      expect(v.first.line, 2);
    });

    test('ignores lines without north delta tuple', () {
      const src = '''
const other = [(1, 2), (3, 4)];
''';
      final v = findTileMapInlineCardinalDirectionViolations(
        relativePath: 'packages/colonizethis_map/lib/src/foo.dart',
        source: src,
      );
      expect(v, isEmpty);
    });
  });
}
