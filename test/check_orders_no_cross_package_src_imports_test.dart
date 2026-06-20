// Refs #3543 — guards `repo.orders_no_cross_package_src_imports`:
// `colonizethis_orders/lib/**` must not deep-import another colonizethis
// package's `lib/src/**` tree; cross-package symbols route through the owning
// package's public barrel.
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_orders_no_cross_package_src_imports.dart';

void _writeOrdersLibFile(String root, String relative, String contents) {
  final file = File(
    p.join(root, 'packages', 'colonizethis_orders', 'lib', relative),
  )..parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
}

void main() {
  group('repo.orders_no_cross_package_src_imports', () {
    test('passes on the real repo workspace', () {
      final logs = <String>[];
      final code = runCheckOrdersNoCrossPackageSrcImports(
        Directory.current.path,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });

    test('fails on a deep src import of a sibling colonizethis package', () {
      final temp = Directory.systemTemp.createTempSync('orders_src_bad_');
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeOrdersLibFile(
        temp.path,
        'src/orders/order_suggestion_helpers.dart',
        "import 'package:colonizethis_world/src/world/sea_reachable_provinces.dart';\n",
      );

      final errLogs = <String>[];
      final code = runCheckOrdersNoCrossPackageSrcImports(
        temp.path,
        err: errLogs.add,
      );
      expect(code, 1);
      expect(
        errLogs.join('\n'),
        contains('src/world/sea_reachable_provinces.dart'),
      );
    });

    test('allows barrel imports and self-package src imports', () {
      final temp = Directory.systemTemp.createTempSync('orders_src_ok_');
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeOrdersLibFile(
        temp.path,
        'src/orders/order_suggestion_helpers.dart',
        "import 'package:colonizethis_world/colonizethis_world.dart';\n"
        "import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';\n"
        "import 'package:colonizethis_orders/src/orders/internal_helper.dart';\n"
        "import 'order_suggestion_naval.dart';\n",
      );

      final code = runCheckOrdersNoCrossPackageSrcImports(
        temp.path,
        err: (_) {},
      );
      expect(code, 0);
    });

    test('skips generated files', () {
      final temp = Directory.systemTemp.createTempSync('orders_src_gen_');
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeOrdersLibFile(
        temp.path,
        'src/orders/order_engine.g.dart',
        "import 'package:colonizethis_world/src/world/sea_reachable_provinces.dart';\n",
      );

      final code = runCheckOrdersNoCrossPackageSrcImports(
        temp.path,
        err: (_) {},
      );
      expect(code, 0);
    });

    test('fails when the orders lib tree is missing', () {
      final temp = Directory.systemTemp.createTempSync('orders_src_missing_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final errLogs = <String>[];
      final code = runCheckOrdersNoCrossPackageSrcImports(
        temp.path,
        err: errLogs.add,
      );
      expect(code, 1);
      expect(errLogs.join('\n'), contains('missing'));
    });
  });
}
