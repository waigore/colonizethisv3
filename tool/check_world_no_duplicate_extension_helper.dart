import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Top-level helper names that have a same-named `WorldState` extension method
/// and must not be re-implemented as a parallel definition (Refs #3710 CI item
/// 2). The free function is allowed only as a thin delegator to the canonical
/// extension method; any other body reintroduces the duplication the #3710
/// refactor removed. Initially scoped to `allProvinces`; extend this set as
/// further free/extension pairs are consolidated.
const Set<String> worldDuplicateExtensionHelperNames = <String>{
  'allProvinces',
};

/// Lib path prefix scanned for duplicate top-level helpers.
const String worldDuplicateExtensionHelperScanPrefix =
    'packages/colonizethis_world/lib/';

/// One top-level function that duplicates a same-named `WorldState` extension
/// method instead of delegating to it.
class WorldDuplicateExtensionHelperViolation {
  const WorldDuplicateExtensionHelperViolation({
    required this.path,
    required this.line,
    required this.symbol,
  });

  final String path;
  final int line;
  final String symbol;
}

class _DuplicateExtensionHelperVisitor extends RecursiveAstVisitor<void> {
  _DuplicateExtensionHelperVisitor({
    required this.relativePath,
    required this.lineInfo,
    required this.out,
  });

  final String relativePath;
  final LineInfo lineInfo;
  final List<WorldDuplicateExtensionHelperViolation> out;

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final name = node.name.lexeme;
    if (worldDuplicateExtensionHelperNames.contains(name) &&
        !_bodyDelegatesToExtensionMethod(name, node.functionExpression.body)) {
      out.add(
        WorldDuplicateExtensionHelperViolation(
          path: relativePath,
          line: lineInfo.getLocation(node.name.offset).lineNumber,
          symbol: name,
        ),
      );
    }
    super.visitFunctionDeclaration(node);
  }

  /// True when [body] is a single delegating call `<target>.<name>()` (either
  /// `=> target.name()` or `{ return target.name(); }`), i.e. the free function
  /// forwards to the canonical extension method on its `WorldState` argument and
  /// holds no independent dual-region traversal of its own.
  bool _bodyDelegatesToExtensionMethod(String name, FunctionBody body) {
    if (body is ExpressionFunctionBody) {
      return _isExtensionMethodDelegation(name, body.expression);
    }
    if (body is BlockFunctionBody) {
      final statements = body.block.statements;
      if (statements.length != 1) return false;
      final only = statements.first;
      if (only is! ReturnStatement) return false;
      final expr = only.expression;
      return expr != null && _isExtensionMethodDelegation(name, expr);
    }
    return false;
  }

  bool _isExtensionMethodDelegation(String name, Expression expression) {
    if (expression is! MethodInvocation) return false;
    if (expression.methodName.name != name) return false;
    if (expression.target is! SimpleIdentifier) return false;
    return expression.argumentList.arguments.isEmpty;
  }
}

/// Pure per-file check for the "no duplicate top-level helper that shadows a
/// `WorldState` extension method" contract (Refs #3710). Flags top-level
/// functions in [worldDuplicateExtensionHelperNames] whose body does more than
/// delegate to the same-named extension method.
List<WorldDuplicateExtensionHelperViolation>
findWorldDuplicateExtensionHelperViolations({
  required String relativePath,
  required String source,
}) {
  final normalized = relativePath.replaceAll('\\', '/');
  if (!normalized.startsWith(worldDuplicateExtensionHelperScanPrefix)) {
    return const [];
  }
  final parsed = parseString(
    content: source,
    path: relativePath,
    throwIfDiagnostics: false,
  );
  final out = <WorldDuplicateExtensionHelperViolation>[];
  parsed.unit.accept(
    _DuplicateExtensionHelperVisitor(
      relativePath: normalized,
      lineInfo: parsed.unit.lineInfo,
      out: out,
    ),
  );
  return out;
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckWorldNoDuplicateExtensionHelper(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);

  final violations = <WorldDuplicateExtensionHelperViolation>[];
  for (final file in collectRepoLintDomainDartFiles(root)) {
    final rel = p.relative(file.path, from: root).replaceAll('\\', '/');
    if (!rel.startsWith(worldDuplicateExtensionHelperScanPrefix)) {
      continue;
    }
    violations.addAll(
      findWorldDuplicateExtensionHelperViolations(
        relativePath: rel,
        source: file.readAsStringSync(),
      ),
    );
  }

  if (violations.isEmpty) {
    logI(
      'check_world_no_duplicate_extension_helper: no top-level helper '
      'duplicates a same-named WorldState extension method '
      '(watched: ${worldDuplicateExtensionHelperNames.join(', ')}).',
    );
    return 0;
  }

  violations.sort((a, b) {
    final byPath = a.path.compareTo(b.path);
    return byPath != 0 ? byPath : a.line.compareTo(b.line);
  });
  logE(
    'check_world_no_duplicate_extension_helper: found ${violations.length} '
    'regression(s):',
  );
  for (final v in violations) {
    logE(
      ' - ${v.path}:${v.line} top-level "${v.symbol}(...)" must delegate to the '
      'WorldState extension method (e.g. "world.${v.symbol}()"), not '
      're-implement it. Refs #3710.',
    );
  }
  return 1;
}

void main() {
  exit(runCheckWorldNoDuplicateExtensionHelper(Directory.current.path));
}
