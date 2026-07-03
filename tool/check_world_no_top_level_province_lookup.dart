import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Top-level province-lookup wrappers removed in favour of the
/// `WorldStateProvinceLookup` extension methods (Refs #3403 / #3843).
const Set<String> deprecatedTopLevelProvinceLookupSymbols = <String>{
  'getProvince',
  'tryGetProvince',
  'getProvinceByRegion',
  'tryGetProvinceByRegion',
};

const String provinceLookupCanonicalPath =
    'packages/colonizethis_world/lib/src/world/province_lookup.dart';

/// Lib path prefix that the world-layer "zero internal callers" contract guards.
const String worldLibScanPrefix = 'packages/colonizethis_world/lib/';

/// One unqualified top-level province-lookup call inside the world layer.
class WorldTopLevelProvinceLookupViolation {
  const WorldTopLevelProvinceLookupViolation({
    required this.path,
    required this.line,
    required this.symbol,
    required this.kind,
  });

  final String path;
  final int line;
  final String symbol;

  /// `call` for unqualified invocations; `definition` for reintroduced wrappers.
  final String kind;
}

class _TopLevelProvinceLookupCallVisitor extends RecursiveAstVisitor<void> {
  _TopLevelProvinceLookupCallVisitor({
    required this.relativePath,
    required this.lineInfo,
    required this.out,
  });

  final String relativePath;
  final LineInfo lineInfo;
  final List<WorldTopLevelProvinceLookupViolation> out;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // A `target` (e.g. `world.tryGetProvince(...)`) is the extension method and
    // is allowed; only unqualified `tryGetProvince(world, ...)` is flagged.
    if (node.target == null) {
      final name = node.methodName.name;
      if (deprecatedTopLevelProvinceLookupSymbols.contains(name)) {
        out.add(
          WorldTopLevelProvinceLookupViolation(
            path: relativePath,
            line: lineInfo.getLocation(node.methodName.offset).lineNumber,
            symbol: name,
            kind: 'call',
          ),
        );
      }
    }
    super.visitMethodInvocation(node);
  }
}

class _DeprecatedTopLevelProvinceLookupDefinitionVisitor
    extends RecursiveAstVisitor<void> {
  _DeprecatedTopLevelProvinceLookupDefinitionVisitor({
    required this.relativePath,
    required this.lineInfo,
    required this.out,
  });

  final String relativePath;
  final LineInfo lineInfo;
  final List<WorldTopLevelProvinceLookupViolation> out;

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final name = node.name.lexeme;
    if (deprecatedTopLevelProvinceLookupSymbols.contains(name)) {
      out.add(
        WorldTopLevelProvinceLookupViolation(
          path: relativePath,
          line: lineInfo.getLocation(node.name.offset).lineNumber,
          symbol: name,
          kind: 'definition',
        ),
      );
    }
    super.visitFunctionDeclaration(node);
  }
}

/// Pure per-file check for the world-layer "no top-level province-lookup
/// callers" contract (Refs #3403). Flags unqualified invocations of any
/// [deprecatedTopLevelProvinceLookupSymbols] symbol; callers must use the
/// `WorldStateProvinceLookup` extension method on [WorldState] instead.
List<WorldTopLevelProvinceLookupViolation>
findWorldTopLevelProvinceLookupViolations({
  required String relativePath,
  required String source,
}) {
  final normalized = relativePath.replaceAll('\\', '/');
  if (!normalized.startsWith(worldLibScanPrefix)) {
    return const [];
  }
  final parsed = parseString(
    content: source,
    path: relativePath,
    throwIfDiagnostics: false,
  );
  final out = <WorldTopLevelProvinceLookupViolation>[];
  if (normalized == provinceLookupCanonicalPath) {
    parsed.unit.accept(
      _DeprecatedTopLevelProvinceLookupDefinitionVisitor(
        relativePath: normalized,
        lineInfo: parsed.unit.lineInfo,
        out: out,
      ),
    );
    return out;
  }
  parsed.unit.accept(
    _TopLevelProvinceLookupCallVisitor(
      relativePath: normalized,
      lineInfo: parsed.unit.lineInfo,
      out: out,
    ),
  );
  return out;
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckWorldNoTopLevelProvinceLookup(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);

  final violations = <WorldTopLevelProvinceLookupViolation>[];
  for (final file in collectRepoLintDomainDartFiles(root)) {
    final rel = p.relative(file.path, from: root).replaceAll('\\', '/');
    if (!rel.startsWith(worldLibScanPrefix)) {
      continue;
    }
    violations.addAll(
      findWorldTopLevelProvinceLookupViolations(
        relativePath: rel,
        source: file.readAsStringSync(),
      ),
    );
  }

  if (violations.isEmpty) {
    logI(
      'check_world_no_top_level_province_lookup: no world-layer callers or '
      'definitions of deprecated top-level province-lookup wrappers.',
    );
    return 0;
  }

  violations.sort((a, b) {
    final byPath = a.path.compareTo(b.path);
    if (byPath != 0) return byPath;
    final byLine = a.line.compareTo(b.line);
    if (byLine != 0) return byLine;
    return a.kind.compareTo(b.kind);
  });
  logE(
    'check_world_no_top_level_province_lookup: found ${violations.length} '
    'regression(s):',
  );
  for (final v in violations) {
    if (v.kind == 'definition') {
      logE(
        ' - ${v.path}:${v.line} top-level "${v.symbol}" wrapper definition; '
        'use WorldStateProvinceLookup extension methods only. Refs #3843.',
      );
      continue;
    }
    logE(
      ' - ${v.path}:${v.line} unqualified top-level "${v.symbol}(...)" call; '
      'use the WorldStateProvinceLookup extension method on WorldState '
      '(e.g. world.${v.symbol}(...)). Refs #3403.',
    );
  }
  return 1;
}

void main() {
  exit(runCheckWorldNoTopLevelProvinceLookup(Directory.current.path));
}
