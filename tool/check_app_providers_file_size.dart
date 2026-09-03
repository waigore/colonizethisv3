// Physical line limit for app providers (`repo.app_providers_file_size`).
// SPEC: SPEC/program/app-providers-file-size.md (wave-24 #4720 Slice D).
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Ratchet ceiling for hand-written Dart under `app/lib/providers/**`.
const int appProvidersFileSizeCeiling = 250;

final RegExp _generatedSuffix = RegExp(r'\.(g|freezed|mocks|gen)\.dart$');

/// PR-blocking structural check: files under `app/lib/providers/**` must
/// stay at or below 250 physical lines (Refs #4720 AC10–AC11).
int runCheckAppProvidersFileSize(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final providersDir = Directory(
    p.join(repoRoot, 'app', 'lib', 'providers'),
  );
  if (!providersDir.existsSync()) {
    logE('check_app_providers_file_size: app/lib/providers not found.');
    return 1;
  }

  final violations = <String>[];
  for (final entity in providersDir.listSync(
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
    if (physicalLines <= appProvidersFileSizeCeiling) {
      continue;
    }
    violations.add(
      '$relativePath ($physicalLines physical lines > $appProvidersFileSizeCeiling)',
    );
  }

  if (violations.isEmpty) {
    logI(
      'check_app_providers_file_size: no violations found '
      '(ceiling $appProvidersFileSizeCeiling; Refs #4720).',
    );
    return 0;
  }

  logE(
    'check_app_providers_file_size: found ${violations.length} '
    'violation(s) under app/lib/providers:',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAppProvidersFileSize(Directory.current.path));
}
