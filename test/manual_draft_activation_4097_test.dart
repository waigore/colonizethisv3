import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_screen_registry_active_paths.dart';

/// Acceptance pins for issue #4097: shipped player-manual surfaces are
/// registry-`active` with real Implementation paths, and `docs/manual/**`
/// no longer cites live screens as draft-playable.
void main() {
  final repoRoot = Directory.current.path;

  /// Matches operable-style draft citations: `**[DRAFT]** `SCREENID``.
  final draftScreenCitation = RegExp(
    r'\*\*\[DRAFT\]\*\*\s*`[A-Z]{3,4}\d{5}`',
  );

  group('issue #4097 manual draft activation', () {
    test('GAME60001 SHEL30001 DLG60001 OVL70001 are active with existing paths',
        () {
      final registry = File(
        p.join(repoRoot, 'SPEC', 'ui', 'screen-registry.md'),
      ).readAsStringSync();
      final rows = parseScreenRegistryRows(registry);
      final byId = {for (final r in rows) r.id: r};

      const expected = <String, String>{
        'GAME60001':
            'app/lib/features/game/screens/trade/trade_screen.dart',
        'SHEL30001':
            'app/lib/features/shell/new_game_setup_flow_dialogs_progress.dart',
        'DLG60001':
            'app/lib/features/game/flame/overlays/next_turn_confirmation_dialog.dart',
        'OVL70001':
            'app/lib/features/game/widgets/shell/player_turn_event_feed_card.dart',
      };

      for (final entry in expected.entries) {
        final row = byId[entry.key];
        expect(row, isNotNull, reason: '${entry.key} missing from registry');
        expect(row!.status, 'active', reason: '${entry.key} status');
        final path = extractDartPathFromCell(row.implementationCell);
        expect(path, entry.value, reason: '${entry.key} implementation path');
        expect(
          File(p.join(repoRoot, path!)).existsSync(),
          isTrue,
          reason: '${entry.key} file missing: $path',
        );
      }
    });

    test('docs/manual chapters do not cite real screen IDs as **[DRAFT]**', () {
      final manualDir = Directory(p.join(repoRoot, 'docs', 'manual'));
      expect(manualDir.existsSync(), isTrue);

      final draftHits = <String>[];
      for (final entity in manualDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.md')) continue;
        final relative = p.relative(entity.path, from: repoRoot);
        final lines = entity.readAsStringSync().split('\n');
        for (var i = 0; i < lines.length; i++) {
          if (draftScreenCitation.hasMatch(lines[i])) {
            draftHits.add('$relative:${i + 1}: ${lines[i].trim()}');
          }
        }
      }

      expect(
        draftHits,
        isEmpty,
        reason:
            'Unexpected draft-playable screen citations:\n${draftHits.join('\n')}',
      );
    });

    test('STYLE_GUIDE does not exemplify GAME60001 as draft', () {
      final styleGuide = File(
        p.join(repoRoot, 'docs', 'manual', 'STYLE_GUIDE.md'),
      ).readAsStringSync();
      expect(draftScreenCitation.hasMatch(styleGuide), isFalse);
      expect(styleGuide.contains('GAME60001'), isFalse);
    });

    test('debug/observe drafts remain omitted from chapter prose', () {
      final chapters = Directory(p.join(repoRoot, 'docs', 'manual'))
          .listSync()
          .whereType<File>()
          .where((f) {
            final name = p.basename(f.path);
            return RegExp(r'^\d{2}-.+\.md$').hasMatch(name);
          });

      for (final chapter in chapters) {
        final body = chapter.readAsStringSync();
        expect(body.contains('OVL60001'), isFalse, reason: chapter.path);
        expect(body.contains('SYS10001'), isFalse, reason: chapter.path);
        expect(body.contains('SYS20001'), isFalse, reason: chapter.path);
      }
    });
  });
}
