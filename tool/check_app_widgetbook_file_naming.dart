// Keeps the Widgetbook catalog split by **UI domain**, not by an arbitrary
// size-based index (Refs #3546 item 6 / AC). The catalog library
// (`app/lib/widgetbook/catalog.dart`) is composed of `part` files; before this
// gate they were named `catalog_part1.dart` … `catalog_part9.dart`, split only
// to stay under the `repo.part_unit_size` line cap. That numbering hid which
// surface family (panels, screens, dialogs, chrome, primitives, …) each file
// registered and produced non-obvious cross-part coupling.
//
// This gate forbids any `app/lib/widgetbook/**` Dart file whose name matches the
// `catalog_part<N>.dart` numbered pattern. New catalog parts must use a
// descriptive domain name (for example `catalog_panels.dart`,
// `catalog_dialogs.dart`, `catalog_primitives.dart`). When a single domain
// exceeds the part-size cap, split it into clearly-named sibling parts rather
// than reintroducing a numbered fragment.
//
// SPEC: SPEC/program/repo-lint.md
import 'dart:io';

import 'package:path/path.dart' as p;

/// Directory holding the Widgetbook catalog library and its `part` files.
const String widgetbookCatalogDirPath = 'app/lib/widgetbook';

/// Matches numbered catalog fragment file names such as `catalog_part1.dart`
/// or `catalog_part12.dart`. Case-insensitive on the `part` token for safety.
final RegExp _numberedCatalogPartFileName = RegExp(
  r'^catalog_part\d+\.dart$',
  caseSensitive: false,
);

/// True when [fileName] (basename only) is a forbidden numbered catalog part.
bool isNumberedCatalogPartFileName(String fileName) =>
    _numberedCatalogPartFileName.hasMatch(fileName);

int runCheckAppWidgetbookFileNaming(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final catalogDir = Directory(p.join(repoRoot, widgetbookCatalogDirPath));
  if (!catalogDir.existsSync()) {
    // No widgetbook catalog directory in this checkout (e.g. partial tree):
    // nothing to enforce, treat as a pass.
    logI(
      'check_app_widgetbook_file_naming: $widgetbookCatalogDirPath not found; '
      'nothing to check.',
    );
    return 0;
  }

  final violations = <String>[];
  final dartFiles = catalogDir
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in dartFiles) {
    final fileName = p.basename(file.path);
    if (!isNumberedCatalogPartFileName(fileName)) {
      continue;
    }
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    violations.add(
      '$rel: numbered Widgetbook catalog fragment is disallowed — rename it to '
      'a descriptive domain name (e.g. catalog_panels.dart / '
      'catalog_dialogs.dart / catalog_primitives.dart) so the catalog is split '
      'by UI domain rather than by size index (Refs #3546)',
    );
  }

  if (violations.isEmpty) {
    logI(
      'check_app_widgetbook_file_naming: Widgetbook catalog parts use '
      'domain names (no catalog_partN.dart fragments).',
    );
    return 0;
  }
  logE('check_app_widgetbook_file_naming: ${violations.length} violation(s):');
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAppWidgetbookFileNaming(Directory.current.path));
}
