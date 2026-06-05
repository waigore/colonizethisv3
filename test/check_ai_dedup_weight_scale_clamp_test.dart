// Refs #3278 — guards `repo.ai_dedup_weight_scale_clamp` enforcement.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_dedup_weight_scale_clamp.dart';

void main() {
  group('repo.ai_dedup_weight_scale_clamp', () {
    test('passes on real repo workspace', () {
      final repoRoot = Directory.current.path;
      final logs = <String>[];
      final code = runCheckAiDedupWeightScaleClamp(
        repoRoot,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
      expect(
        logs.join('\n'),
        contains('check_ai_dedup_weight_scale_clamp: no violations found.'),
      );
    });

    test('fails when a lib file inlines the weight-scale clamp idiom', () {
      final temp = Directory.systemTemp.createTempSync('ai_weight_clamp_fail_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final aiLib = Directory(
        p.join(temp.path, 'packages/colonizethis_ai/lib/src/planning'),
      )..createSync(recursive: true);

      File(p.join(aiLib.path, 'inline_clamp.dart')).writeAsStringSync(
        'int f(double w) {\n'
        '  if (w <= 0.0) {\n'
        '    return 0;\n'
        '  }\n'
        '  final clamped = w > 1.0 ? 1.0 : w;\n'
        '  return (45 * clamped).round();\n'
        '}\n',
      );

      final errLogs = <String>[];
      final code = runCheckAiDedupWeightScaleClamp(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );

      expect(code, 1);
      expect(errLogs.join('\n'), contains('inline_clamp.dart'));
      expect(errLogs.join('\n'), contains('scaleWeightedBonus'));
    });

    test('passes when files call the shared helper', () {
      final temp = Directory.systemTemp.createTempSync('ai_weight_clamp_pass_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final aiLib = Directory(
        p.join(temp.path, 'packages/colonizethis_ai/lib/src/planning'),
      )..createSync(recursive: true);

      File(p.join(aiLib.path, 'uses_helper.dart')).writeAsStringSync(
        'int f(double w) => scaleWeightedBonus(w, 45);\n',
      );

      final code = runCheckAiDedupWeightScaleClamp(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });
  });
}
