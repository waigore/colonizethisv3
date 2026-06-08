import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_logic_all_provinces_sanctioned_calls.dart';

/// Builds a minimal temp repo root with both scanned package trees plus a
/// `tool/logic_all_provinces_sanctions.yaml` allowlist, then runs the checker.
({int code, List<String> errs}) _runInTempRepo({
  required Map<String, List<String>> filesByRelativePath,
  required String sanctionsYaml,
}) {
  final tempDir = Directory.systemTemp.createTempSync('all_provinces_gate_');
  try {
    // Both scanned roots must exist or the checker errors out early.
    Directory(
      p.join(tempDir.path, 'packages/colonizethis_logic/lib/src'),
    ).createSync(recursive: true);
    Directory(
      p.join(tempDir.path, 'packages/colonizethis_orders/lib/src'),
    ).createSync(recursive: true);

    final yamlFile = File(
      p.join(tempDir.path, 'tool/logic_all_provinces_sanctions.yaml'),
    )..createSync(recursive: true);
    yamlFile.writeAsStringSync(sanctionsYaml);

    filesByRelativePath.forEach((relative, lines) {
      final file = File(p.join(tempDir.path, relative))
        ..createSync(recursive: true);
      file.writeAsStringSync('${lines.join('\n')}\n');
    });

    final errs = <String>[];
    final code = runCheckLogicAllProvincesSanctionedCalls(
      tempDir.path,
      info: (_) {},
      err: errs.add,
    );
    return (code: code, errs: errs);
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}

void main() {
  group('logicSourceLineContainsAllProvincesCall', () {
    test('detects top-level allProvinces(', () {
      expect(
        logicSourceLineContainsAllProvincesCall(
          'for (final p in allProvinces(game.worldState)) {',
        ),
        isTrue,
      );
    });

    test('detects WorldState.allProvinces()', () {
      expect(
        logicSourceLineContainsAllProvincesCall(
          'for (final p in game.worldState.allProvinces()) {',
        ),
        isTrue,
      );
    });

    test('ignores province id substring', () {
      expect(
        logicSourceLineContainsAllProvincesCall(
          'final id = "oldWorld|all_provinces_ignored";',
        ),
        isFalse,
      );
    });
  });

  test('current repo passes allProvinces sanction gate', () {
    expect(runCheckLogicAllProvincesSanctionedCalls('.', info: (_) {}), 0);
  });

  group('colonizethis_orders tree is in scope (Refs #3290)', () {
    const ordersFile =
        'packages/colonizethis_orders/lib/src/orders/order_suggestion_x.dart';

    test('sanctioned orders call site passes', () {
      final result = _runInTempRepo(
        filesByRelativePath: {
          ordersFile: [
            'void f() {',
            '  for (final p in allProvinces(w)) {}',
            '}',
          ],
        },
        sanctionsYaml:
            'version: 1\nsanctions:\n  - path: $ordersFile\n    line: 2\n',
      );
      expect(result.code, 0);
    });

    test('unsanctioned orders call site fails and is reported', () {
      final result = _runInTempRepo(
        filesByRelativePath: {
          ordersFile: [
            'void f() {',
            '  for (final p in allProvinces(w)) {}',
            '}',
          ],
        },
        sanctionsYaml: 'version: 1\nsanctions: []\n',
      );
      expect(result.code, 1);
      expect(result.errs.any((e) => e.contains('$ordersFile:2')), isTrue);
    });

    test('stale orders sanction (call moved away) fails and is reported', () {
      final result = _runInTempRepo(
        filesByRelativePath: {
          ordersFile: ['void f() {', '  // no broad iteration here', '}'],
        },
        sanctionsYaml:
            'version: 1\nsanctions:\n  - path: $ordersFile\n    line: 2\n',
      );
      expect(result.code, 1);
      expect(result.errs.any((e) => e.contains('$ordersFile:2')), isTrue);
    });
  });
}
