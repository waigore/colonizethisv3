// E2E mirror tests and helper implementations must live in
// `packages/colonizethis_app_e2e_support`, not under `app/test/e2e_*`.
// Refs #3878 Phase 1.
import 'dart:io';

import 'package:path/path.dart' as p;

const _maxAppE2eMirrorTests = 10;
const _appTestDir = 'app/test';
const _appIntegrationDir = 'app/integration_test';

int runCheckAppE2eHelperLocation(
  String repoRoot, {
  void Function(String line)? err,
}) {
  final logE = err ?? stderr.writeln;
  var exitCode = 0;

  final mirrorDir = Directory(p.join(repoRoot, _appTestDir));
  if (!mirrorDir.existsSync()) {
    logE('check_app_e2e_helper_location: missing $_appTestDir');
    return 1;
  }

  final mirrorFiles = mirrorDir
      .listSync(recursive: false)
      .whereType<File>()
      .where((f) => p.basename(f.path).startsWith('e2e_'))
      .map((f) => p.basename(f.path))
      .toList()
    ..sort();

  if (mirrorFiles.length > _maxAppE2eMirrorTests) {
    logE(
      'check_app_e2e_helper_location: found ${mirrorFiles.length} '
      '$_appTestDir/e2e_*.dart files (max $_maxAppE2eMirrorTests). '
      'Move mirror tests to packages/colonizethis_app_e2e_support/test/:',
    );
    for (final name in mirrorFiles) {
      logE('  $_appTestDir/$name');
    }
    exitCode = 1;
  }

  final integrationDir = Directory(p.join(repoRoot, _appIntegrationDir));
  if (integrationDir.existsSync()) {
    final helperFiles = <String>[];
    for (final entity in integrationDir.listSync(recursive: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final name = p.basename(entity.path);
      if (name == 'e2e_helpers.dart' ||
          name.startsWith('e2e_test_shared')) {
        helperFiles.add('$_appIntegrationDir/$name');
      }
    }
    if (helperFiles.isNotEmpty) {
      logE(
        'check_app_e2e_helper_location: E2E helper implementations must live '
        'in packages/colonizethis_app_e2e_support/lib/, not '
        '$_appIntegrationDir:',
      );
      for (final path in helperFiles) {
        logE('  $path');
      }
      exitCode = 1;
    }
  }

  return exitCode;
}

void main(List<String> args) {
  final repoRoot = args.isNotEmpty
      ? p.normalize(args.first)
      : p.normalize(p.join(Directory.current.path));
  exit(runCheckAppE2eHelperLocation(repoRoot));
}
