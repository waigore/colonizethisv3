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
    test(
      'exits with non-zero and clear message when CLI validation fails',
      () async {
        final result = await Process.run(
          'dart',
          [
            'run',
            'bin/init_game.dart',
            '--great-powers',
            'prussia',
            '--prussia-leader',
            'invalid_variant',
            '--no-save',
          ],
          runInShell: false,
          workingDirectory: _packageRoot,
          stderrEncoding: utf8,
          stdoutEncoding: utf8,
        );
        expect(
          result.exitCode,
          1,
          reason: 'CLI should exit 1 on validation failure',
        );
        final err = result.stderr as String;
        expect(err, contains('Error:'), reason: 'User-facing error message');
        expect(
          err,
          isNot(contains('package:')),
          reason: 'No raw stack trace to user',
        );
      },
    );

    test('config file not found exits 1 with clear message', () async {
      final result = await Process.run(
        'dart',
        [
          'run',
          'bin/init_game.dart',
          '--config',
          '/nonexistent/config.json',
          '--no-save',
        ],
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
