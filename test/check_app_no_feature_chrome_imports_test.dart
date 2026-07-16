// Refs #4035 AC2 — guards `repo.app_no_feature_chrome_imports`.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_app_no_feature_chrome_imports.dart';

void main() {
  group('repo.app_no_feature_chrome_imports', () {
    test('passes on real repo workspace', () {
      final logs = <String>[];
      final code = runCheckAppNoFeatureChromeImports(
        Directory.current.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
      expect(
        logs.join('\n'),
        contains('no feature chrome shim imports'),
      );
    });

    test('fails when feature chrome directory exists', () {
      final temp = Directory.systemTemp.createTempSync('chrome_dir_');
      addTearDown(() => temp.deleteSync(recursive: true));
      Directory(p.join(temp.path, 'app/lib/features/game/widgets/chrome'))
          .createSync(recursive: true);

      final errLogs = <String>[];
      final code = runCheckAppNoFeatureChromeImports(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );
      expect(code, 1);
      expect(errLogs.join('\n'), contains('directory must not exist'));
    });

    test('fails on banned package chrome import', () {
      final temp = Directory.systemTemp.createTempSync('chrome_import_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final appTest = Directory(p.join(temp.path, 'app/test'))
        ..createSync(recursive: true);
      File(p.join(appTest.path, 'bad_import_test.dart')).writeAsStringSync(
        "import 'package:colonizethis_app/features/game/widgets/chrome/"
        "ct_panel.dart';\n",
      );

      final errLogs = <String>[];
      final code = runCheckAppNoFeatureChromeImports(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );
      expect(code, 1);
      expect(errLogs.join('\n'), contains('features/game/widgets/chrome/'));
    });

    test('fails on banned relative chrome import', () {
      final temp = Directory.systemTemp.createTempSync('chrome_rel_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final features = Directory(
        p.join(temp.path, 'app/lib/features/game/widgets/units'),
      )..createSync(recursive: true);
      File(p.join(features.path, 'panel.dart')).writeAsStringSync(
        "import '../../chrome/ct_action_text_button.dart';\n",
      );

      final errLogs = <String>[];
      final code = runCheckAppNoFeatureChromeImports(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );
      expect(code, 1);
      expect(errLogs.join('\n'), contains('../../chrome/'));
    });
  });
}
