import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_app_panel_static_session_revision_sot.dart';

void main() {
  group('repo.app_panel_static_session_revision', () {
    test('passes on real repo workspace', () {
      final logs = <String>[];
      final code = runCheckAppPanelStaticSessionRevisionSot(
        Directory.current.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });

    test('fails when a non-canonical file inlines the static revision triple', () {
      final temp = Directory.systemTemp.createTempSync('panel_static_sot_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final lib = Directory(p.join(temp.path, 'app', 'lib'))
        ..createSync(recursive: true);
      File(p.join(lib.path, 'copy.dart')).writeAsStringSync('''
dynamic rebuild(Game game) {
  return (
    gameId: game.id,
    turnNumber: game.worldState.turnState.turnNumber,
    worldRevision: panelWorldRevision(game),
  );
}
''');
      final err = <String>[];
      final code = runCheckAppPanelStaticSessionRevisionSot(
        temp.path,
        info: (_) {},
        err: err.add,
      );
      expect(code, 1);
      expect(err.join('\n'), contains('copy.dart'));
    });

    test('fails when a file redeclares provinceOverlayWorldRevision', () {
      final temp = Directory.systemTemp.createTempSync('panel_static_overlay_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final lib = Directory(p.join(temp.path, 'app', 'lib'))
        ..createSync(recursive: true);
      File(p.join(lib.path, 'overlay_dup.dart')).writeAsStringSync('''
int provinceOverlayWorldRevision(Game game) => 0;
''');
      final err = <String>[];
      final code = runCheckAppPanelStaticSessionRevisionSot(
        temp.path,
        info: (_) {},
        err: err.add,
      );
      expect(code, 1);
      expect(err.join('\n'), contains('overlay_dup.dart'));
    });

    test('passes the canonical helper with the triple idiom', () {
      final temp = Directory.systemTemp.createTempSync('panel_static_ok_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final helperDir = Directory(
        p.join(temp.path, 'app', 'lib', 'providers'),
      )..createSync(recursive: true);
      File(
        p.join(helperDir.path, 'panel_session_revision.dart'),
      ).writeAsStringSync('''
PanelStaticSessionRevision panelStaticSessionRevision(Game game) {
  return (
    gameId: game.id,
    turnNumber: game.worldState.turnState.turnNumber,
    worldRevision: panelWorldRevision(game),
  );
}
''');
      final logs = <String>[];
      final code = runCheckAppPanelStaticSessionRevisionSot(
        temp.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });
  });
}
