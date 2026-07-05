import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_app_widgetbook_catalog_location.dart';

void main() {
  group('runCheckAppWidgetbookCatalogLocation', () {
    test('fails when catalog files remain under app/lib', () {
      final temp = Directory.systemTemp.createTempSync('widgetbook-loc-bad-');
      try {
        _writeDartFile(
          p.join(temp.path, appLibDirPath, 'widgetbook', 'catalog.dart'),
          'void main() {}\n',
        );

        final errors = <String>[];
        final exitCode = runCheckAppWidgetbookCatalogLocation(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('catalog.dart'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when catalogs live only under widgetbook_host', () {
      final temp = Directory.systemTemp.createTempSync('widgetbook-loc-ok-');
      try {
        _writeDartFile(
          p.join(temp.path, appLibDirPath, 'widgetbook.dart'),
          "export 'package:widgetbook_host/catalogs/catalog.dart';\n",
        );
        _writeDartFile(
          p.join(temp.path, widgetbookCatalogDirPath, 'catalog.dart'),
          "part 'catalog_panels.dart';\n",
        );

        final exitCode = runCheckAppWidgetbookCatalogLocation(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });
}

void _writeDartFile(String path, String content) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(content);
}
