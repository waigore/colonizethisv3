import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_app_main_line_budget.dart';

void main() {
  final repoRoot = p.normalize(p.join(Directory.current.path));

  test('colonizethis_app main role stays within 69_300 lines', () {
    expect(runCheckAppMainLineBudget(repoRoot), 0);
  });
}
