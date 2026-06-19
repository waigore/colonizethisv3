import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_orders_no_part_directives.dart';

void main() {
  group('runCheckOrdersNoPartDirectives', () {
    test('fails for a `part` parent directive in orders lib', () {
      final temp = Directory.systemTemp.createTempSync(
        'orders-no-part-parent-',
      );
      try {
        final ordersLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_orders', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(ordersLib.path, 'parent.dart'),
          "// header\npart 'child.dart';\nvoid x() {}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckOrdersNoPartDirectives(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('parent.dart:2'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails for a `part of` fragment directive in orders lib', () {
      final temp = Directory.systemTemp.createTempSync('orders-no-part-frag-');
      try {
        final ordersLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_orders', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(ordersLib.path, 'child.dart'),
          "part of 'parent.dart';\nvoid x() {}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckOrdersNoPartDirectives(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('child.dart:1'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes for an orders lib library file with explicit imports', () {
      final temp = Directory.systemTemp.createTempSync('orders-no-part-ok-');
      try {
        final ordersLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_orders', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(ordersLib.path, 'lib_file.dart'),
          "import 'helpers.dart';\n\nfinal participants = <String>[];\nvoid x() {}\n",
        );

        final exitCode = runCheckOrdersNoPartDirectives(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('ignores `part of` outside the orders package lib', () {
      final temp = Directory.systemTemp.createTempSync('orders-no-part-other-');
      try {
        final otherLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_map', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(otherLib.path, 'child.dart'),
          "part of 'parent.dart';\nvoid x() {}\n",
        );

        final exitCode = runCheckOrdersNoPartDirectives(
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

  group('ordersNoPartDirectivesLineIsPartDirective', () {
    test('matches part and part of directive forms', () {
      expect(
        ordersNoPartDirectivesLineIsPartDirective("part 'a.dart';"),
        isTrue,
      );
      expect(
        ordersNoPartDirectivesLineIsPartDirective("part of 'a.dart';"),
        isTrue,
      );
      expect(
        ordersNoPartDirectivesLineIsPartDirective('part of "a.dart";'),
        isTrue,
      );
    });

    test('does not match identifiers that start with part', () {
      expect(
        ordersNoPartDirectivesLineIsPartDirective('participants.add(x);'),
        isFalse,
      );
      expect(
        ordersNoPartDirectivesLineIsPartDirective('final partition = 1;'),
        isFalse,
      );
    });
  });
}

void _writeDartFile(String path, String content) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(content);
}
