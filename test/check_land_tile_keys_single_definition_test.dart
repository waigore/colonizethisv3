import 'package:test/test.dart';

import '../tool/check_land_tile_keys_single_definition.dart';

void main() {
  group('findLandTileKeysSingleDefinitionViolations', () {
    test('accepts the canonical definition in province_lookup.dart', () {
      const src = r'''
List<String> landTileKeysForProvinceBucket(
  WorldState world,
  String regionId,
  String fullProvinceId, {
  bool allowLocalIdFallback = false,
}) {
  return const [];
}
''';
      final violations = findLandTileKeysSingleDefinitionViolations(
        relativePath: landTileKeysCanonicalPath,
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('flags a second top-level definition outside the canonical file', () {
      const src = r'''
List<String> landTileKeysForProvinceBucket(
  WorldState ws,
  String regionId,
  String fullProvinceId,
) {
  return const [];
}
''';
      final violations = findLandTileKeysSingleDefinitionViolations(
        relativePath:
            'packages/colonizethis_world/lib/src/world/naval_coastal_visibility.dart',
        source: src,
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('must be defined only in'));
    });

    test('flags a `hide landTileKeysForProvinceBucket` combinator', () {
      const src = r'''
import 'province_lookup.dart' hide landTileKeysForProvinceBucket;
''';
      final violations = findLandTileKeysSingleDefinitionViolations(
        relativePath:
            'packages/colonizethis_world/lib/src/world/fog_resolution.dart',
        source: src,
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('no longer needed'));
    });

    test('flags a `hide` on an export directive', () {
      const src = r'''
export 'src/world/naval_coastal_visibility.dart'
    hide landTileKeysForProvinceBucket;
''';
      final violations = findLandTileKeysSingleDefinitionViolations(
        relativePath: 'packages/colonizethis_world/lib/colonizethis_world.dart',
        source: src,
      );
      expect(violations, hasLength(1));
    });

    test('accepts callers that invoke the canonical function', () {
      const src = r'''
void f(WorldState ws, String regionId, String fullProvinceId) {
  final tiles = landTileKeysForProvinceBucket(
    ws,
    regionId,
    fullProvinceId,
    allowLocalIdFallback: true,
  );
  print(tiles.length);
}
''';
      final violations = findLandTileKeysSingleDefinitionViolations(
        relativePath:
            'packages/colonizethis_world/lib/src/world/naval_coastal_visibility.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });
  });
}
