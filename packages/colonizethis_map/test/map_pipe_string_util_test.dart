import 'package:colonizethis_map/src/map_pipe_string_util.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('mapPipeLocalProvinceIdFromPortsSeaboardKey', () {
    test('parses region|local|extra as local when region matches', () {
      expect(
        mapPipeLocalProvinceIdFromPortsSeaboardKey('oldWorld|p1|x', 'oldWorld'),
        'p1',
      );
    });

    test('returns null when region prefix mismatches', () {
      expect(
        mapPipeLocalProvinceIdFromPortsSeaboardKey('newWorld|p1|x', 'oldWorld'),
        isNull,
      );
    });

    test('two-segment key returns first segment as local id', () {
      expect(
        mapPipeLocalProvinceIdFromPortsSeaboardKey('p1|ignored', 'oldWorld'),
        'p1',
      );
    });
  });

  group('mapPipeTryParseTwoPartPair', () {
    test('parses exactly two segments', () {
      final p = mapPipeTryParseTwoPartPair('a|b');
      expect(p, isNotNull);
      expect(p!.$1, 'a');
      expect(p.$2, 'b');
    });

    test('returns null when not two segments', () {
      expect(mapPipeTryParseTwoPartPair('a|b|c'), isNull);
      expect(mapPipeTryParseTwoPartPair('a'), isNull);
    });
  });

  group('mapPipeLastSegmentOrWhole', () {
    test('returns whole string when no pipe', () {
      expect(mapPipeLastSegmentOrWhole('s1'), 's1');
    });

    test('returns last segment when pipe present', () {
      expect(mapPipeLastSegmentOrWhole('oldWorld|s3'), 's3');
    });
  });
}
