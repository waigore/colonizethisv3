import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Repo-relative path to the only library file allowed to call `.split('|')` / `.split("|")`.
const _allowedPipeSplitLibFile = 'packages/colonizethis_map/lib/src/tile_key_util.dart';

/// Matches `.split('|')`, `.split("|")`, `.split(r'|')`, `.split(r"|")` with optional spaces.
final _pipeSplitLiteralPattern = RegExp(
  r'''\.split\s*\(\s*r?['"]\|['"]\s*\)''',
);

/// One `.split('|'|"|…)` use outside [tile_key_util.dart](packages/colonizethis_map/lib/src/tile_key_util.dart).
final class ColonizethisMapPipeSplitViolation {
  const ColonizethisMapPipeSplitViolation({
    required this.path,
    required this.line,
    required this.snippet,
  });

  final String path;
  final int line;
  final String snippet;
}

/// Returns violations for [relativePath] / [source] under `packages/colonizethis_map/lib/`.
List<ColonizethisMapPipeSplitViolation> findColonizethisMapLibPipeSplitViolations({
  required String relativePath,
  required String source,
}) {
  final normalized = p.normalize(relativePath);
  final mapLibPrefix =
      p.join('packages', 'colonizethis_map', 'lib') + p.separator;
  if (!normalized.startsWith(mapLibPrefix)) {
    return const [];
  }
  if (normalized == p.normalize(_allowedPipeSplitLibFile)) {
    return const [];
  }
  final violations = <ColonizethisMapPipeSplitViolation>[];
  final lines = const LineSplitter().convert(source);
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final code = _stripTrailingLineComment(line);
    if (!_pipeSplitLiteralPattern.hasMatch(code)) {
      continue;
    }
    violations.add(
      ColonizethisMapPipeSplitViolation(
        path: relativePath,
        line: i + 1,
        snippet: line.trim(),
      ),
    );
  }
  return violations;
}

String _stripTrailingLineComment(String line) {
  final idx = line.indexOf('//');
  if (idx < 0) {
    return line;
  }
  return line.substring(0, idx);
}

/// PR-blocking gate: all pipe-delimited string splits in `colonizethis_map` lib live in
/// [tile_key_util.dart](packages/colonizethis_map/lib/src/tile_key_util.dart) (GitHub #2087).
int runCheckColonizethisMapLibPipeSplits(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final libDir = Directory(p.join(root, 'packages', 'colonizethis_map', 'lib'));
  if (!libDir.existsSync()) {
    logE('check_colonizethis_map_lib_pipe_splits: missing ${libDir.path}');
    return 1;
  }

  final violations = <ColonizethisMapPipeSplitViolation>[];
  for (final entity in libDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final rel = p.normalize(p.relative(entity.path, from: root));
    final src = entity.readAsStringSync();
    violations.addAll(
      findColonizethisMapLibPipeSplitViolations(relativePath: rel, source: src),
    );
  }

  if (violations.isEmpty) {
    logI('check_colonizethis_map_lib_pipe_splits: no violations found.');
    return 0;
  }

  logE(
    'check_colonizethis_map_lib_pipe_splits: pipe-delimited .split(...) must live only in '
    '$_allowedPipeSplitLibFile (${violations.length} violation(s)):',
  );
  for (final v in violations) {
    logE(' - ${v.path}:${v.line}: ${v.snippet}');
  }
  return 1;
}

void main(List<String> args) {
  final code = runCheckColonizethisMapLibPipeSplits(Directory.current.path);
  exit(code);
}
