import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_app_e2e_helper_location.dart';

void main() {
  final repoRoot = p.normalize(p.join(Directory.current.path));

  test('E2E helpers and mirror tests live in colonizethis_app_e2e_support', () {
    expect(runCheckAppE2eHelperLocation(repoRoot), 0);
  });
}
