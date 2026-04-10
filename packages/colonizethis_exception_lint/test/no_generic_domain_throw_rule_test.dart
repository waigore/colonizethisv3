import 'dart:io';

import 'package:colonizethis_exception_lint/exception_enforcement.dart';
import 'package:colonizethis_test/test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('lint reports error when path matches domain packages/', () async {
    final tmp = Directory.systemTemp.createTempSync('ct_exc_lint_pkg_');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final libDir = Directory(p.join(tmp.path, 'packages', 'sample', 'lib'));
    libDir.createSync(recursive: true);
    final file = File(p.join(libDir.path, 'bad.dart'));
    file.writeAsStringSync('void f() { throw ArgumentError("x"); }\n');

    final rule = NoGenericDomainThrowRule();
    final errors = await rule.testAnalyzeAndRun(file);
    expect(errors, isNotEmpty);
    expect(errors.first.diagnosticCode.name, 'no_generic_domain_throw');
  });

  test('lint skips widgetbook_host-shaped paths', () async {
    final tmp = Directory.systemTemp.createTempSync('ct_exc_lint_wb_');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final libDir = Directory(p.join(tmp.path, 'widgetbook_host', 'lib'));
    libDir.createSync(recursive: true);
    final file = File(p.join(libDir.path, 'bad.dart'));
    file.writeAsStringSync('void f() { throw ArgumentError("x"); }\n');

    final rule = NoGenericDomainThrowRule();
    final errors = await rule.testAnalyzeAndRun(file);
    expect(errors, isEmpty);
  });
}
