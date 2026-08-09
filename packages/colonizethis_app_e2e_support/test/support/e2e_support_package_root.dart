/// Resolves this package's root when tests run from package cwd or from `app/`
/// (CI: `flutter test ../packages/colonizethis_app_e2e_support/test/`).
library;

import 'dart:io';

import 'package:path/path.dart' as p;

/// Package directory that owns `lib/` and `pubspec.yaml` for
/// `colonizethis_app_e2e_support`.
Directory e2eSupportPackageRoot() {
  const packageNameLine = 'name: colonizethis_app_e2e_support';
  final candidates = <String>[
    Directory.current.path,
    p.normalize(
      p.join(
        Directory.current.path,
        '..',
        'packages',
        'colonizethis_app_e2e_support',
      ),
    ),
  ];
  for (final root in candidates) {
    final pubspec = File(p.join(root, 'pubspec.yaml'));
    if (!pubspec.existsSync()) {
      continue;
    }
    if (pubspec.readAsStringSync().contains(packageNameLine)) {
      return Directory(root);
    }
  }
  throw StateError(
    'Could not locate colonizethis_app_e2e_support from cwd=${Directory.current.path}',
  );
}
