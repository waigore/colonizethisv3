import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_commodity_l10n_coverage.dart';

void main() {
  group('catalogCommodityIdsFromSource', () {
    test('extracts raw camelCase catalog ids', () {
      const source = '''
class CommodityCatalog {
  static const Commodity grain = Commodity(id: 'grain', category: CommodityCategory.food);
  static const Commodity sugarCane = Commodity(id: 'sugarCane', category: CommodityCategory.rawMaterial);
}
''';
      expect(
        catalogCommodityIdsFromSource(source),
        ['grain', 'sugarCane'],
      );
    });
  });

  group('runCheckCommodityL10nCoverage', () {
    test('passes against the live repo catalog and ARB', () {
      final errors = <String>[];
      final exitCode = runCheckCommodityL10nCoverage(
        Directory.current.path,
        info: (_) {},
        err: errors.add,
      );
      expect(exitCode, 0, reason: errors.join('\n'));
    });

    test('fails when a catalog id lacks an ARB key', () {
      final temp = Directory.systemTemp.createTempSync('commodity-l10n-');
      try {
        final catalogDir = Directory(
          p.join(
            temp.path,
            'packages',
            'colonizethis_data',
            'lib',
            'src',
          ),
        )..createSync(recursive: true);
        File(p.join(catalogDir.path, 'commodities.dart')).writeAsStringSync(
          "static const Commodity grain = Commodity(id: 'grain');\n"
          "static const Commodity sugarCane = Commodity(id: 'sugarCane');\n",
        );
        final arbDir = Directory(
          p.join(
            temp.path,
            'packages',
            'colonizethis_app_l10n',
            'lib',
            'l10n',
            'arb',
          ),
        )..createSync(recursive: true);
        File(p.join(arbDir.path, 'app_en.arb')).writeAsStringSync(
          '{\n'
          '  "@@locale": "en",\n'
          '  "commodity_grain": "Grain"\n'
          '}\n',
        );

        final errors = <String>[];
        final exitCode = runCheckCommodityL10nCoverage(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('commodity_sugarCane'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });
}
