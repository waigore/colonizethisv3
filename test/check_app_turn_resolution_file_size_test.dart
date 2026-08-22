import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_turn_resolution_file_size.dart';

void main() {
  test('wave-20 ceiling is 260', () {
    expect(appTurnResolutionFileSizeCeiling, 260);
  });

  test('fails when a turn_resolution file exceeds 260 lines', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_turn_resolution_file_size_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final violatingFile = File(
      '${temp.path}/app/lib/features/game/turn_resolution/too_long.dart',
    )..createSync(recursive: true);
    violatingFile.writeAsStringSync(List.filled(261, '// line').join('\n'));

    final logs = <String>[];
    final code = runCheckAppTurnResolutionFileSize(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('too_long.dart'));
    expect(logs.join('\n'), contains('261 physical lines > 260'));
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

  test('passes when all turn_resolution files are at or below 260 lines', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_turn_resolution_file_size_pass_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final okFile = File(
      '${temp.path}/app/lib/features/game/turn_resolution/ok.dart',
    )..createSync(recursive: true);
    okFile.writeAsStringSync(List.filled(260, '// line').join('\n'));

    final code = runCheckAppTurnResolutionFileSize(temp.path);
    expect(code, 0);
  });
}
