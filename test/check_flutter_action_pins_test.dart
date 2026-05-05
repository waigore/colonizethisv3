import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_flutter_action_pins.dart';

void main() {
  test('fails when flutter-action step omits flutter-version pin', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_flutter_action_pins_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final workflow = File('${temp.path}/.github/workflows/quality.yml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: quality
jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
''');

    expect(workflow.existsSync(), isTrue);

    final logs = <String>[];
    final code = runCheckFlutterActionPins(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('without flutter-version pin'));
  });

  test('passes when flutter-action step defines flutter-version pin', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_flutter_action_pins_pass_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final workflow = File('${temp.path}/.github/workflows/quality.yml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: quality
jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          flutter-version: '3.41.9'
''');

    expect(workflow.existsSync(), isTrue);
    expect(runCheckFlutterActionPins(temp.path), 0);
  });
}
