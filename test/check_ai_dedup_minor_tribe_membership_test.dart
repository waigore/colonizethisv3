// Refs #3717 — guards `repo.ai_dedup_minor_tribe_membership` enforcement.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_dedup_minor_tribe_membership.dart';

void main() {
  group('repo.ai_dedup_minor_tribe_membership', () {
    test('passes on real repo workspace', () {
      final repoRoot = Directory.current.path;
      final logs = <String>[];
      final code = runCheckAiDedupMinorTribeMembership(
        repoRoot,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
      expect(
        logs.join('\n'),
        contains('check_ai_dedup_minor_tribe_membership: no violations found.'),
      );
    });

    test('fails when a lib file inlines the minorNations membership check', () {
      final temp = Directory.systemTemp.createTempSync('ai_minor_fail_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final aiLib = Directory(
        p.join(temp.path, 'packages/colonizethis_ai/lib/src/planning'),
      )..createSync(recursive: true);

      File(p.join(aiLib.path, 'inline_minor.dart')).writeAsStringSync(
        'bool f(game, id) => game.minorNations.any((m) => m.id == id);\n',
      );

      final errLogs = <String>[];
      final code = runCheckAiDedupMinorTribeMembership(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );

      expect(code, 1);
      expect(errLogs.join('\n'), contains('inline_minor.dart'));
      expect(errLogs.join('\n'), contains('isMinorFaction'));
    });

    test('fails when a lib file inlines the tribes membership check', () {
      final temp = Directory.systemTemp.createTempSync('ai_tribe_fail_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final aiLib = Directory(
        p.join(temp.path, 'packages/colonizethis_ai/lib/src/planning'),
      )..createSync(recursive: true);

      File(p.join(aiLib.path, 'inline_tribe.dart')).writeAsStringSync(
        'bool f(game, factionId) =>\n'
        '    game.tribes.any((t) => t.id == factionId);\n',
      );

      final code = runCheckAiDedupMinorTribeMembership(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 1);
    });

    test('passes when files call the shared helpers', () {
      final temp = Directory.systemTemp.createTempSync('ai_membership_pass_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final aiLib = Directory(
        p.join(temp.path, 'packages/colonizethis_ai/lib/src/planning'),
      )..createSync(recursive: true);

      File(p.join(aiLib.path, 'uses_helper.dart')).writeAsStringSync(
        'bool a(game, id) => isMinorFaction(game, id);\n'
        'bool b(game, id) => isTribeFaction(game, id);\n'
        'bool c(game, id) => isMinorOrTribeFaction(game, id);\n',
      );

      final code = runCheckAiDedupMinorTribeMembership(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });

    test('does not flag a roster scan whose predicate is not id-equality', () {
      // Iterating `minorNations`/`tribes` for an ownership test (no
      // `<param>.id ==` equality) must not be mistaken for the membership form.
      final temp = Directory.systemTemp.createTempSync('ai_membership_other_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final aiLib = Directory(
        p.join(temp.path, 'packages/colonizethis_ai/lib/src/planning'),
      )..createSync(recursive: true);

      File(p.join(aiLib.path, 'ownership_scan.dart')).writeAsStringSync(
        'bool f(game, ownerCache, kRegionOldWorld) => game.minorNations.any(\n'
        '    (m) => ownerCache.ownsAnyInRegion(m.id, kRegionOldWorld),\n'
        '  );\n',
      );

      final code = runCheckAiDedupMinorTribeMembership(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });

    test('allows the canonical faction_query.dart definitions', () {
      final temp = Directory.systemTemp.createTempSync('ai_membership_canon_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final aiUtil = Directory(
        p.join(temp.path, 'packages/colonizethis_ai/lib/src/util'),
      )..createSync(recursive: true);

      File(p.join(aiUtil.path, 'faction_query.dart')).writeAsStringSync(
        'bool isMinorFaction(game, factionId) =>\n'
        '    game.minorNations.any((m) => m.id == factionId);\n'
        'bool isTribeFaction(game, factionId) =>\n'
        '    game.tribes.any((t) => t.id == factionId);\n',
      );

      final code = runCheckAiDedupMinorTribeMembership(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });
  });
}
