import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_logic_dead_files.dart';

void main() {
  test('passes on real repo workspace', () {
    final repoRoot = Directory.current.path;
    final logs = <String>[];
    final code = runCheckLogicDeadFiles(
      repoRoot,
      info: logs.add,
      err: logs.add,
    );
    expect(code, 0, reason: logs.join('\n'));
    expect(
      logs.join('\n'),
      contains('Logic dead-file check passed'),
    );
  });

  test('fails when lib/src file is not imported or barrel-exported', () {
    final temp = Directory.systemTemp.createTempSync('logic_dead_files_fail_');
    addTearDown(() => temp.deleteSync(recursive: true));

    final logicLib = Directory(p.join(temp.path, 'packages/colonizethis_logic/lib'))
      ..createSync(recursive: true);
    final logicSrc = Directory(p.join(logicLib.path, 'src'))
      ..createSync(recursive: true);

    File(p.join(logicLib.path, 'colonizethis_logic.dart')).writeAsStringSync(
      'library colonizethis_logic;\n',
    );
    File(p.join(logicSrc.path, 'orphan.dart')).writeAsStringSync(
      '// intentionally unreferenced\n',
    );

    final err = <String>[];
    final code = runCheckLogicDeadFiles(
      temp.path,
      info: (_) {},
      err: err.add,
    );

    expect(code, 1);
    expect(err.join('\n'), contains('orphan.dart'));
  });
}
