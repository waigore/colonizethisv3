/// Pins Slice A topic splits for `e2e_test_shared` / `e2e_test_shared_panels`
/// (Refs #4075 AC1 / AC2).
library;

import 'dart:io';

import 'package:colonizethis_test/test.dart';
import 'package:path/path.dart' as p;

void main() {
  final libDir = Directory(p.join(Directory.current.path, 'lib'));

  group('e2e_test_shared topic split (Refs #4075 AC1)', () {
    test('umbrella exports residual topic libraries', () {
      final barrel = File(
        p.join(libDir.path, 'e2e_test_shared.dart'),
      ).readAsStringSync();
      for (final export in <String>[
        "export 'e2e_test_shared_intro.dart';",
        "export 'e2e_test_shared_bottom_sheet.dart';",
        "export 'e2e_test_shared_hit_testable.dart';",
        "export 'e2e_test_shared_civilian_taps.dart';",
        "export 'e2e_test_shared_dismiss_transient_ui.dart';",
        "export 'e2e_test_shared_move_dialog_finders.dart';",
        "export 'e2e_test_shared_panels.dart';",
      ]) {
        expect(barrel, contains(export));
      }
    });

    test('umbrella stays under the former god-file physical size', () {
      final lines = File(
        p.join(libDir.path, 'e2e_test_shared.dart'),
      ).readAsLinesSync().length;
      // Pre-split size was 1456 physical lines; topic extraction must leave a
      // thin barrel + pump/perf core well under that ceiling.
      expect(lines, lessThanOrEqualTo(700));
    });

    test('negative: no shared topic library re-absorbs the pre-split size', () {
      final oversized = <String>[];
      for (final file in libDir.listSync().whereType<File>()) {
        final name = p.basename(file.path);
        if (!name.startsWith('e2e_test_shared') || !name.endsWith('.dart')) {
          continue;
        }
        final lines = file.readAsLinesSync().length;
        if (lines > 1000) {
          oversized.add('$name ($lines)');
        }
      }
      expect(oversized, isEmpty);
    });
  });

  group('e2e_test_shared_panels topic split (Refs #4075 AC1 / AC2)', () {
    test(
      'panels umbrella exports production/fleet/explore topic libraries',
      () {
        final barrel = File(
          p.join(libDir.path, 'e2e_test_shared_panels.dart'),
        ).readAsStringSync();
        for (final export in <String>[
          "export 'e2e_test_shared_production_panel.dart';",
          "export 'e2e_test_shared_split_home_fleet.dart';",
          "export 'e2e_test_shared_naval_move.dart';",
          "export 'e2e_test_shared_explore_assign.dart';",
        ]) {
          expect(barrel, contains(export));
        }
      },
    );

    test('panels umbrella stays under the former god-file physical size', () {
      final lines = File(
        p.join(libDir.path, 'e2e_test_shared_panels.dart'),
      ).readAsLinesSync().length;
      // Pre-split size was 1379 physical lines.
      expect(lines, lessThanOrEqualTo(700));
    });

    test('negative: panels topic libraries exist as distinct files', () {
      for (final name in <String>[
        'e2e_test_shared_production_panel.dart',
        'e2e_test_shared_split_home_fleet.dart',
        'e2e_test_shared_naval_move.dart',
        'e2e_test_shared_explore_assign.dart',
      ]) {
        final file = File(p.join(libDir.path, name));
        expect(file.existsSync(), isTrue, reason: '$name missing');
        expect(file.readAsLinesSync(), isNotEmpty);
      }
    });
  });
}
