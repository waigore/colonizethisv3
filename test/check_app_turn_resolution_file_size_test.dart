import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_turn_resolution_file_size.dart';

void main() {
  test('wave-21 ceiling is 250', () {
    expect(appTurnResolutionFileSizeCeiling, 250);
  });

  test('fails when a turn_resolution file exceeds 250 lines', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_turn_resolution_file_size_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final violatingFile = File(
      '${temp.path}/app/lib/features/game/turn_resolution/too_long.dart',
    )..createSync(recursive: true);
    violatingFile.writeAsStringSync(List.filled(251, '// line').join('\n'));

    final logs = <String>[];
    final code = runCheckAppTurnResolutionFileSize(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('too_long.dart'));
    expect(logs.join('\n'), contains('251 physical lines > 250'));
  });

  test('fails when turn_resolution directory is missing', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_turn_resolution_file_size_no_dir_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final logs = <String>[];
    final code = runCheckAppTurnResolutionFileSize(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('turn_resolution not found'));
  });

  test('passes when all turn_resolution files are at or below 250 lines', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_turn_resolution_file_size_pass_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final okFile = File(
      '${temp.path}/app/lib/features/game/turn_resolution/ok.dart',
    )..createSync(recursive: true);
    okFile.writeAsStringSync(List.filled(250, '// line').join('\n'));

    final code = runCheckAppTurnResolutionFileSize(temp.path);
    expect(code, 0);
  });
}
