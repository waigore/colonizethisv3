import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

const _maxPartFragmentPhysicalLines = 1000;

int runCheckPartUnitSize(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot);
    final content = file.readAsStringSync();
    if (!_isDartPartFragmentFile(content)) {
      continue;
    }
    final lineCount = _countPhysicalLines(content);
    if (lineCount > _maxPartFragmentPhysicalLines) {
      violations.add(
        '$rel: part fragment file has $lineCount physical lines '
        '(max=$_maxPartFragmentPhysicalLines)',
      );
    }
  }

  if (violations.isEmpty) {
    logI('check_part_unit_size: no part-unit size violations.');
    return 0;
  }
  logE('check_part_unit_size: ${violations.length} violation(s):');
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

int _countPhysicalLines(String content) => content.split('\n').length;

/// True when the first non-empty, non-line-comment line is a `part of` directive.
bool _isDartPartFragmentFile(String content) {
  for (final raw in content.split('\n')) {
    final line = raw.trimLeft();
    if (line.isEmpty) {
      continue;
    }
    if (line.startsWith('//')) {
      continue;
    }
    return line.startsWith('part of ');
  }
  return false;
}

void main() {
  exit(runCheckPartUnitSize(Directory.current.path));
}
