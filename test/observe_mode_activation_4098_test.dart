import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_screen_registry_active_paths.dart';

/// Acceptance pins for issue #4098: OVL60001 observe mode is registry-active
/// with a real Implementation path, screenId binding, Widgetbook folder, and
/// remains omitted from the player game manual.
void main() {
  final repoRoot = Directory.current.path;

  group('issue #4098 OVL60001 observe mode activation', () {
    test('OVL60001 is active with existing implementation path', () {
      final registry = File(
        p.join(repoRoot, 'SPEC', 'ui', 'screen-registry.md'),
      ).readAsStringSync();
      final rows = parseScreenRegistryRows(registry);
      final byId = {for (final r in rows) r.id: r};

      final row = byId['OVL60001'];
      expect(row, isNotNull, reason: 'OVL60001 missing from registry');
      expect(row!.status, 'active', reason: 'OVL60001 status');
      const expectedPath =
          'app/lib/features/game/widgets/panels/observe_mode_not_defined_panel.dart';
      final path = extractDartPathFromCell(row.implementationCell);
      expect(path, expectedPath, reason: 'OVL60001 implementation path');
      expect(
        File(p.join(repoRoot, path!)).existsSync(),
        isTrue,
        reason: 'OVL60001 file missing: $path',
      );
      expect(
        registry.contains('| Observe Mode Not Defined Panel |'),
        isTrue,
        reason: 'OVL60001 Widgetbook folder missing from registry row',
      );
    });

    test('ObserveModeNotDefinedPanel binds UiScreenIds.observeModeOverlay', () {
      final panelSource = File(
        p.join(
          repoRoot,
          'app',
          'lib',
          'features',
          'game',
          'widgets',
          'panels',
          'observe_mode_not_defined_panel.dart',
        ),
      ).readAsStringSync();
      expect(
        panelSource.contains('static const screenId = UiScreenIds.observeModeOverlay'),
        isTrue,
      );
      expect(panelSource.contains("UiScreenIds.observeModeOverlay"), isTrue);

      final idsSource = File(
        p.join(repoRoot, 'app', 'lib', 'config', 'ui_screen_ids.dart'),
      ).readAsStringSync();
      expect(
        idsSource.contains("static const String observeModeOverlay = 'OVL60001'"),
        isTrue,
      );
    });

    test('Widgetbook catalog registers Observe Mode Not Defined Panel', () {
      final catalogPart = File(
        p.join(
          repoRoot,
          'widgetbook_host',
          'lib',
          'catalogs',
          'catalog_observe_mode.dart',
        ),
      ).readAsStringSync();
      expect(catalogPart.contains("name: 'Observe Mode Not Defined Panel'"), isTrue);

      final catalog = File(
        p.join(repoRoot, 'widgetbook_host', 'lib', 'catalogs', 'catalog.dart'),
      ).readAsStringSync();
      expect(catalog.contains("part 'catalog_observe_mode.dart'"), isTrue);
      expect(
        catalog.contains('...observeModeNotDefinedPanelDirectories,'),
        isTrue,
      );
    });

    test('docs/manual chapters do not cite OVL60001', () {
      final chapters = Directory(p.join(repoRoot, 'docs', 'manual'))
          .listSync()
          .whereType<File>()
          .where((f) {
            final name = p.basename(f.path);
            return RegExp(r'^\d{2}-.+\.md$').hasMatch(name);
          });

      expect(chapters, isNotEmpty, reason: 'expected numbered manual chapters');
      for (final chapter in chapters) {
        final body = chapter.readAsStringSync();
        expect(
          body.contains('OVL60001'),
          isFalse,
          reason: p.relative(chapter.path, from: repoRoot),
        );
      }
    });

    test('negative: OVL60001 is not left as draft/TBD in registry', () {
      final registry = File(
        p.join(repoRoot, 'SPEC', 'ui', 'screen-registry.md'),
      ).readAsStringSync();
      final rows = parseScreenRegistryRows(registry);
      final row = rows.firstWhere((r) => r.id == 'OVL60001');
      expect(row.status, isNot('draft'));
      expect(row.implementationCell.trim(), isNot('TBD'));
      expect(extractDartPathFromCell(row.implementationCell), isNotNull);
    });
  });
}
