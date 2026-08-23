import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_test_no_duplicate_shortcut_golden_game_service.dart';

void main() {
  test('fails when a governed golden suite declares extends GameService', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_duplicate_shortcut_golden_gs_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    File(
        '${temp.path}/app/test/province_build_road_shortcut_host_goldens_test.dart',
      )
      ..createSync(recursive: true)
      ..writeAsStringSync('''
class GameService {}
class _GameServiceBuildRoadGolden extends GameService {}
''');
    File(
      '${temp.path}/app/test/province_establish_consulate_shortcut_host_goldens_test.dart',
    ).writeAsStringSync('''
class GameService {}
class _GameServiceConsulateGolden extends GameService {}
''');

    final logs = <String>[];
    final code = runCheckAppTestNoDuplicateShortcutGoldenGameService(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(
      logs.join('\n'),
      contains('province_build_road_shortcut_host_goldens_test.dart'),
    );
    expect(
      logs.join('\n'),
      isNot(
        contains(
          'province_establish_consulate_shortcut_host_goldens_test.dart',
        ),
      ),
    );
  });

  test('passes when governed goldens do not extend GameService', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_duplicate_shortcut_golden_gs_pass_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    File(
        '${temp.path}/app/test/province_build_road_shortcut_host_goldens_test.dart',
      )
      ..createSync(recursive: true)
      ..writeAsStringSync('''
import 'province_shortcut_host_golden_game_service.dart';

void main() {}
''');

    final code = runCheckAppTestNoDuplicateShortcutGoldenGameService(temp.path);
    expect(code, 0);
  });
}
