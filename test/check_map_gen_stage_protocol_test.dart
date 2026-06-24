import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_map_gen_stage_protocol.dart';

void main() {
  group('findMapGenStageProtocolViolations', () {
    test('accepts a service class implementing MapGenStage', () {
      const src = r'''
class TileMapGenLakesProvinces implements MapGenStage {
  @override
  final TileMapParams params;
}
''';
      final violations = findMapGenStageProtocolViolations(
        relativePath:
            'packages/colonizethis_map/lib/src/gen/tile_map_generator_lakes_provinces.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('flags a service class missing MapGenStage implementation', () {
      const src = r'''
class TileMapGenLakesProvinces {
  final TileMapParams params;
}
''';
      final violations = findMapGenStageProtocolViolations(
        relativePath:
            'packages/colonizethis_map/lib/src/gen/tile_map_generator_lakes_provinces.dart',
        source: src,
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('must implement MapGenStage'));
    });

    test('ignores unrelated map lib files', () {
      const src = r'''
class FooBar {}
''';
      final violations = findMapGenStageProtocolViolations(
        relativePath: 'packages/colonizethis_map/lib/src/foo.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('accepts a service adopting the uniform MapGenPass entry point', () {
      const src = r'''
class TileMapGenLandSeeds
    implements MapGenPass<LandSeedPassPayload, LandSeedPassResult> {
  @override
  final TileMapLandSeedParams params;
}
''';
      final violations = findMapGenStageProtocolViolations(
        relativePath:
            'packages/colonizethis_map/lib/src/gen/tile_map_generator_land_seeds.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });
  });

  group('sourceAdoptsMapGenPass', () {
    test('true when the source implements MapGenPass', () {
      expect(
        sourceAdoptsMapGenPass('class X implements MapGenPass<A, B> {}'),
        isTrue,
      );
    });

    test('false when the source only implements MapGenStage', () {
      expect(
        sourceAdoptsMapGenPass('class X implements MapGenStage {}'),
        isFalse,
      );
    });
  });

  group('runCheckMapGenStageProtocol', () {
    test(
      'passes on the live repository tree (>=4 families adopt MapGenPass)',
      () {
        final lines = <String>[];
        final code = runCheckMapGenStageProtocol(
          Directory.current.path,
          info: lines.add,
          err: lines.add,
        );
        expect(code, 0, reason: lines.join('\n'));
      },
    );
  });
}
