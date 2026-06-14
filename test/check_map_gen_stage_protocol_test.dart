import 'package:test/test.dart';

import '../tool/check_map_gen_stage_protocol.dart';

void main() {
  group('findMapGenStageProtocolViolations', () {
    test('accepts a service class implementing MapGenStage', () {
      const src = r'''
class _TileMapGenJoinSea implements MapGenStage {
  @override
  final TileMapParams params;
}
''';
      final violations = findMapGenStageProtocolViolations(
        relativePath:
            'packages/colonizethis_map/lib/src/tile_map_generator_join_sea.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('flags a service class missing MapGenStage implementation', () {
      const src = r'''
class _TileMapGenJoinSea {
  final TileMapParams params;
}
''';
      final violations = findMapGenStageProtocolViolations(
        relativePath:
            'packages/colonizethis_map/lib/src/tile_map_generator_join_sea.dart',
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
  });
}
