// CLI error handling: config that causes runInitGame/setup to throw exits with clear message.
// SPEC/program/init-game-tool.md (Constraints: error handling).

import 'dart:convert';
import 'dart:io';
import 'package:colonizethis_test/test.dart';

import 'package:path/path.dart' as p;

/// Package root: tool/init_game. Works when run from package dir or repo root.
String get _packageRoot {
  final cwd = Directory.current.path;
  final inPackage = File(p.join(cwd, 'bin', 'init_game.dart')).existsSync();
  return inPackage ? cwd : p.join(cwd, 'tool', 'init_game');
}

void main() {
  group('init_game CLI', () {
    test('exits with non-zero and clear message when setup fails (too few OW provinces)', () async {
      final dir = await Directory.systemTemp.createTemp('init_game_test_');
      try {
        // Config with 1 OW province but default 6 GPs: setup may throw (provinces or sea-bound).
        final configFile = File('${dir.path}/config.json');
        await configFile.writeAsString('''
{
  "numProvincesOldWorld": 1,
  "numProvincesNewWorld": 5
}
''');
        final result = await Process.run(
          'dart',
          ['run', 'bin/init_game.dart', '--config', configFile.path, '--no-save'],
          runInShell: false,
          workingDirectory: _packageRoot,
          stderrEncoding: utf8,
          stdoutEncoding: utf8,
        );
        expect(result.exitCode, 1, reason: 'CLI should exit 1 on setup failure');
        final err = result.stderr as String;
        expect(err, contains('Error:'), reason: 'User-facing error message');
        expect(err, isNot(contains('package:')), reason: 'No raw stack trace to user');
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('config file not found exits 1 with clear message', () async {
      final result = await Process.run(
        'dart',
        ['run', 'bin/init_game.dart', '--config', '/nonexistent/config.json', '--no-save'],
        runInShell: false,
        workingDirectory: _packageRoot,
        stderrEncoding: utf8,
        stdoutEncoding: utf8,
      );
      expect(result.exitCode, 1);
      expect(result.stderr, contains('Error:'));
      expect(result.stderr, contains('not found'));
    });
  });
}
