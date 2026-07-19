/// Pins Slice B facade slim + province expected-lines section split
/// (Refs #4075 AC3 / AC4).
library;

import 'dart:io';

import 'package:colonizethis_test/test.dart';
import 'package:path/path.dart' as p;

import 'support/e2e_support_package_root.dart';

void main() {
  final libDir = Directory(p.join(e2eSupportPackageRoot().path, 'lib'));
  final supportDir = Directory(p.join(libDir.path, 'test_support'));

  group('e2e_helpers facade slim (Refs #4075 AC3)', () {
    test('facade re-exports AC1 alias topic libraries', () {
      final barrel = File(
        p.join(libDir.path, 'e2e_helpers.dart'),
      ).readAsStringSync();
      for (final export in <String>[
        "export 'e2e_helpers_aliases_ui.dart';",
        "export 'e2e_helpers_aliases_orders.dart';",
        "export 'e2e_helpers_aliases_scenario.dart';",
      ]) {
        expect(barrel, contains(export));
      }
    });

    test('facade stays under the former god-file physical size', () {
      final lines = File(
        p.join(libDir.path, 'e2e_helpers.dart'),
      ).readAsLinesSync().length;
      // Pre-slim size was 1007 physical lines.
      expect(lines, lessThanOrEqualTo(700));
    });

    test('negative: no helpers alias file re-absorbs the pre-slim size', () {
      final oversized = <String>[];
      for (final file in libDir.listSync().whereType<File>()) {
        final name = p.basename(file.path);
        if (!name.startsWith('e2e_helpers') || !name.endsWith('.dart')) {
          continue;
        }
        final lines = file.readAsLinesSync().length;
        if (lines > 700) {
          oversized.add('$name ($lines)');
        }
      }
      expect(oversized, isEmpty);
    });
  });

  group('province expected-lines section split (Refs #4075 AC4)', () {
    test('public entrypoint file parts in section libraries', () {
      final entry = File(
        p.join(supportDir.path, 'province_panel_e2e_expected_lines.dart'),
      ).readAsStringSync();
      expect(entry, contains('provincePanelWideLayoutExpectedTexts'));
      for (final part in <String>[
        "part 'province_panel_e2e_expected_lines_ctx.dart';",
        "part 'province_panel_e2e_expected_lines_political_tile.dart';",
        "part 'province_panel_e2e_expected_lines_economic.dart';",
        "part 'province_panel_e2e_expected_lines_units.dart';",
        "part 'province_panel_e2e_expected_lines_labels.dart';",
      ]) {
        expect(entry, contains(part));
      }
    });

    test('entry file stays under former physical size', () {
      final lines = File(
        p.join(supportDir.path, 'province_panel_e2e_expected_lines.dart'),
      ).readAsLinesSync().length;
      // Pre-split size was 756 physical lines.
      expect(lines, lessThanOrEqualTo(200));
    });

    test('negative: section parts exist and stay under 400 physical lines', () {
      for (final name in <String>[
        'province_panel_e2e_expected_lines_ctx.dart',
        'province_panel_e2e_expected_lines_political_tile.dart',
        'province_panel_e2e_expected_lines_economic.dart',
        'province_panel_e2e_expected_lines_units.dart',
        'province_panel_e2e_expected_lines_labels.dart',
      ]) {
        final file = File(p.join(supportDir.path, name));
        expect(file.existsSync(), isTrue, reason: '$name missing');
        expect(
          file.readAsStringSync(),
          contains("part of 'province_panel_e2e_expected_lines.dart';"),
        );
        expect(file.readAsLinesSync().length, lessThanOrEqualTo(400));
      }
    });
  });
}
