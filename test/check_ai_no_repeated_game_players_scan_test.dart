// Refs #3288 — guards `repo.ai_no_repeated_game_players_scan`.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_no_repeated_game_players_scan.dart';

const _treasuryPlannerRelative =
    'packages/colonizethis_ai/lib/src/planning/treasury_planner.dart';

File _writeTreasuryPlanner(Directory root, String body) {
  final dir = Directory(
    p.join(root.path, 'packages/colonizethis_ai/lib/src/planning'),
  )..createSync(recursive: true);
  final file = File(p.join(dir.path, 'treasury_planner.dart'))
    ..writeAsStringSync(body);
  return file;
}

void main() {
  group('repo.ai_no_repeated_game_players_scan', () {
    test('passes on real repo workspace', () {
      final repoRoot = Directory.current.path;
      final logs = <String>[];
      final code = runCheckAiNoRepeatedGamePlayersScan(
        repoRoot,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
      expect(
        logs.join('\n'),
        contains(
          'check_ai_no_repeated_game_players_scan: no violations found.',
        ),
      );
    });

    test('fails when treasury_planner iterates game.players', () {
      final temp = Directory.systemTemp.createTempSync('ai_players_scan_fail_');
      addTearDown(() => temp.deleteSync(recursive: true));

      _writeTreasuryPlanner(
        temp,
        'int totalTreasury(Game game) {\n'
        '  var total = 0;\n'
        '  for (final player in game.players) {\n'
        '    total += player.treasury;\n'
        '  }\n'
        '  return total;\n'
        '}\n',
      );

      final errLogs = <String>[];
      final code = runCheckAiNoRepeatedGamePlayersScan(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );

      expect(code, 1);
      expect(errLogs.join('\n'), contains(_treasuryPlannerRelative));
      expect(errLogs.join('\n'), contains('game.playerById'));
    });

    test('fails on game.players.where(...) aggregation comprehensions', () {
      final temp = Directory.systemTemp.createTempSync('ai_players_where_fail_');
      addTearDown(() => temp.deleteSync(recursive: true));

      _writeTreasuryPlanner(
        temp,
        'int tradeEligibleCount(Game game) =>\n'
        '    game.players.where((p) => p.treasury > 0).length;\n',
      );

      final code = runCheckAiNoRepeatedGamePlayersScan(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 1);
    });

    test('passes when treasury_planner uses game.playerById', () {
      final temp = Directory.systemTemp.createTempSync('ai_players_scan_pass_');
      addTearDown(() => temp.deleteSync(recursive: true));

      _writeTreasuryPlanner(
        temp,
        'int treasuryForPlayer(Game game, String playerId) =>\n'
        '    game.playerById(playerId)?.treasury ?? 0;\n',
      );

      final code = runCheckAiNoRepeatedGamePlayersScan(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });

    test('ignores game.players outside treasury_planner', () {
      final temp = Directory.systemTemp.createTempSync('ai_players_scan_scope_');
      addTearDown(() => temp.deleteSync(recursive: true));

      // treasury_planner clean; another planning file scans game.players
      // legitimately (e.g. economy_planner / lock-recovery rotation).
      _writeTreasuryPlanner(temp, 'void f() {}\n');
      final planningDir = Directory(
        p.join(temp.path, 'packages/colonizethis_ai/lib/src/planning'),
      );
      File(p.join(planningDir.path, 'economy_planner.dart')).writeAsStringSync(
        'int g(Game game) {\n'
        '  var n = 0;\n'
        '  for (final player in game.players) n++;\n'
        '  return n;\n'
        '}\n',
      );

      final code = runCheckAiNoRepeatedGamePlayersScan(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });

    test('errors when treasury_planner source is missing', () {
      final temp = Directory.systemTemp.createTempSync('ai_players_scan_miss_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final errLogs = <String>[];
      final code = runCheckAiNoRepeatedGamePlayersScan(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );
      expect(code, 1);
      expect(errLogs.join('\n'), contains(_treasuryPlannerRelative));
    });
  });
}
