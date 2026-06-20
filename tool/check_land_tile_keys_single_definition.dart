import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Canonical symbol that must have exactly one definition (Refs #3403 Phase 1).
const String landTileKeysSymbol = 'landTileKeysForProvinceBucket';

/// The only `lib/` file allowed to declare [landTileKeysSymbol] top-level.
const String landTileKeysCanonicalPath =
    'packages/colonizethis_world/lib/src/world/province_lookup.dart';

/// One violation of the single-definition / no-`hide` contract.
class LandTileKeysSingleDefinitionViolation {
  const LandTileKeysSingleDefinitionViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}

/// Pure per-file check for the `landTileKeysForProvinceBucket` dedup contract.
///
/// Flags two regressions:
/// 1. A second top-level definition of [landTileKeysSymbol] in any `lib/` file
///    other than [landTileKeysCanonicalPath]. Callers that need the legacy /
///    fixture local-id bucket fallback must route through the canonical
///    function's `allowLocalIdFallback: true` parameter instead of declaring a
///    divergent copy.
/// 2. Any `hide landTileKeysForProvinceBucket` import/export combinator, which
///    was the workaround for the former duplicate and is no longer needed.
List<LandTileKeysSingleDefinitionViolation>
findLandTileKeysSingleDefinitionViolations({
  required String relativePath,
  required String source,
}) {
  final normalized = relativePath.replaceAll('\\', '/');
  final parsed = parseString(
    content: source,
    path: relativePath,
    throwIfDiagnostics: false,
  );
  final lineInfo = parsed.unit.lineInfo;
  final out = <LandTileKeysSingleDefinitionViolation>[];

  for (final decl in parsed.unit.declarations) {
    if (decl is FunctionDeclaration && decl.name.lexeme == landTileKeysSymbol) {
      if (normalized == landTileKeysCanonicalPath) {
        continue;
      }
      out.add(
        LandTileKeysSingleDefinitionViolation(
          path: normalized,
          line: lineInfo.getLocation(decl.offset).lineNumber,
          message:
              'top-level function "$landTileKeysSymbol" must be defined only in '
              '$landTileKeysCanonicalPath; route callers needing the legacy '
              'local-id bucket through its `allowLocalIdFallback: true` parameter.',
        ),
      );
    }
  }

  for (final directive in parsed.unit.directives) {
    if (directive is! NamespaceDirective) {
      continue;
    }
    for (final combinator in directive.combinators) {
      if (combinator is! HideCombinator) {
        continue;
      }
      for (final name in combinator.hiddenNames) {
        if (name.name != landTileKeysSymbol) {
          continue;
        }
        out.add(
          LandTileKeysSingleDefinitionViolation(
            path: normalized,
            line: lineInfo.getLocation(name.offset).lineNumber,
            message:
                '`hide $landTileKeysSymbol` is no longer needed; the symbol has '
                'a single canonical definition in $landTileKeysCanonicalPath.',
          ),
        );
      }
    }
  }

  return out;
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckLandTileKeysSingleDefinition(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);

  final violations = <LandTileKeysSingleDefinitionViolation>[];
  for (final file in collectRepoLintDomainDartFiles(root)) {
    final rel = p.relative(file.path, from: root).replaceAll('\\', '/');
    // Definitions and `hide` carve-outs are a `lib/` concern.
    if (!rel.contains('/lib/')) {
      continue;
    }
    violations.addAll(
      findLandTileKeysSingleDefinitionViolations(
        relativePath: rel,
        source: file.readAsStringSync(),
      ),
    );
  }

  if (violations.isEmpty) {
    logI(
      'check_land_tile_keys_single_definition: single canonical '
      '"$landTileKeysSymbol" definition; no `hide` workarounds.',
    );
    return 0;
  }

  violations.sort((a, b) {
    final byPath = a.path.compareTo(b.path);
    return byPath != 0 ? byPath : a.line.compareTo(b.line);
  });
  logE(
    'check_land_tile_keys_single_definition: found ${violations.length} '
    'regression(s):',
  );
  for (final v in violations) {
    logE(' - ${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckLandTileKeysSingleDefinition(Directory.current.path));
}
