/// Pins Slice A topic splits for `e2e_test_shared` / `e2e_test_shared_panels`
/// (Refs #4075 AC1 / AC2).
library;

import 'dart:io';

import 'package:colonizethis_test/test.dart';
import 'package:path/path.dart' as p;

import 'support/e2e_support_package_root.dart';

void main() {
  final libDir = Directory(p.join(e2eSupportPackageRoot().path, 'lib'));

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
      expect(lines, lessThanOrEqualTo(400));
    });

    test('negative: no shared topic library re-absorbs the pre-split size', () {
      final oversized = <String>[];
      for (final file in libDir.listSync().whereType<File>()) {
        final name = p.basename(file.path);
        if (!name.startsWith('e2e_test_shared') || !name.endsWith('.dart')) {
          continue;
        }
        final lines = file.readAsLinesSync().length;
        if (lines > 400) {
          oversized.add('$name ($lines)');
        }
      }
      expect(oversized, isEmpty);
    });
  });

  group('e2e_test_shared_panels topic split (Refs #4075 AC1 / AC2)', () {
    test('panels umbrella exports production/fleet/explore topic libraries', () {
        final barrel = File(
          p.join(libDir.path, 'e2e_test_shared_panels.dart'),
        ).readAsStringSync();
        for (final export in <String>[
          "export 'e2e_test_shared_production_panel.dart';",
          "export 'e2e_test_shared_split_home_fleet.dart';",
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
      expect(lines, lessThanOrEqualTo(400));
    });

    test('negative: panels topic libraries exist as distinct files', () {
      for (final name in <String>[
        'e2e_test_shared_production_panel.dart',
        'e2e_test_shared_split_home_fleet.dart',
        'e2e_test_shared_explore_assign.dart',
      ]) {
        final file = File(p.join(libDir.path, name));
        expect(file.existsSync(), isTrue, reason: '$name missing');
        expect(file.readAsLinesSync(), isNotEmpty);
      }
    });

    test('naval move topic split exports sibling modules (Refs #4195)', () {
      final barrel = File(
        p.join(libDir.path, 'e2e_test_shared_naval_move.dart'),
      ).readAsStringSync();
      for (final export in <String>[
        "export 'e2e_test_shared_naval_move_tap.dart';",
        "export 'e2e_test_shared_naval_move_pick.dart';",
        "export 'e2e_test_shared_naval_move_segment.dart';",
      ]) {
        expect(barrel, contains(export));
      }
      for (final name in <String>[
        'e2e_test_shared_naval_move_tap.dart',
        'e2e_test_shared_naval_move_pick.dart',
        'e2e_test_shared_naval_move_segment.dart',
      ]) {
        final file = File(p.join(libDir.path, name));
        expect(file.existsSync(), isTrue, reason: '$name missing');
        final lines = file.readAsLinesSync().length;
        expect(lines, lessThanOrEqualTo(400), reason: '$name still over slice-A cap');
      }
    });

    test('slice B residual lib files stay under 400 physical lines (Refs #4195)', () {
      for (final name in <String>[
        'e2e_test_shared.dart',
        'e2e_test_shared_adaptive_polling.dart',
        'e2e_test_shared_explore_assign.dart',
        'e2e_test_shared_explore_assign_sweep.dart',
        'e2e_test_shared_explore_assign_bundled.dart',
        'test_support/civilian_units_panel_e2e_expected_lines.dart',
        'test_support/civilian_units_panel_e2e_expected_lines_assigned.dart',
        'test_support/civilian_units_panel_e2e_expected_lines_rows.dart',
      ]) {
        final file = File(p.join(libDir.path, name));
        expect(file.existsSync(), isTrue, reason: '$name missing');
        final lines = file.readAsLinesSync().length;
        expect(lines, lessThanOrEqualTo(400), reason: '$name still over slice-B cap');
      }
    });

    test('explore assign topic split exports sibling modules (Refs #4195 slice B)', () {
      final barrel = File(
        p.join(libDir.path, 'e2e_test_shared_explore_assign.dart'),
      ).readAsStringSync();
      for (final export in <String>[
        "export 'e2e_test_shared_explore_assign_sweep.dart';",
        "export 'e2e_test_shared_explore_assign_bundled.dart';",
      ]) {
        expect(barrel, contains(export));
      }
    });

    test('shared umbrella exports adaptive polling sibling (Refs #4195 slice B)', () {
      final barrel = File(
        p.join(libDir.path, 'e2e_test_shared.dart'),
      ).readAsStringSync();
      expect(
        barrel,
        contains("export 'e2e_test_shared_adaptive_polling.dart';"),
      );
    });

    test('slice D test mirror files stay under 500 physical lines (Refs #4195)', () {
      final testDir = Directory(p.join(e2eSupportPackageRoot().path, 'test'));
      final oversized = <String>[];
      for (final file in testDir.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        final lines = file.readAsLinesSync().length;
        if (lines > 500) {
          oversized.add('${p.relative(file.path, from: testDir.path)} ($lines)');
        }
      }
      expect(oversized, isEmpty, reason: 'All test files must be ≤500 lines');
    });
  });
}
