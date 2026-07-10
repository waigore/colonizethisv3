import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_app_no_stray_l10n_gen.dart';

void main() {
  group('runCheckAppNoStrayL10nGen', () {
    test('passes when app/lib/l10n is absent', () {
      final temp = Directory.systemTemp.createTempSync('stray-l10n-absent-');
      try {
        Directory(p.join(temp.path, 'app', 'lib')).createSync(recursive: true);
        final exitCode = runCheckAppNoStrayL10nGen(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when stray *.dart exists under app/lib/l10n', () {
      final temp = Directory.systemTemp.createTempSync('stray-l10n-bad-');
      try {
        final stray = File(
          p.join(temp.path, appLibL10nDirPath, 'gen', 'app_localizations.dart'),
        )
          ..createSync(recursive: true)
          ..writeAsStringSync('// stray\n');

        final errors = <String>[];
        final exitCode = runCheckAppNoStrayL10nGen(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(
          errors.join('\n'),
          contains(p.relative(stray.path, from: temp.path).replaceAll('\\', '/')),
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes on current repo root with no stray gen', () {
      final repoRoot = p.normalize(p.join(Directory.current.path));
      expect(runCheckAppNoStrayL10nGen(repoRoot, info: (_) {}, err: (_) {}), 0);
    });
  });
}
