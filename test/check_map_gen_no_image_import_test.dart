import 'package:test/test.dart';

import '../tool/check_map_gen_no_image_import.dart';

void main() {
  group('isMapRenderLayerFile', () {
    test('classifies files under lib/src/render/ as render layer', () {
      expect(
        isMapRenderLayerFile(
          'packages/colonizethis_map/lib/src/render/tile_map_visualization.dart',
        ),
        isTrue,
      );
    });

    test('classifies flat lib/src/ files as non-render layer', () {
      expect(
        isMapRenderLayerFile(
          'packages/colonizethis_map/lib/src/tile_map_generator.dart',
        ),
        isFalse,
      );
    });
  });

  group('findMapGenImageImportViolations', () {
    test('flags a package:image import in a non-render-layer file', () {
      const src = r'''
import 'package:image/image.dart' as img;

void encode() {}
''';
      final violations = findMapGenImageImportViolations(
        relativePath: 'packages/colonizethis_map/lib/src/tile_map_generator.dart',
        source: src,
      );
      expect(violations, hasLength(1));
      expect(violations.single.line, 1);
      expect(violations.single.message, contains('render layer'));
    });

    test('flags a package:image export in a non-render-layer file', () {
      const src = r'''
export 'package:image/image.dart';
''';
      final violations = findMapGenImageImportViolations(
        relativePath:
            'packages/colonizethis_map/lib/src/tile_map_generator_land_seeds.dart',
        source: src,
      );
      expect(violations, hasLength(1));
    });

    test(
      'flags a package:image import in a view-model file (outside render/)',
      () {
        const src = r'''
import 'package:image/image.dart' as img;
''';
        final violations = findMapGenImageImportViolations(
          relativePath:
              'packages/colonizethis_map/lib/src/init_game_map_view_builder.dart',
          source: src,
        );
        expect(violations, hasLength(1));
      },
    );

    test('allows package:image import in a render-layer file', () {
      const src = r'''
import 'package:image/image.dart' as img;
''';
      final violations = findMapGenImageImportViolations(
        relativePath:
            'packages/colonizethis_map/lib/src/render/tile_map_visualization.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('allows package:image in any render-layer file (path scope)', () {
      const src = r'''
import 'package:image/image.dart' as img;
''';
      final violations = findMapGenImageImportViolations(
        relativePath:
            'packages/colonizethis_map/lib/src/render/multi_region_map_rendering.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('does not flag a same-prefix package such as package:image_picker', () {
      const src = r'''
import 'package:image_picker/image_picker.dart';
''';
      final violations = findMapGenImageImportViolations(
        relativePath: 'packages/colonizethis_map/lib/src/tile_map_generator.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('does not flag a comment mentioning package:image', () {
      const src = r'''
// This generation pass must never import 'package:image/image.dart'.
final grid = TileMapGrid.filled(h, w, '');
''';
      final violations = findMapGenImageImportViolations(
        relativePath: 'packages/colonizethis_map/lib/src/tile_map_generator.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('does not flag an unrelated import', () {
      const src = r'''
import 'tile_map_grid.dart';
import 'package:meta/meta.dart';
''';
      final violations = findMapGenImageImportViolations(
        relativePath: 'packages/colonizethis_map/lib/src/tile_map_generator.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });
  });
}
