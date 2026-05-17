// Refs #2521, AC12 — guards `repo.ai_planner_context` enforcement.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_planner_context.dart';

void main() {
  group('repo.ai_planner_context', () {
    test('passes on real repo workspace', () {
      final repoRoot = Directory.current.path;
      final logs = <String>[];
      final code = runCheckAiPlannerContext(
        repoRoot,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
      expect(
        logs.join('\n'),
        contains('check_ai_planner_context: no violations found.'),
      );
    });

    test('fails when a planner entrypoint has more than six parameters', () {
      final temp = Directory.systemTemp.createTempSync('ai_planner_ctx_fail_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final planningDir = Directory(
        p.join(temp.path, 'packages/colonizethis_ai/lib/src/planning'),
      )..createSync(recursive: true);

      File(p.join(planningDir.path, 'bad_planner.dart')).writeAsStringSync('''
Orders runMovePlanner({
  required String a,
  required String b,
  required String c,
  required String d,
  required String e,
  required String f,
  required String g,
}) => Orders();
''');

      final errLogs = <String>[];
      final code = runCheckAiPlannerContext(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );

      expect(code, 1);
      expect(errLogs.join('\n'), contains('runMovePlanner'));
      expect(errLogs.join('\n'), contains('PlannerContext'));
    });
  });
}
