// Physical line limit for shared catalog widgets (`repo.app_catalog_widgets_file_size`).
// SPEC: SPEC/program/app-catalog-widgets-file-size.md (wave-15 #4352 Slice B).
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Ratchet ceiling for hand-written catalog widgets under `app/lib/widgets/**`.
const int appCatalogWidgetsFileSizeCeiling = 300;

final RegExp _generatedSuffix = RegExp(r'\.(g|freezed|mocks|gen)\.dart$');

/// PR-blocking structural check: files under `app/lib/widgets/**` must stay
/// at or below 300 physical lines (Refs #4352 AC4).
int runCheckAppCatalogWidgetsFileSize(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final widgetsDir = Directory(p.join(repoRoot, 'app', 'lib', 'widgets'));
  if (!widgetsDir.existsSync()) {
    logE(
      'check_app_catalog_widgets_file_size: app/lib/widgets not found.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final entity in widgetsDir.listSync(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final relativePath = p.relative(entity.path, from: repoRoot).replaceAll(
      '\\',
      '/',
    );
    if (_generatedSuffix.hasMatch(relativePath)) {
      continue;
    }
    final physicalLines = const LineSplitter()
        .convert(entity.readAsStringSync())
        .length;
    if (physicalLines <= appCatalogWidgetsFileSizeCeiling) {
      continue;
    }
    violations.add(
      '$relativePath ($physicalLines physical lines > $appCatalogWidgetsFileSizeCeiling)',
    );
  }

  if (violations.isEmpty) {
    logI(
      'check_app_catalog_widgets_file_size: no violations found '
      '(ceiling $appCatalogWidgetsFileSizeCeiling; Refs #4352).',
    );
    return 0;
  }

  logE(
    'check_app_catalog_widgets_file_size: found ${violations.length} '
    'violation(s) under app/lib/widgets:',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAppCatalogWidgetsFileSize(Directory.current.path));
}
