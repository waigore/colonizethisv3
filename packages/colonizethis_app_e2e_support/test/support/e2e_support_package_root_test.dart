/// Pins package-root resolution for CI cwd (`app/`) vs package cwd.
library;

import 'dart:io';

import 'package:colonizethis_test/test.dart';
import 'package:path/path.dart' as p;

import 'e2e_support_package_root.dart';

void main() {
  test('e2eSupportPackageRoot resolves this package from current cwd', () {
    final root = e2eSupportPackageRoot();
    expect(
      File(p.join(root.path, 'pubspec.yaml')).readAsStringSync(),
      contains('name: colonizethis_app_e2e_support'),
    );
    expect(
      File(p.join(root.path, 'lib', 'e2e_helpers.dart')).existsSync(),
      isTrue,
    );
  });

  test('negative: resolved root is never the app/ directory', () {
    final root = e2eSupportPackageRoot();
    expect(p.basename(root.path), 'colonizethis_app_e2e_support');
    expect(p.basename(root.path), isNot('app'));
  });
}
