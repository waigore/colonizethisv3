import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_source_file_size.dart';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckAiSourceFileSize', () {
    test('passes on current repo tree under 300 physical-line ceiling', () {
      expect(runCheckAiSourceFileSize('.'), 0);
    });

    test('ceiling is 300 after #4365 Slice A headroom ratchet', () {
      expect(aiSourceFileSizeCeiling, 300);
    });

    test(
      'grandfather allowlist is empty after #4079 / #4104 / #4310 / #4365 splits',
      () {
        expect(aiSourceFileSizeGrandfatheredForTests, isEmpty);
      },
    );

    test('fails when an AI lib/src file exceeds the ceiling', () {
      final root = Directory.systemTemp.createTempSync('ai_src_size_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_ai/lib/src/fat.dart',
        List.generate(12, (i) => '// line $i').join('\n'),
      );

      final errors = <String>[];
      final code = runCheckAiSourceFileSize(
        root.path,
        ceiling: 10,
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('fat.dart'));
    });

    test('skips an over-cap file listed in the grandfather allowlist', () {
      final root = Directory.systemTemp.createTempSync('ai_src_size_gf');
      addTearDown(() => root.deleteSync(recursive: true));
      const grandfatheredRel = 'packages/colonizethis_ai/lib/src/legacy.dart';
      _writeFile(
        root,
        grandfatheredRel,
        List.generate(12, (i) => '// line $i').join('\n'),
      );

      final code = runCheckAiSourceFileSize(
        root.path,
        ceiling: 10,
        grandfatheredPaths: const [grandfatheredRel],
      );
      expect(code, 0);
    });

    test('fails when a grandfather entry no longer exists', () {
      final root = Directory.systemTemp.createTempSync('ai_src_size_stale');
      addTearDown(() => root.deleteSync(recursive: true));
      Directory(
        p.join(root.path, 'packages/colonizethis_ai/lib/src'),
      ).createSync(recursive: true);

      final errors = <String>[];
      final code = runCheckAiSourceFileSize(
        root.path,
        grandfatheredPaths: const [
          'packages/colonizethis_ai/lib/src/missing.dart',
        ],
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('stale grandfather'));
    });

    test('fails when a grandfather entry is now under the ceiling', () {
      final root = Directory.systemTemp.createTempSync('ai_src_size_undercap');
      addTearDown(() => root.deleteSync(recursive: true));
      const grandfatheredRel = 'packages/colonizethis_ai/lib/src/slim.dart';
      _writeFile(
        root,
        grandfatheredRel,
        List.generate(5, (i) => '// line $i').join('\n'),
      );

      final errors = <String>[];
      final code = runCheckAiSourceFileSize(
        root.path,
        ceiling: 10,
        grandfatheredPaths: const [grandfatheredRel],
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('now under'));
    });

    test('ignores generated files over the ceiling', () {
      final root = Directory.systemTemp.createTempSync('ai_src_size_gen');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_ai/lib/src/huge.g.dart',
        List.generate(12, (i) => '// line $i').join('\n'),
      );

      final code = runCheckAiSourceFileSize(root.path, ceiling: 10);
      expect(code, 0);
    });

    test('Slice B essay hosts stay ≤260 physical lines (Refs #4530)', () {
      const hosts = <String>[
        'packages/colonizethis_ai/lib/src/planning/colonial_phase_planner_acquisition.dart',
        'packages/colonizethis_ai/lib/src/planning/expand_phase_planner_economy.dart',
        'packages/colonizethis_ai/lib/src/planning/expand_phase_planner_peace_default_start_quota.dart',
        'packages/colonizethis_ai/lib/src/planning/phase_planner_economy_filter_expand.dart',
        'packages/colonizethis_ai/lib/src/planning/expand_phase_planner_peace_targets_stalled.dart',
        'packages/colonizethis_ai/lib/src/planning/phase_priority_weights.dart',
        'packages/colonizethis_ai/lib/src/planning/develop_phase_planner.dart',
        'packages/colonizethis_ai/lib/src/planning/expand_phase_planner_peer_peace_zero_regiment.dart',
        'packages/colonizethis_ai/lib/src/planning/expand_phase_planner_gp_blocker_peace.dart',
        'packages/colonizethis_ai/lib/src/planning/expand_peace_frontier_helpers.dart',
      ];
      for (final relative in hosts) {
        final lines = File(relative).readAsLinesSync().length;
        expect(
          lines,
          lessThanOrEqualTo(260),
          reason: '$relative is $lines lines (Slice B headroom target ≤260)',
        );
      }
    });
  });
}
