import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_debug_console_logic_contract_boundary.dart';

void main() {
  group('runCheckDebugConsoleLogicContractBoundary', () {
    test('passes when debug console imports only approved logic contract', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_debug_console_logic_contract_boundary_pass_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      _writeRulesYaml(temp.path);
      _writeDartFile(
        temp.path,
        'packages/colonizethis_debug_console/lib/ok.dart',
        "import 'package:colonizethis_logic/debug_console_api.dart';\n",
      );

      expect(runCheckDebugConsoleLogicContractBoundary(temp.path), 0);
    });

    test('fails when debug console imports colonizethis_logic src internals', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_debug_console_logic_contract_boundary_fail_src_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      _writeRulesYaml(temp.path);
      _writeDartFile(
        temp.path,
        'packages/colonizethis_debug_console/lib/bad_src.dart',
        "import 'package:colonizethis_logic/src/turn/turn_resolver.dart';\n",
      );

      expect(runCheckDebugConsoleLogicContractBoundary(temp.path), 1);
    });

    test('honors incremental relative dart path filtering', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_debug_console_logic_contract_boundary_incremental_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      _writeRulesYaml(temp.path);
      _writeDartFile(
        temp.path,
        'packages/colonizethis_debug_console/lib/clean.dart',
        "import 'package:colonizethis_logic/debug_console_api.dart';\n",
      );
      _writeDartFile(
        temp.path,
        'packages/colonizethis_debug_console/lib/bad_barrel.dart',
        "import 'package:colonizethis_logic/colonizethis_logic.dart';\n",
      );

      final onlyClean = runCheckDebugConsoleLogicContractBoundary(
        temp.path,
        incrementalRelativeDartPaths: const [
          'packages/colonizethis_debug_console/lib/clean.dart',
        ],
      );
      expect(onlyClean, 0);

      final onlyBad = runCheckDebugConsoleLogicContractBoundary(
        temp.path,
        incrementalRelativeDartPaths: const [
          'packages/colonizethis_debug_console/lib/bad_barrel.dart',
        ],
      );
      expect(onlyBad, 1);
    });
  });
}

void _writeRulesYaml(String repoRoot) {
  final rulesFile = File(
    p.join(repoRoot, 'tool', 'disallowed_ast_patterns.yaml'),
  )..createSync(recursive: true);
  rulesFile.writeAsStringSync('''
rules:
  - id: debug_console_logic_contract_boundary
    message: import policy
    match:
      kind: scoped_package_import_contract
      scoped_relative_path_prefixes:
        - packages/colonizethis_debug_console/lib/
      package_name: colonizethis_logic
      allowed_imports:
        - package:colonizethis_logic/debug_console_api.dart
''');
}

void _writeDartFile(String repoRoot, String relativePath, String contents) {
  final file = File(p.join(repoRoot, relativePath))
    ..createSync(recursive: true);
  file.writeAsStringSync(contents);
}
