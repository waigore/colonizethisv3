// Physical line limit for app core services (`repo.app_core_services_file_size`).
// SPEC: SPEC/program/app-core-services-file-size.md (wave-16 #4450 Slice A).
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Ratchet ceiling for hand-written Dart under `app/lib/core/services/**`.
const int appCoreServicesFileSizeCeiling = 300;

final RegExp _generatedSuffix = RegExp(r'\.(g|freezed|mocks|gen)\.dart$');

/// PR-blocking structural check: files under `app/lib/core/services/**` must
/// stay at or below 300 physical lines (Refs #4450 AC3).
int runCheckAppCoreServicesFileSize(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final servicesDir = Directory(
    p.join(repoRoot, 'app', 'lib', 'core', 'services'),
  );
  if (!servicesDir.existsSync()) {
    logE('check_app_core_services_file_size: app/lib/core/services not found.');
    return 1;
  }

  final violations = <String>[];
  for (final entity in servicesDir.listSync(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final relativePath = p
        .relative(entity.path, from: repoRoot)
        .replaceAll('\\', '/');
    if (_generatedSuffix.hasMatch(relativePath)) {
      continue;
    }
    final physicalLines = const LineSplitter()
        .convert(entity.readAsStringSync())
        .length;
    if (physicalLines <= appCoreServicesFileSizeCeiling) {
      continue;
    }
    violations.add(
      '$relativePath ($physicalLines physical lines > $appCoreServicesFileSizeCeiling)',
    );
  }

  if (violations.isEmpty) {
    logI(
      'check_app_core_services_file_size: no violations found '
      '(ceiling $appCoreServicesFileSizeCeiling; Refs #4450).',
    );
    return 0;
  }

  logE(
    'check_app_core_services_file_size: found ${violations.length} '
    'violation(s) under app/lib/core/services:',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAppCoreServicesFileSize(Directory.current.path));
}
