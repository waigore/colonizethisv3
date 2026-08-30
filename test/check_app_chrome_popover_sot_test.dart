import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_app_chrome_popover_sot.dart';

void main() {
  group('repo.app_chrome_popover_sot', () {
    test('passes on real repo workspace', () {
      final logs = <String>[];
      final code = runCheckAppChromePopoverSot(
        Directory.current.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });

    test(
      'fails when OverlayEntry DismissIntent and dialogScrim share a file',
      () {
        final temp = Directory.systemTemp.createTempSync('chrome_popover_sot_');
        addTearDown(() => temp.deleteSync(recursive: true));
        final lib = Directory(p.join(temp.path, 'app', 'lib'))
          ..createSync(recursive: true);
        File(p.join(lib.path, 'copy.dart')).writeAsStringSync('''
void showCopy() {
  OverlayEntry(
    builder: (_) => Shortcuts(
      shortcuts: const {SingleActivator(LogicalKeyboardKey.escape): DismissIntent()},
      child: ColoredBox(color: EditorialMonoclePalette.dialogScrim),
    ),
  );
}
''');
        final err = <String>[];
        final code = runCheckAppChromePopoverSot(
          temp.path,
          info: (_) {},
          err: err.add,
        );
        expect(code, 1);
        expect(err.join('\n'), contains('copy.dart'));
      },
    );

    test('passes the canonical helper path even with the three tokens', () {
      final temp = Directory.systemTemp.createTempSync('chrome_popover_ok_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final helperDir = Directory(
        p.join(temp.path, 'app', 'lib', 'features', 'game', 'widgets', 'shell'),
      )..createSync(recursive: true);
      File(
        p.join(helperDir.path, 'chrome_anchored_popover.dart'),
      ).writeAsStringSync('''
OverlayEntry e;
DismissIntent i;
final c = dialogScrim;
''');
      final logs = <String>[];
      final code = runCheckAppChromePopoverSot(
        temp.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });
  });
}
