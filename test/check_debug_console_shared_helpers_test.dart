import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_debug_console_shared_helpers.dart';

void main() {
  test('passes on the repository debug console package', () {
    final repoRoot = Directory.current.path;
    expect(runCheckDebugConsoleSharedHelpers(repoRoot), 0);
  });

  test('fails when spawn parser omits parseOptionalCount', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_debug_console_shared_helpers_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    final srcDir = Directory(
      '${temp.path}/packages/colonizethis_debug_console/lib/src',
    )..createSync(recursive: true);

    File('${srcDir.path}/debug_console_parser_helpers.dart').writeAsStringSync('''
int parseOptionalCount(List<String> tokens, int position) => 1;
({int requested, int credited, String? error}) parseAmountWithClamp(String token) =>
    (requested: 1, credited: 1, error: null);
String? canonicalIdForInput(String input, Iterable<String> candidates) => null;
''');

    File('${srcDir.path}/debug_console_command_parser.dart').writeAsStringSync('''
class DebugConsoleCommandParser {
  void _parseSpawnCivilian(List<String> tokens) {
    final count = 1;
  }
  void _parseSpawnRegiment(List<String> tokens) {
    parseOptionalCount(tokens, 3);
  }
  void _parseSpawnShip(List<String> tokens) {
    parseOptionalCount(tokens, 3);
  }
  void _parseAddMoney(List<String> tokens) {
    parseAmountWithClamp('1');
  }
  void _parseAddWorker(List<String> tokens) {
    parseAmountWithClamp('1');
  }
  void _parseAddResource(List<String> tokens) {
    parseAmountWithClamp('1');
  }
}
''');

    File('${srcDir.path}/debug_console_executor_helpers.dart').writeAsStringSync('''
void dispatchDebugConsoleSessionEvents() {}
String creditExecutorMessage({
  required String what,
  required int requestedAmount,
  required int creditedAmount,
}) => '';
''');

    File('${srcDir.path}/debug_console_command_executor.dart').writeAsStringSync('''
class DebugConsoleCommandExecutor {
  void _executeInvocation() {
    dispatchDebugConsoleSessionEvents();
  }
}
''');

    final logs = <String>[];
    final code = runCheckDebugConsoleSharedHelpers(
      temp.path,
      info: logs.add,
      err: logs.add,
    );
    expect(code, 1);
    expect(
      logs.join('\n'),
      contains('_parseSpawnCivilian must call parseOptionalCount'),
    );
  });
}
