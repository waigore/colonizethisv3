// CLI happy path: outputs and save directory. SPEC/program/game-setup-pipeline.md § Acceptance criteria.

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
  group('init_game CLI artifacts', () {
    test(
        'writes markdown, map PNG, and Hive save when outputs requested without --no-save',
        () async {
      final dir = await Directory.systemTemp.createTemp('init_game_cli_art_');
      try {
        final mdPath = p.join(dir.path, 'out.md');
        final pngPath = p.join(dir.path, 'map.png');
        final saveDir = p.join(dir.path, 'hive_save');

        final result = await Process.run(
          'dart',
          [
            'run',
            'bin/init_game.dart',
            '--great-power-count',
            '2',
            '--minor-nation-count',
            '1',
            '--tribe-count',
            '2',
            '--num-provinces-old-world',
            '20',
            '--num-provinces-new-world',
            '15',
            '--seed',
            '4242',
            '--output-markdown',
            mdPath,
            '--output-map',
            pngPath,
            '--output-game',
            saveDir,
          ],
          runInShell: false,
          workingDirectory: _packageRoot,
          stderrEncoding: utf8,
          stdoutEncoding: utf8,
        );

        expect(result.exitCode, 0, reason: result.stderr);
        final md = File(mdPath);
        expect(md.existsSync(), isTrue);
        final mdText = md.readAsStringSync();
        expect(mdText, contains('# Game Setup'));
        expect(mdText, contains('## Faction Setup'));

        final png = File(pngPath);
        expect(png.existsSync(), isTrue);
        expect(png.lengthSync(), greaterThan(0));

        final save = Directory(saveDir);
        expect(save.existsSync(), isTrue);
        expect(
          save.listSync(followLinks: false),
          isNotEmpty,
          reason: 'Hive should write at least one file under --output-game dir',
        );
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });
}
