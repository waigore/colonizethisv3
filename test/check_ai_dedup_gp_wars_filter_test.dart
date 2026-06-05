// Refs #3278 — guards `repo.ai_dedup_gp_wars_filter` enforcement.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_dedup_gp_wars_filter.dart';

void main() {
  group('repo.ai_dedup_gp_wars_filter', () {
    test('passes on real repo workspace', () {
      final repoRoot = Directory.current.path;
      final logs = <String>[];
      final code = runCheckAiDedupGpWarsFilter(
        repoRoot,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
      expect(
        logs.join('\n'),
        contains('check_ai_dedup_gp_wars_filter: no violations found.'),
      );
    });

    test('fails when a lib file inlines the GP-wars filter comprehension', () {
      final temp = Directory.systemTemp.createTempSync('ai_gp_wars_fail_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final aiLib = Directory(
        p.join(temp.path, 'packages/colonizethis_ai/lib/src/planning'),
      )..createSync(recursive: true);

      File(p.join(aiLib.path, 'inline_filter.dart')).writeAsStringSync(
        'void f(game, snapshot) {\n'
        '  final gpWars = <String>[\n'
        '    for (final factionId in snapshot.threats.atWarWith)\n'
        '      if (game.playerById(factionId) != null) factionId,\n'
        '  ];\n'
        '}\n',
      );

      final errLogs = <String>[];
      final code = runCheckAiDedupGpWarsFilter(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );

      expect(code, 1);
      expect(errLogs.join('\n'), contains('inline_filter.dart'));
      expect(errLogs.join('\n'), contains('gpFactionIdsAtWarWith'));
    });

    test('passes when files call the shared helper', () {
      final temp = Directory.systemTemp.createTempSync('ai_gp_wars_pass_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final aiLib = Directory(
        p.join(temp.path, 'packages/colonizethis_ai/lib/src/planning'),
      )..createSync(recursive: true);

      File(p.join(aiLib.path, 'uses_helper.dart')).writeAsStringSync(
        'List<String> f(game, snapshot) => gpFactionIdsAtWarWith(game, snapshot);\n',
      );

      final code = runCheckAiDedupGpWarsFilter(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });
  });
}
