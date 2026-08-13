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
      // Pre-slim size was 1007 physical lines; post-#4344 lib cap is 300.
      expect(lines, lessThanOrEqualTo(300));
    });

    test('negative: no helpers alias file re-absorbs the pre-slim size', () {
      final oversized = <String>[];
      for (final file in libDir.listSync().whereType<File>()) {
        final name = p.basename(file.path);
        if (!name.startsWith('e2e_helpers') || !name.endsWith('.dart')) {
          continue;
        }
        final lines = file.readAsLinesSync().length;
        if (lines > 300) {
          oversized.add('$name ($lines)');
        }
      }
      expect(oversized, isEmpty);
    });
  });

  group('province expected-lines section split (Refs #4075 AC4 / #4344 Slice A)', () {
    test('public entrypoint imports section libraries (no part directives)', () {
      final entry = File(
        p.join(supportDir.path, 'province_panel_e2e_expected_lines.dart'),
      ).readAsStringSync();
      expect(entry, contains('provincePanelWideLayoutExpectedTexts'));
      expect(RegExp(r"^\s*part\s+", multiLine: true).hasMatch(entry), isFalse);
      for (final imp in <String>[
        "import 'province_panel_e2e_expected_lines_ctx.dart';",
        "import 'province_panel_e2e_expected_lines_political_tile.dart';",
        "import 'province_panel_e2e_expected_lines_economic.dart';",
        "import 'province_panel_e2e_expected_lines_units.dart';",
        "import 'province_panel_e2e_expected_lines_labels.dart';",
      ]) {
        expect(entry, contains(imp));
      }
    });

    test('entry file stays under former physical size', () {
      final lines = File(
        p.join(supportDir.path, 'province_panel_e2e_expected_lines.dart'),
      ).readAsLinesSync().length;
      // Pre-split size was 756 physical lines.
      expect(lines, lessThanOrEqualTo(200));
    });

    test('negative: section libraries exist, stay ≤300 lines, and are not parts', () {
      for (final name in <String>[
        'province_panel_e2e_expected_lines_ctx.dart',
        'province_panel_e2e_expected_lines_political_tile.dart',
        'province_panel_e2e_expected_lines_economic.dart',
        'province_panel_e2e_expected_lines_units.dart',
        'province_panel_e2e_expected_lines_labels.dart',
      ]) {
        final file = File(p.join(supportDir.path, name));
        expect(file.existsSync(), isTrue, reason: '$name missing');
        final body = file.readAsStringSync();
        expect(
          RegExp(r"^\s*part\s+of\s+", multiLine: true).hasMatch(body),
          isFalse,
        );
        expect(file.readAsLinesSync().length, lessThanOrEqualTo(300));
      }
    });
  });
}
