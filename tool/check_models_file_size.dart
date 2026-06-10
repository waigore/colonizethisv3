// Non-comment line limit for colonizethis_models lib/src
// (`repo.models_file_size`). Refs #3393, Phase 5 — model file splitting.
// SPEC: SPEC/program/repo-lint.md
//
// `colonizethis_models` hosts the shared value types consumed by every domain
// package and the app. Several of its `lib/src` files had grown past 500
// non-comment lines, mixing many unrelated concerns in one file. Phase 5 splits
// the largest offenders by concern; this gate caps `colonizethis_models/lib/src`
// at 500 non-comment lines (the repo-wide gate is 1000) so splits do not
// silently regress. Files still pending a split are grandfathered via
// `tool/models_file_size_baseline.json`; the baseline is append-only-shrinking:
// removing a file from it (after splitting) is the goal, adding to it is not.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'check_dart_file_non_comment_line_size.dart'
    show countNonCommentLinesFromSource;

const _modelsSrcRelative = 'packages/colonizethis_models/lib/src';
const _baselineRelative = 'tool/models_file_size_baseline.json';
const _maxNonCommentLines = 500;

void main() {
  exit(runCheckModelsFileSize(Directory.current.path));
}

int runCheckModelsFileSize(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final srcDir = Directory(p.join(repoRoot, _modelsSrcRelative));
  if (!srcDir.existsSync()) {
    logE('check_models_file_size: missing $_modelsSrcRelative');
    return 1;
  }

  final baseline = _loadBaseline(p.join(repoRoot, _baselineRelative));
  final violations = <String>[];

  for (final entity in srcDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final relative =
        '$_modelsSrcRelative/${p.relative(entity.path, from: srcDir.path)}'
            .replaceAll('\\', '/');
    if (baseline.contains(relative)) continue;

    final nonCommentLines = countNonCommentLinesFromSource(
      entity.readAsStringSync(),
    );
    if (nonCommentLines > _maxNonCommentLines) {
      violations.add(
        '$relative ($nonCommentLines non-comment lines > $_maxNonCommentLines)',
      );
    }
  }

  if (violations.isEmpty) {
    logI('check_models_file_size: no violations outside baseline.');
    return 0;
  }

  violations.sort();
  logE(
    'check_models_file_size: found ${violations.length} violation(s) '
    '(non-comment lines > $_maxNonCommentLines). Split the file by concern '
    '(Refs #3393 Phase 5) instead of growing it:',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

Set<String> _loadBaseline(String baselinePath) {
  final file = File(baselinePath);
  if (!file.existsSync()) return <String>{};
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! List) return <String>{};
  return decoded.map((e) => e.toString()).toSet();
}

int maxModelsNonCommentLinesForTests() => _maxNonCommentLines;
