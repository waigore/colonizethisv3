// Ensures Widgetbook catalog sources live under widgetbook_host, not app/lib
// (Refs #3878 Phase 4 / AC7).
//
// SPEC: SPEC/program/repo-and-packages.md
import 'dart:io';

import 'package:path/path.dart' as p;

/// Canonical Widgetbook catalog directory after Phase 4 relocation.
const String widgetbookCatalogDirPath = 'widgetbook_host/lib/catalogs';

/// App production tree must not contain catalog fragment files.
const String appLibDirPath = 'app/lib';

/// Matches catalog library and part file names such as `catalog.dart` or
/// `catalog_panels.dart`.
final RegExp _catalogFileName = RegExp(r'^catalog.*\.dart$');

int runCheckAppWidgetbookCatalogLocation(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final appLibDir = Directory(p.join(repoRoot, appLibDirPath));
  if (!appLibDir.existsSync()) {
    logI(
      'check_app_widgetbook_catalog_location: $appLibDirPath not found; '
      'nothing to check.',
    );
    return 0;
  }

  final violations = <String>[];
  final dartFiles = appLibDir
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in dartFiles) {
    final fileName = p.basename(file.path);
    if (!_catalogFileName.hasMatch(fileName)) {
      continue;
    }
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    violations.add(
      '$rel: Widgetbook catalog files must live under '
      '$widgetbookCatalogDirPath (Refs #3878)',
    );
  }

  final catalogDir = Directory(p.join(repoRoot, widgetbookCatalogDirPath));
  if (!catalogDir.existsSync()) {
    violations.add(
      '$widgetbookCatalogDirPath: expected Widgetbook catalog directory is '
      'missing after relocation (Refs #3878)',
    );
  }

  if (violations.isEmpty) {
    logI(
      'check_app_widgetbook_catalog_location: no catalog*.dart under $appLibDirPath; '
      'catalogs live in $widgetbookCatalogDirPath.',
    );
    return 0;
  }
  logE(
    'check_app_widgetbook_catalog_location: ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAppWidgetbookCatalogLocation(Directory.current.path));
}
