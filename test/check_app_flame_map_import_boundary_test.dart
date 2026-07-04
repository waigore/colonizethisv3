import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_app_flame_map_import_boundary.dart';

void main() {
  final repoRoot = p.normalize(p.join(Directory.current.path));

  test('flame map submodule import boundaries pass on repo baseline', () {
    expect(runCheckAppFlameMapImportBoundary(repoRoot), 0);
  });
}
