import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_logic_reduced_surface.dart';

void main() {
  test('thin-core ceiling matches the epic AC (<=15 source files)', () {
    expect(maxLogicReducedSurfaceFilesForTests(), 15);
  });

  test('passes for the real post-split colonizethis_logic surface', () {
    final code = runCheckLogicReducedSurface(
      Directory.current.path,
      info: (_) {},
      err: (_) {},
    );
    expect(code, 0);
  });

  test('fails when lib/ holds more than 15 non-generated source files', () {
    final temp = Directory.systemTemp.createTempSync('logic_reduced_surface_');
    addTearDown(() => temp.deleteSync(recursive: true));

    final libDir = Directory(
      '${temp.path}/packages/colonizethis_logic/lib',
    )..createSync(recursive: true);
    for (var i = 0; i < 16; i++) {
      File('${libDir.path}/file_$i.dart')
        ..createSync()
        ..writeAsStringSync('// source $i');
    }

    final code = runCheckLogicReducedSurface(
      temp.path,
      info: (_) {},
      err: (_) {},
    );
    expect(code, 1);
  });

  test('ignores generated files when counting the surface', () {
    final temp = Directory.systemTemp.createTempSync('logic_reduced_gen_');
    addTearDown(() => temp.deleteSync(recursive: true));

    final libDir = Directory(
      '${temp.path}/packages/colonizethis_logic/lib',
    )..createSync(recursive: true);
    for (var i = 0; i < 15; i++) {
      File('${libDir.path}/file_$i.dart')
        ..createSync()
        ..writeAsStringSync('// source $i');
    }
    for (var i = 0; i < 5; i++) {
      File('${libDir.path}/file_$i.g.dart')
        ..createSync()
        ..writeAsStringSync('// generated $i');
    }

    final code = runCheckLogicReducedSurface(
      temp.path,
      info: (_) {},
      err: (_) {},
    );
    expect(code, 0);
  });

  test('fails when the colonizethis_logic lib tree is missing', () {
    final temp = Directory.systemTemp.createTempSync('logic_reduced_missing_');
    addTearDown(() => temp.deleteSync(recursive: true));

    final code = runCheckLogicReducedSurface(
      temp.path,
      info: (_) {},
      err: (_) {},
    );
    expect(code, 1);
  });
}
