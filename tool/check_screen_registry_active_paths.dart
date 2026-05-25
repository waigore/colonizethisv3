import 'dart:io';

import 'package:path/path.dart' as p;

/// PR-blocking structural check: every `active` row in
/// [`SPEC/ui/screen-registry.md`] must have an Implementation cell that
/// resolves to an existing `.dart` file under `app/lib/`.
///
/// Rationale (issue #2801): the registry promised `colonizethis-ui-documentation.mdc`
/// § Registry maintenance — `active` requires spec + Widgetbook + code binding.
/// Rows that stayed `active` while their Implementation column was `TBD` (or a
/// stale path) silently violated that contract. CI now blocks the drift.
///
/// Scope (intentionally narrow):
/// - Reads only the table under the `## Registry` heading; ignores `draft` rows
///   (they may legitimately have `TBD` or `—` while spec/widget work catches up).
/// - The Implementation cell must be a single backticked `app/lib/...dart`
///   path; any literal `TBD`, empty cell, or non-`app/lib/` path fails for an
///   `active` row.
/// - The referenced file must exist on disk relative to [repoRoot].
///
/// SPEC: `SPEC/program/repo-lint.md` (and per-rule context: issue #2801).
int runCheckScreenRegistryActivePaths(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final registryFile = File(
    p.join(repoRoot, 'SPEC', 'ui', 'screen-registry.md'),
  );
  if (!registryFile.existsSync()) {
    logE(
      'check_screen_registry_active_paths: SPEC/ui/screen-registry.md not found.',
    );
    return 1;
  }

  final rows = parseScreenRegistryRows(registryFile.readAsStringSync());
  final activeRows = rows.where((r) => r.status == 'active').toList();
  if (activeRows.isEmpty) {
    logE(
      'check_screen_registry_active_paths: no `active` rows found '
      '(table is empty or malformed).',
    );
    return 1;
  }

  final violations = <String>[];
  for (final row in activeRows) {
    final cell = row.implementationCell.trim();
    final pathFromCell = extractDartPathFromCell(cell);
    if (pathFromCell == null) {
      violations.add(
        '${row.id} (line ${row.lineNumber}): Implementation cell is not a '
        'valid `app/lib/...dart` path (got "$cell").',
      );
      continue;
    }
    final absolute = p.normalize(p.join(repoRoot, pathFromCell));
    if (!File(absolute).existsSync()) {
      violations.add(
        '${row.id} (line ${row.lineNumber}): Implementation path '
        '`$pathFromCell` does not exist on disk.',
      );
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_screen_registry_active_paths: all '
      '${activeRows.length} active row(s) resolve to existing app/lib files.',
    );
    return 0;
  }

  logE(
    'check_screen_registry_active_paths: '
    'found ${violations.length} active row(s) with missing or invalid '
    'Implementation paths in SPEC/ui/screen-registry.md:',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  logE(
    'Fix: edit SPEC/ui/screen-registry.md so each `active` row points to an '
    'existing `app/lib/...dart` file, or demote the row to `draft` if the '
    'implementation is not in place yet.',
  );
  return 1;
}

/// Single parsed row from the `## Registry` table. Exposed for tests.
class ScreenRegistryRow {
  ScreenRegistryRow({
    required this.id,
    required this.implementationCell,
    required this.status,
    required this.lineNumber,
  });

  final String id;
  final String implementationCell;
  final String status;
  final int lineNumber;
}

/// Parses the `## Registry` markdown table. Tolerant of the header/separator
/// rows; intentionally strict about column count so a malformed row fails fast.
/// Exposed for tests.
List<ScreenRegistryRow> parseScreenRegistryRows(String markdown) {
  final lines = markdown.split('\n');
  final out = <ScreenRegistryRow>[];
  var inRegistrySection = false;
  for (var i = 0; i < lines.length; i++) {
    final raw = lines[i];
    final trimmed = raw.trim();
    if (trimmed.startsWith('## ')) {
      inRegistrySection = trimmed == '## Registry';
      continue;
    }
    if (!inRegistrySection || !trimmed.startsWith('|')) {
      continue;
    }
    // Skip the GFM header separator row (e.g. `|----|----|`).
    if (RegExp(r'^\|[\s\-:|]+\|$').hasMatch(trimmed)) {
      continue;
    }
    final cells = _splitMarkdownRow(trimmed);
    if (cells.length < 6) {
      continue;
    }
    final idCell = cells[0].trim();
    // Header row has `ID` (no backticks). Skip it.
    if (idCell == 'ID' || idCell.isEmpty) {
      continue;
    }
    final id = idCell.replaceAll('`', '').trim();
    out.add(
      ScreenRegistryRow(
        id: id,
        implementationCell: cells[3],
        status: cells[5].trim().toLowerCase(),
        lineNumber: i + 1,
      ),
    );
  }
  return out;
}

/// Returns the `app/lib/...dart` path inside [cell] when it is a single
/// backticked Dart path; otherwise returns `null` (covers `TBD`, `—`, empty,
/// or any non-`app/lib/` value). Exposed for tests.
String? extractDartPathFromCell(String cell) {
  final trimmed = cell.trim();
  if (trimmed.isEmpty || trimmed == 'TBD' || trimmed == '—') {
    return null;
  }
  final match = RegExp(r'^`([^`]+)`$').firstMatch(trimmed);
  if (match == null) {
    return null;
  }
  final path = match.group(1)!.trim();
  if (!path.startsWith('app/lib/') || !path.endsWith('.dart')) {
    return null;
  }
  return path;
}

List<String> _splitMarkdownRow(String row) {
  // Drop leading/trailing pipes so split yields actual cells.
  var trimmed = row.trim();
  if (trimmed.startsWith('|')) {
    trimmed = trimmed.substring(1);
  }
  if (trimmed.endsWith('|')) {
    trimmed = trimmed.substring(0, trimmed.length - 1);
  }
  return trimmed.split('|');
}

void main() {
  exit(runCheckScreenRegistryActivePaths(Directory.current.path));
}
