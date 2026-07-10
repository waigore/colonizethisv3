import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_test_no_duplicate_yarn_bundle.dart';

const _kConsolidated = '''
import 'support/yarn_test_fixtures.dart';

void main() {
  testWidgets('uses shared yarn bundle', (tester) async {
    final bundle = YarnStringAssetBundle({'a.yarn': 'title: x\\n---\\nHi\\n===\\n'});
    expect(await bundle.loadString('a.yarn'), contains('Hi'));
  });
}
''';

const _kReintroduced = '''
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _StringAssetBundle extends Fake implements AssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async => '';
}

void main() {}
''';

void _writeGovernedFile(Directory temp, String name, String contents) {
  File('${temp.path}/app/test/$name')
    ..createSync(recursive: true)
    ..writeAsStringSync(contents);
}

void main() {
  test('passes when dialogue overlay test uses shared yarn fixtures', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_yarn_pass_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(temp, 'dialogue_overlays_specs_test.dart', _kConsolidated);

    final logs = <String>[];
    final code = runCheckAppTestNoDuplicateYarnBundle(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 0);
    expect(logs.join('\n'), contains('no duplicated Yarn AssetBundle'));
  });

  test('fails when Fake AssetBundle is reintroduced in dialogue overlay test',
      () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_yarn_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(
      temp,
      'tribe_first_contact_overlay_test.dart',
      _kReintroduced,
    );

    final logs = <String>[];
    final code = runCheckAppTestNoDuplicateYarnBundle(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('_StringAssetBundle'));
  });
}
