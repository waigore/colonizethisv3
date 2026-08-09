import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_screen_registry_active_paths.dart';

/// Acceptance pins for issue #4099: SYS10001 debug log viewer is registry-active
/// with a real Spec path, Implementation path, screenId binding, Widgetbook
/// folder, and remains omitted from the player game manual.
void main() {
  final repoRoot = Directory.current.path;

  group('issue #4099 SYS10001 debug log viewer activation', () {
    test('SYS10001 is active with existing implementation path', () {
      final registry = File(
        p.join(repoRoot, 'SPEC', 'ui', 'screen-registry.md'),
      ).readAsStringSync();
      final rows = parseScreenRegistryRows(registry);
      final byId = {for (final r in rows) r.id: r};

      final row = byId['SYS10001'];
      expect(row, isNotNull, reason: 'SYS10001 missing from registry');
      expect(row!.status, 'active', reason: 'SYS10001 status');
      const expectedPath =
          'app/lib/features/debug_log/debug_log_viewer_screen.dart';
      final path = extractDartPathFromCell(row.implementationCell);
      expect(path, expectedPath, reason: 'SYS10001 implementation path');
      expect(
        File(p.join(repoRoot, path!)).existsSync(),
        isTrue,
        reason: 'SYS10001 file missing: $path',
      );
      expect(
        registry.contains('| Debug Log Viewer |'),
        isTrue,
        reason: 'SYS10001 Widgetbook folder missing from registry row',
      );
      expect(
        File(
          p.join(repoRoot, 'SPEC', 'ui', 'debug-log-viewer.md'),
        ).existsSync(),
        isTrue,
        reason: 'SPEC/ui/debug-log-viewer.md missing',
      );
    });

    test('DebugLogViewerScreen binds UiScreenIds.debugLogViewer', () {
      final screenSource = File(
        p.join(
          repoRoot,
          'app',
          'lib',
          'features',
          'debug_log',
          'debug_log_viewer_screen.dart',
        ),
      ).readAsStringSync();
      expect(
        screenSource.contains(
          'static const screenId = UiScreenIds.debugLogViewer',
        ),
        isTrue,
      );

      final idsSource = File(
        p.join(repoRoot, 'app', 'lib', 'config', 'ui_screen_ids.dart'),
      ).readAsStringSync();
      expect(
        idsSource.contains("static const String debugLogViewer = 'SYS10001'"),
        isTrue,
      );
    });

    test('Widgetbook catalog registers Debug Log Viewer', () {
      final catalogPart = File(
        p.join(
          repoRoot,
          'widgetbook_host',
          'lib',
          'catalogs',
          'catalog_debug_log_viewer.dart',
        ),
      ).readAsStringSync();
      expect(catalogPart.contains("name: 'Debug Log Viewer'"), isTrue);
      expect(catalogPart.contains("name: 'Default — empty buffer'"), isTrue);
      expect(catalogPart.contains("name: 'Populated — warning rows'"), isTrue);
      expect(catalogPart.contains("name: 'Mobile viewport'"), isTrue);

      final catalog = File(
        p.join(repoRoot, 'widgetbook_host', 'lib', 'catalogs', 'catalog.dart'),
      ).readAsStringSync();
      expect(catalog.contains("part 'catalog_debug_log_viewer.dart'"), isTrue);
      expect(catalog.contains('...debugLogViewerDirectories,'), isTrue);
    });

    test('docs/manual chapters do not cite SYS10001', () {
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
          body.contains('SYS10001'),
          isFalse,
          reason: p.relative(chapter.path, from: repoRoot),
        );
      }
    });

    test('negative: SYS10001 is not left as draft/TBD in registry', () {
      final registry = File(
        p.join(repoRoot, 'SPEC', 'ui', 'screen-registry.md'),
      ).readAsStringSync();
      final rows = parseScreenRegistryRows(registry);
      final row = rows.firstWhere((r) => r.id == 'SYS10001');
      expect(row.status, isNot('draft'));
      expect(row.implementationCell.trim(), isNot('TBD'));
      expect(extractDartPathFromCell(row.implementationCell), isNotNull);
      expect(
        registry.contains('[debug-log-viewer.md](debug-log-viewer.md)'),
        isTrue,
        reason: 'SYS10001 Spec column must link UI screen doc',
      );
    });
  });
}
