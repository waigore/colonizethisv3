import 'package:test/test.dart';

import '../tool/check_map_region_dispatch_central.dart';

void main() {
  group('findMapRegionDispatchViolations', () {
    test('flags an inline regionId == kRegionOldWorld comparison', () {
      const src = r'''
if (regionId == kRegionOldWorld) {
  return forOldWorld();
}
''';
      final violations = findMapRegionDispatchViolations(
        relativePath: 'packages/colonizethis_map/lib/src/foo.dart',
        source: src,
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('selectByMapRegionId'));
    });

    test('flags a != comparison and a constant-on-the-left comparison', () {
      const src = r'''
if (parsed.regionId != kRegionNewWorld) return;
final ow = kRegionOldWorld == regionId;
''';
      final violations = findMapRegionDispatchViolations(
        relativePath: 'packages/colonizethis_map/lib/src/foo.dart',
        source: src,
      );
      expect(violations, hasLength(2));
    });

    test('accepts canonical selectByMapRegionId delegation', () {
      const src = r'''
return selectByMapRegionId(
  regionId,
  oldWorld: () => a,
  newWorld: () => b,
);
''';
      final violations = findMapRegionDispatchViolations(
        relativePath: 'packages/colonizethis_map/lib/src/foo.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('does not flag the region constants used as a list literal', () {
      const src = r'''
for (final regionId in const [kRegionOldWorld, kRegionNewWorld]) {
  build(regionId);
}
''';
      final violations = findMapRegionDispatchViolations(
        relativePath: 'packages/colonizethis_map/lib/src/foo.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('does not flag the region constants used as map keys', () {
      const src = r'''
final ow = viewByRegion[kRegionOldWorld]!;
final nw = viewByRegion[kRegionNewWorld]!;
''';
      final violations = findMapRegionDispatchViolations(
        relativePath: 'packages/colonizethis_map/lib/src/foo.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('does not flag the region constants used as named arguments', () {
      const src = r'''
final ow = regionMapRenderInputs(game: game, regionId: kRegionOldWorld);
''';
      final violations = findMapRegionDispatchViolations(
        relativePath: 'packages/colonizethis_map/lib/src/foo.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('does not flag the region constants in string interpolation', () {
      const src = r'''
throw MapValidationException(
  'map: unknown region id "$regionId" (expected $kRegionOldWorld or $kRegionNewWorld)',
);
''';
      final violations = findMapRegionDispatchViolations(
        relativePath: 'packages/colonizethis_map/lib/src/foo.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('does not flag a comment describing the comparison', () {
      const src = r'''
/// Stops branching `regionId == kRegionOldWorld ? ... : ...` inline.
final grid = build();
''';
      final violations = findMapRegionDispatchViolations(
        relativePath: 'packages/colonizethis_map/lib/src/foo.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });
  });
}
