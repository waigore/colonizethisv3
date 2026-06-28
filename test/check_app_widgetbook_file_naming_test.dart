import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_app_widgetbook_file_naming.dart';

void main() {
  group('isNumberedCatalogPartFileName', () {
    test('matches numbered catalog fragments', () {
      expect(isNumberedCatalogPartFileName('catalog_part1.dart'), isTrue);
      expect(isNumberedCatalogPartFileName('catalog_part9.dart'), isTrue);
      expect(isNumberedCatalogPartFileName('catalog_part12.dart'), isTrue);
    });

    test('does not match domain-named catalog files', () {
      expect(isNumberedCatalogPartFileName('catalog.dart'), isFalse);
      expect(isNumberedCatalogPartFileName('catalog_panels.dart'), isFalse);
      expect(isNumberedCatalogPartFileName('catalog_dialogs.dart'), isFalse);
      expect(isNumberedCatalogPartFileName('catalog_primitives.dart'), isFalse);
      // A descriptive name that merely contains "part" as a word is allowed.
      expect(
        isNumberedCatalogPartFileName('catalog_partner_panels.dart'),
        isFalse,
      );
    });
  });

  group('runCheckAppWidgetbookFileNaming', () {
    test('fails when a numbered catalog fragment exists', () {
      final temp = Directory.systemTemp.createTempSync('widgetbook-naming-bad-');
      try {
        _writeDartFile(
          p.join(temp.path, widgetbookCatalogDirPath, 'catalog.dart'),
          "part 'catalog_part1.dart';\n",
        );
        _writeDartFile(
          p.join(temp.path, widgetbookCatalogDirPath, 'catalog_part1.dart'),
          "part of 'catalog.dart';\n",
        );

        final errors = <String>[];
        final exitCode = runCheckAppWidgetbookFileNaming(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('catalog_part1.dart'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when all catalog parts use domain names', () {
      final temp = Directory.systemTemp.createTempSync('widgetbook-naming-ok-');
      try {
        _writeDartFile(
          p.join(temp.path, widgetbookCatalogDirPath, 'catalog.dart'),
          "part 'catalog_panels.dart';\npart 'catalog_dialogs.dart';\n",
        );
        _writeDartFile(
          p.join(temp.path, widgetbookCatalogDirPath, 'catalog_panels.dart'),
          "part of 'catalog.dart';\n",
        );
        _writeDartFile(
          p.join(temp.path, widgetbookCatalogDirPath, 'catalog_dialogs.dart'),
          "part of 'catalog.dart';\n",
        );

        final exitCode = runCheckAppWidgetbookFileNaming(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when the widgetbook directory is absent', () {
      final temp = Directory.systemTemp.createTempSync(
        'widgetbook-naming-none-',
      );
      try {
        final exitCode = runCheckAppWidgetbookFileNaming(
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
