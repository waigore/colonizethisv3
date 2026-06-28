// Refs #3393, Phase 3 — guards `repo.ai_api_narrow_surface` enforcement:
// packages/colonizethis_logic/lib/ai_api.dart must re-export sibling-domain
// symbols through the domain barrel rather than barrel-bypassing deep `src/`
// paths whenever the barrel already publishes the owning file.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_api_narrow_surface.dart';

void main() {
  group('repo.ai_api_narrow_surface', () {
    test('passes on real repo workspace', () {
      final repoRoot = Directory.current.path;
      final logs = <String>[];
      final code = runCheckAiApiNarrowSurface(
        repoRoot,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
      expect(
        logs.join('\n'),
        contains(
          'check_ai_api_narrow_surface: no barrel-bypass exports found.',
        ),
      );
    });

    test('fails when ai_api deep-exports a barrel-published file', () {
      final temp = Directory.systemTemp.createTempSync('ai_api_narrow_fail_');
      addTearDown(() => temp.deleteSync(recursive: true));

      // World barrel re-exports ai_control.dart, so the deep export bypasses it.
      _writeBarrelPackage(
        temp.path,
        'colonizethis_world',
        barrelExports: const ["export 'src/world/ai_control.dart';"],
        srcFiles: const {
          'src/world/ai_control.dart': 'bool isAiControlled() => true;',
        },
      );
      _writeAiApi(
        temp.path,
        "export 'package:colonizethis_world/src/world/ai_control.dart'\n"
        "    show isAiControlled;\n",
      );

      final errLogs = <String>[];
      final code = runCheckAiApiNarrowSurface(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );

      expect(code, 1);
      expect(
        errLogs.join('\n'),
        contains('bypasses the colonizethis_world barrel'),
      );
      expect(errLogs.join('\n'), contains('ai_api.dart:'));
    });

    test('passes when ai_api re-exports through the domain barrel', () {
      final temp = Directory.systemTemp.createTempSync('ai_api_narrow_barrel_');
      addTearDown(() => temp.deleteSync(recursive: true));

      _writeBarrelPackage(
        temp.path,
        'colonizethis_world',
        barrelExports: const ["export 'src/world/ai_control.dart';"],
        srcFiles: const {
          'src/world/ai_control.dart': 'bool isAiControlled() => true;',
        },
      );
      _writeAiApi(
        temp.path,
        "export 'package:colonizethis_world/colonizethis_world.dart'\n"
        "    show isAiControlled;\n",
      );

      final code = runCheckAiApiNarrowSurface(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });

    test('allows a deep export the barrel does not publish', () {
      final temp = Directory.systemTemp.createTempSync(
        'ai_api_narrow_deep_ok_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      // Barrel publishes only ai_control.dart; sea_reachable_provinces.dart is
      // not re-exported, so a deep export of it is the only contract surface.
      _writeBarrelPackage(
        temp.path,
        'colonizethis_world',
        barrelExports: const ["export 'src/world/ai_control.dart';"],
        srcFiles: const {
          'src/world/ai_control.dart': 'bool isAiControlled() => true;',
          'src/world/sea_reachable_provinces.dart':
              'List<String> reachable() => const [];',
        },
      );
      _writeAiApi(
        temp.path,
        "export 'package:colonizethis_world/src/world/sea_reachable_provinces.dart'\n"
        "    show reachable;\n",
      );

      final code = runCheckAiApiNarrowSurface(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });

    test('flags a file reachable transitively through a sub-barrel', () {
      final temp = Directory.systemTemp.createTempSync('ai_api_narrow_trans_');
      addTearDown(() => temp.deleteSync(recursive: true));

      // orders barrel -> src/orders/orders.dart -> draft_orders_mutations.dart.
      _writeBarrelPackage(
        temp.path,
        'colonizethis_orders',
        barrelExports: const ["export 'src/orders/orders.dart';"],
        srcFiles: const {
          'src/orders/orders.dart': "export 'draft_orders_mutations.dart';",
          'src/orders/draft_orders_mutations.dart': 'void apply() {}',
        },
      );
      _writeAiApi(
        temp.path,
        "export 'package:colonizethis_orders/src/orders/draft_orders_mutations.dart'\n"
        "    show apply;\n",
      );

      final code = runCheckAiApiNarrowSurface(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 1);
    });

    test('fails when ai_api.dart is missing', () {
      final temp = Directory.systemTemp.createTempSync(
        'ai_api_narrow_missing_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      final errLogs = <String>[];
      final code = runCheckAiApiNarrowSurface(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );

      expect(code, 1);
      expect(errLogs.join('\n'), contains('Missing AI contract file'));
    });
  });
}

void _writeAiApi(String repoRoot, String exportsBody) {
  final dir = Directory(
    p.join(repoRoot, 'packages', 'colonizethis_logic', 'lib'),
  )..createSync(recursive: true);
  File(
    p.join(dir.path, 'ai_api.dart'),
  ).writeAsStringSync('library;\n\n$exportsBody');
}

void _writeBarrelPackage(
  String repoRoot,
  String pkg, {
  required List<String> barrelExports,
  required Map<String, String> srcFiles,
}) {
  final libDir = Directory(p.join(repoRoot, 'packages', pkg, 'lib'))
    ..createSync(recursive: true);
  File(
    p.join(libDir.path, '$pkg.dart'),
  ).writeAsStringSync('library $pkg;\n\n${barrelExports.join('\n')}\n');
  srcFiles.forEach((relative, contents) {
    final file = File(p.join(libDir.path, relative))
      ..parent.createSync(recursive: true);
    file.writeAsStringSync(contents);
  });
}
