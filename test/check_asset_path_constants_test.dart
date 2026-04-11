import 'package:test/test.dart';

import '../tool/check_asset_path_constants.dart';

void main() {
  group('findAssetPathConstantViolationsInSource', () {
    test('flags direct assets/ string literal', () {
      const src = r'''
void f() {
  final p = 'assets/icons/32/ui_icon_foo.png';
  print(p);
}
''';
      final v = findAssetPathConstantViolationsInSource(
        relativePath: 'app/lib/widgets/foo.dart',
        source: src,
      );
      expect(v, isNotEmpty);
      expect(v.first.message, contains('assets/icons'));
      expect(v.first.line, greaterThan(0));
      expect(v.first.column, greaterThan(0));
    });

    test('flags packages/<pkg>/assets/ prefix in interpolation', () {
      const src = r'''
void f() {
  final id = 'x';
  final p = 'packages/colonizethis_data/assets/data/$id.json';
  print(p);
}
''';
      final v = findAssetPathConstantViolationsInSource(
        relativePath: 'app/lib/widgets/foo.dart',
        source: src,
      );
      expect(v, isNotEmpty);
      expect(v.first.message, contains('packages/colonizethis_data'));
    });

    test('allows non-asset string', () {
      const src = r'''
void f() {
  final s = 'not/an/asset/path';
  print(s);
}
''';
      final v = findAssetPathConstantViolationsInSource(
        relativePath: 'app/lib/widgets/foo.dart',
        source: src,
      );
      expect(v, isEmpty);
    });

    test('does not flag app_assets.dart', () {
      const src = r'''
const String kX = 'assets/icons/x.png';
''';
      final v = findAssetPathConstantViolationsInSource(
        relativePath: 'app/lib/config/app_assets.dart',
        source: src,
      );
      expect(v, isEmpty);
    });

    test('does not flag app_constants.dart', () {
      const src = r'''
const String kPrefix = 'assets/icons/32/';
''';
      final v = findAssetPathConstantViolationsInSource(
        relativePath: 'app/lib/config/app_constants.dart',
        source: src,
      );
      expect(v, isEmpty);
    });
  });
}
