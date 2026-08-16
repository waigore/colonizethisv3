import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_test_no_duplicate_shortcut_fixtures.dart';

void main() {
  test('fails when a governed shortcut-host test re-declares MapTopology', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_duplicate_shortcut_fixtures_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    File(
        '${temp.path}/app/test/province_explore_shortcut_host_emit_event_test.dart',
      )
      ..createSync(recursive: true)
      ..writeAsStringSync('''
import 'package:colonizethis_data/colonizethis_data.dart';

final MapTopology _combinedTopology = MapTopology(nodes: const [], edges: const []);
''');
    File(
      '${temp.path}/app/test/province_shortcut_host_emit_fixtures.dart',
    ).writeAsStringSync(
      'final ok = MapTopology(nodes: const [], edges: const []);\n',
    );
    File(
      '${temp.path}/app/test/province_shortcut_host_emit_test_support_test.dart',
    ).writeAsStringSync(
      'final ignored = MapTopology(nodes: const [], edges: const []);\n',
    );

    final logs = <String>[];
    final code = runCheckAppTestNoDuplicateShortcutFixtures(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(
      logs.join('\n'),
      contains('province_explore_shortcut_host_emit_event_test.dart'),
    );
    expect(
      logs.join('\n'),
      isNot(contains('app/test/province_shortcut_host_emit_fixtures.dart')),
    );
    expect(
      logs.join('\n'),
      isNot(
        contains('app/test/province_shortcut_host_emit_test_support_test.dart'),
      ),
    );
  });

  test('passes when only the fixture SoT declares MapTopology', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_duplicate_shortcut_fixtures_pass_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    File('${temp.path}/app/test/province_shortcut_host_emit_fixtures.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        'final MapTopology combined = MapTopology(nodes: const [], edges: const []);\n',
      );
    File(
      '${temp.path}/app/test/province_explore_shortcut_host_emit_event_test.dart',
    ).writeAsStringSync('''
import 'province_shortcut_host_emit_fixtures.dart';

final MapTopology _combinedTopology = provinceShortcutHostCombinedTopology();
''');

    final code = runCheckAppTestNoDuplicateShortcutFixtures(temp.path);
    expect(code, 0);
  });
}
