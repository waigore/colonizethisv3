import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_screen_registry_active_paths.dart';

/// Acceptance pins for issue #4100: SYS20001 debug console is registry-active
/// with a real Implementation path, screenId binding, Widgetbook folder, and
/// remains omitted from the player game manual.
void main() {
  final repoRoot = Directory.current.path;

  group('issue #4100 SYS20001 debug console activation', () {
    test('SYS20001 is active with existing implementation path', () {
      final registry = File(
        p.join(repoRoot, 'SPEC', 'ui', 'screen-registry.md'),
      ).readAsStringSync();
      final rows = parseScreenRegistryRows(registry);
      final byId = {for (final r in rows) r.id: r};

      final row = byId['SYS20001'];
      expect(row, isNotNull, reason: 'SYS20001 missing from registry');
      expect(row!.status, 'active', reason: 'SYS20001 status');
      const expectedPath =
          'app/lib/features/game/flame/overlays/debug_console_overlay_panel.dart';
      final path = extractDartPathFromCell(row.implementationCell);
      expect(path, expectedPath, reason: 'SYS20001 implementation path');
      expect(
        File(p.join(repoRoot, path!)).existsSync(),
        isTrue,
        reason: 'SYS20001 file missing: $path',
      );
      expect(
        registry.contains('| Debug Console Panel |'),
        isTrue,
        reason: 'SYS20001 Widgetbook folder missing from registry row',
      );
    });

    test('DebugConsoleOverlayPanel binds UiScreenIds.debugConsolePanel', () {
      final panelSource = File(
        p.join(
          repoRoot,
          'app',
          'lib',
          'features',
          'game',
          'flame',
          'overlays',
          'debug_console_overlay_panel.dart',
        ),
      ).readAsStringSync();
      expect(
        panelSource.contains(
          'static const screenId = UiScreenIds.debugConsolePanel',
        ),
        isTrue,
      );

      final idsSource = File(
        p.join(repoRoot, 'app', 'lib', 'config', 'ui_screen_ids.dart'),
      ).readAsStringSync();
      expect(
        idsSource.contains("static const String debugConsolePanel = 'SYS20001'"),
        isTrue,
      );
    });

    test('Widgetbook catalog registers Debug Console Panel', () {
      final catalogPart = File(
        p.join(
          repoRoot,
          'widgetbook_host',
          'lib',
          'catalogs',
          'catalog_debug_console.dart',
        ),
      ).readAsStringSync();
      expect(catalogPart.contains("name: 'Debug Console Panel'"), isTrue);

      final catalog = File(
        p.join(repoRoot, 'widgetbook_host', 'lib', 'catalogs', 'catalog.dart'),
      ).readAsStringSync();
      expect(catalog.contains("part 'catalog_debug_console.dart'"), isTrue);
      expect(catalog.contains('...debugConsolePanelDirectories,'), isTrue);
    });

    test('docs/manual chapters do not cite SYS20001', () {
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
          body.contains('SYS20001'),
          isFalse,
          reason: p.relative(chapter.path, from: repoRoot),
        );
      }
    });

    test('negative: SYS20001 is not left as draft/TBD in registry', () {
      final registry = File(
        p.join(repoRoot, 'SPEC', 'ui', 'screen-registry.md'),
      ).readAsStringSync();
      final rows = parseScreenRegistryRows(registry);
      final row = rows.firstWhere((r) => r.id == 'SYS20001');
      expect(row.status, isNot('draft'));
      expect(row.implementationCell.trim(), isNot('TBD'));
      expect(extractDartPathFromCell(row.implementationCell), isNotNull);
    });
  });
}
