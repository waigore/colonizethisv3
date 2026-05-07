import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_no_duplicate_helpers.dart';

const _kCanonicalEraRomanContents = '''
String eraRoman(int era) {
  return era >= 1 ? 'I' : 'I';
}
''';

const _kCanonicalCommodityContents = '''
String commodityDisplayName(String id) {
  return id;
}
''';

const _kCanonicalTrainHelperContents = '''
String trainDialogPlayerById({required String playerId}) {
  return playerId;
}
''';

void _writeCanonicalHelpers(Directory tempDir) {
  File('${tempDir.path}/app/lib/features/game/utils/tech_ui_helpers.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync(_kCanonicalEraRomanContents);
  File('${tempDir.path}/app/lib/features/game/utils/commodity_ui_helpers.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync(_kCanonicalCommodityContents);
  File(
      '${tempDir.path}/app/lib/features/game/widgets/train_unit_dialog_helper.dart',
    )
    ..createSync(recursive: true)
    ..writeAsStringSync(_kCanonicalTrainHelperContents);
}

void main() {
  test('passes when canonical helpers live only in canonical files', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_no_duplicate_helpers_pass_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeCanonicalHelpers(temp);

    final logs = <String>[];
    final code = runCheckAppNoDuplicateHelpers(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 0);
    expect(
      logs.join('\n'),
      contains('no canonical-helper or removed-helper regressions found'),
    );
  });

  test(
    'fails when a tracked canonical helper is redefined outside its canonical file',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_duplicate_helpers_canonical_redef_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeCanonicalHelpers(temp);

      File('${temp.path}/app/lib/features/game/widgets/duplicate_era.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
String eraRoman(int era) {
  return 'XX';
}
''');

      final logs = <String>[];
      final code = runCheckAppNoDuplicateHelpers(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(
        logs.join('\n'),
        contains('duplicate_era.dart:1: top-level function "eraRoman"'),
      );
    },
  );

  test(
    'fails when a removed private helper reappears as a top-level function',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_duplicate_helpers_removed_top_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeCanonicalHelpers(temp);

      File('${temp.path}/app/lib/features/game/widgets/regression_panel.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
String _eraRoman(int era) {
  return 'IX';
}
''');

      final logs = <String>[];
      final code = runCheckAppNoDuplicateHelpers(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(
        logs.join('\n'),
        contains('removed private helper "_eraRoman" reappears'),
      );
    },
  );

  test('fails when a removed private helper reappears as a class method', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_no_duplicate_helpers_removed_method_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeCanonicalHelpers(temp);

    File('${temp.path}/app/lib/features/game/widgets/tech_widget.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
class TechWidget {
  String _categoryLabel(String c) {
    return c;
  }
}
''');

    final logs = <String>[];
    final code = runCheckAppNoDuplicateHelpers(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(
      logs.join('\n'),
      contains('removed private helper "_categoryLabel" reappears'),
    );
  });

  test('ignores violations under app/lib/widgetbook/', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_no_duplicate_helpers_widgetbook_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeCanonicalHelpers(temp);

    File('${temp.path}/app/lib/widgetbook/catalog_part1.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
String eraRoman(int era) => 'X';

class StoryShim {
  String _commodityDisplayName(String id) => id;
}
''');

    final code = runCheckAppNoDuplicateHelpers(temp.path);
    expect(code, 0);
  });

  test('ignores violations under app/lib/test_support/', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_no_duplicate_helpers_test_support_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeCanonicalHelpers(temp);

    File('${temp.path}/app/lib/test_support/expected_lines.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
String eraRoman(int era) => 'IV';

String _commodityDisplayName(String id) => id;
''');

    final code = runCheckAppNoDuplicateHelpers(temp.path);
    expect(code, 0);
  });

  test('ignores generated dart suffixes', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_no_duplicate_helpers_generated_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeCanonicalHelpers(temp);

    File('${temp.path}/app/lib/features/game/widgets/store_state.g.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
String eraRoman(int era) => 'GEN';
''');
    File('${temp.path}/app/lib/l10n/gen/app_l10n_flutter_gen.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
String _eraRoman(int era) => 'L10N';
''');

    final code = runCheckAppNoDuplicateHelpers(temp.path);
    expect(code, 0);
  });

  test('multiple regressions in different files are all reported, sorted', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_no_duplicate_helpers_multi_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeCanonicalHelpers(temp);

    File('${temp.path}/app/lib/features/game/widgets/a_panel.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
String eraRoman(int era) => 'A';
''');
    File('${temp.path}/app/lib/features/game/widgets/b_panel.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
String _commodityDisplayName(String id) => id;
''');

    final logs = <String>[];
    final code = runCheckAppNoDuplicateHelpers(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    final joined = logs.join('\n');
    expect(joined, contains('a_panel.dart:1'));
    expect(joined, contains('b_panel.dart:1'));
    expect(joined, contains('found 2 regression(s)'));
  });
}
