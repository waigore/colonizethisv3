import 'package:test/test.dart';

import '../tool/check_colonizethis_map_lib_pipe_split.dart';

void main() {
  group('findColonizethisMapLibPipeSplitViolations', () {
    test('flags split pipe literal outside allowed modules', () {
      const src = r'''
void f(String k) {
  final p = k.split('|');
  print(p);
}
''';
      final v = findColonizethisMapLibPipeSplitViolations(
        relativePath: 'packages/colonizethis_map/lib/src/foo.dart',
        source: src,
      );
      expect(v, isNotEmpty);
      expect(v.first.line, greaterThan(0));
    });

    test('ignores split with other delimiter', () {
      const src = r'''
void f(String k) {
  final p = k.split(',');
  print(p);
}
''';
      final v = findColonizethisMapLibPipeSplitViolations(
        relativePath: 'packages/colonizethis_map/lib/src/foo.dart',
        source: src,
      );
      expect(v, isEmpty);
    });
  });
}
