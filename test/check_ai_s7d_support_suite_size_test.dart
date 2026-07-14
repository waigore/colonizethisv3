import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_s7d_support_suite_size.dart';

void main() {
  group('runCheckAiS7dSupportSuiteSize', () {
    test('fails when an S7D support module exceeds the soft ceiling', () {
      final temp = Directory.systemTemp.createTempSync('ai-s7d-over-');
      try {
        _writeS7dModule(
          temp,
          'lock_recovery_probes.dart',
          List<String>.filled(
            aiS7dSupportSuitePhysicalLineCeiling + 2,
            '// pad',
          ).join('\n'),
        );
        final errors = <String>[];
        final exitCode = runCheckAiS7dSupportSuiteSize(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('lock_recovery_probes.dart'));
        expect(
          errors.join('\n'),
          contains('$aiS7dSupportSuitePhysicalLineCeiling'),
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when every S7D support module is under the soft ceiling', () {
      final temp = Directory.systemTemp.createTempSync('ai-s7d-ok-');
      try {
        _writeS7dModule(
          temp,
          'run_seed42_s7d_diagnostic_campaign.dart',
          'void run() {}\n',
        );
        final exitCode = runCheckAiS7dSupportSuiteSize(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });
}

void _writeS7dModule(Directory temp, String basename, String body) {
  final dir = Directory(
    p.join(
      temp.path,
      'packages',
      'colonizethis_ai',
      'test',
      'support',
      's7d',
    ),
  )..createSync(recursive: true);
  File(p.join(dir.path, basename)).writeAsStringSync(body);
}
