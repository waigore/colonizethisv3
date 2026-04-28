import 'dart:io';

import 'package:colonizethis_exception_lint/exception_enforcement.dart';
import 'package:colonizethis_test/test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('lint reports error for fleet_ interpolation in logic lib', () async {
    final tmp = Directory.systemTemp.createTempSync('ct_home_fleet_lint_');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final libDir = Directory(
      p.join(tmp.path, 'packages', 'colonizethis_logic', 'lib'),
    );
    libDir.createSync(recursive: true);
    final file = File(p.join(libDir.path, 'bad.dart'));
    file.writeAsStringSync(r'''
void f(String humanPlayerId) {
  final isHome = humanPlayerId == 'fleet_$humanPlayerId';
}
''');

    final rule = NoRawHomeFleetIdRule();
    final errors = await rule.testAnalyzeAndRun(file);
    expect(errors, isNotEmpty);
    expect(errors.first.diagnosticCode.name, 'no_raw_home_fleet_id');
  });

  test('lint allows canonical homeFleetIdFor in naval.dart', () async {
    final tmp = Directory.systemTemp.createTempSync('ct_home_fleet_lint_ok_');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final libDir = Directory(
      p.join(tmp.path, 'packages', 'colonizethis_logic', 'lib', 'src', 'world'),
    );
    libDir.createSync(recursive: true);
    final file = File(p.join(libDir.path, 'naval.dart'));
    file.writeAsStringSync(r'''
String homeFleetIdFor(String playerId) => 'fleet_$playerId';
''');

    final rule = NoRawHomeFleetIdRule();
    final errors = await rule.testAnalyzeAndRun(file);
    expect(errors, isEmpty);
  });

  test('lint skips plain fleet_ string literal', () async {
    final tmp = Directory.systemTemp.createTempSync('ct_home_fleet_lit_');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final libDir = Directory(
      p.join(tmp.path, 'packages', 'colonizethis_logic', 'lib'),
    );
    libDir.createSync(recursive: true);
    final file = File(p.join(libDir.path, 'ok.dart'));
    file.writeAsStringSync(r'''
void f() {
  final x = 'fleet_1';
}
''');

    final rule = NoRawHomeFleetIdRule();
    final errors = await rule.testAnalyzeAndRun(file);
    expect(errors, isEmpty);
  });

  test('lint skips non-logic packages', () async {
    final tmp = Directory.systemTemp.createTempSync('ct_home_fleet_other_');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final libDir = Directory(p.join(tmp.path, 'packages', 'other_pkg', 'lib'));
    libDir.createSync(recursive: true);
    final file = File(p.join(libDir.path, 'x.dart'));
    file.writeAsStringSync(r'''
void f(String id) {
  final x = 'fleet_$id';
}
''');

    final rule = NoRawHomeFleetIdRule();
    final errors = await rule.testAnalyzeAndRun(file);
    expect(errors, isEmpty);
  });
}
