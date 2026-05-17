import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// AST gate: repeated integer literals in domain `lib/` trees should become named
/// constants. SPEC: SPEC/program/repeated-magic-numbers.md
///
/// Warn when the same value appears ≥3 times; fail when ≥5.
///
/// Issue #1747: focus on hash/LCG-style literals, not routine UI sizes or scores.
/// Count a literal when it is **hex** (`0x…`), or **decimal** with
/// [abs] ≥ [_largeDecimalAbsMin], or in [_knownDecimalMagic].
const _largeDecimalAbsMin = 0x1000000; // 16_777_216
const Set<int> _knownDecimalMagic = {1103515245, 12345};
const _tinyAbsMaxExempt = 2; // same spirit as -1, 0, 1, 2 in the issue
const _warnThreshold = 3;
const _failThreshold = 5;

/// One counted literal site (for tests and aggregation).
final class MagicLiteralOccurrence {
  const MagicLiteralOccurrence({
    required this.value,
    required this.path,
    required this.line,
  });

  final int value;
  final String path;
  final int line;
}

int runCheckRepeatedMagicNumbers(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
  void Function(String line)? warn,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final logW = warn ?? stderr.writeln;

  final files = collectRepoLintDomainDartFiles(repoRoot);
  final occurrences = <MagicLiteralOccurrence>[];

  for (final file in files) {
    final rel = p.relative(file.path, from: repoRoot);
    final content = file.readAsStringSync();
    occurrences.addAll(collectMagicLiteralsFromSource(rel, content));
  }

  final byValue = <int, List<MagicLiteralOccurrence>>{};
  for (final o in occurrences) {
    byValue.putIfAbsent(o.value, () => []).add(o);
  }

  var exitCode = 0;
  final keys = byValue.keys.toList()..sort();
  for (final value in keys) {
    final sites = byValue[value]!;
    final count = sites.length;
    if (count < _warnThreshold) continue;
    final label = '$value';
    if (count >= _failThreshold) {
      exitCode = 1;
      logE(
        'repeated_magic_numbers: value $label appears $count times '
        '(fail threshold $_failThreshold):',
      );
      for (final o in sites) {
        logE('  ${o.path}:${o.line}');
      }
    } else {
      logW(
        'repeated_magic_numbers: WARNING value $label appears $count times '
        '(warn at $_warnThreshold, fail at $_failThreshold):',
      );
      for (final o in sites) {
        logW('  ${o.path}:${o.line}');
      }
    }
  }

  if (exitCode == 0) {
    logI('repeated_magic_numbers: no fail-level repeated literals.');
  }
  return exitCode;
}

/// Exposed for unit tests.
List<MagicLiteralOccurrence> collectMagicLiteralsFromSource(
  String relativePath,
  String content,
) {
  // Keep repeated-magic-numbers scoped to production code paths.
  // Per SPEC/program/repeated-magic-numbers.md, package/app test trees remain
  // excluded even though other AST checkers now scan tests (#2014).
  if (repoLintPathIsExcludedTestOrGeneratedDart(relativePath)) {
    return const [];
  }

  final parsed = parseString(
    content: content,
    path: relativePath,
    throwIfDiagnostics: false,
  );

  final visitor = _MagicLiteralVisitor(relativePath, parsed.lineInfo);
  parsed.unit.accept(visitor);
  return visitor.occurrences;
}

void main() {
  exit(runCheckRepeatedMagicNumbers(Directory.current.path));
}

final class _MagicLiteralVisitor extends RecursiveAstVisitor<void> {
  _MagicLiteralVisitor(this.relativePath, this.lineInfo);

  final String relativePath;
  final LineInfo lineInfo;
  final List<MagicLiteralOccurrence> occurrences = [];

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    final p = node.parent;
    if (p is PrefixExpression && p.operator.lexeme == '-') {
      super.visitIntegerLiteral(node);
      return;
    }
    _maybeRecord(node, node.value, node);
    super.visitIntegerLiteral(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if (node.operator.lexeme == '-' && node.operand is IntegerLiteral) {
      final lit = node.operand as IntegerLiteral;
      final v = lit.value;
      if (v != null) {
        _maybeRecord(node, -v, lit);
      }
    }
    super.visitPrefixExpression(node);
  }

  void _maybeRecord(AstNode node, int? value, IntegerLiteral literal) {
    if (value == null) return;
    if (value.abs() <= _tinyAbsMaxExempt) return;
    if (!_shouldCountAsMagicLiteral(literal, value)) return;
    if (_insideStringInterpolation(node)) return;
    if (_insideEnumConstantDeclaration(node)) return;
    if (_isUnderConstVariableInitializer(node)) return;

    final line = lineInfo.getLocation(node.offset).lineNumber;
    occurrences.add(
      MagicLiteralOccurrence(value: value, path: relativePath, line: line),
    );
  }
}

bool _insideStringInterpolation(AstNode node) {
  for (AstNode? p = node.parent; p != null; p = p.parent) {
    if (p is StringInterpolation) return true;
  }
  return false;
}

bool _insideEnumConstantDeclaration(AstNode node) {
  for (AstNode? p = node.parent; p != null; p = p.parent) {
    if (p is EnumConstantDeclaration) return true;
  }
  return false;
}

bool _isUnderConstVariableInitializer(AstNode node) {
  AstNode? n = node;
  while (n != null) {
    final p = n.parent;
    if (p is VariableDeclaration) {
      final vd = p;
      final init = vd.initializer;
      if (init != null && _isDescendantOf(init, node)) {
        final vdl = vd.parent;
        if (vdl is VariableDeclarationList && vdl.isConst) {
          return true;
        }
      }
    }
    n = p;
  }
  return false;
}

bool _isDescendantOf(AstNode root, AstNode node) {
  AstNode? cur = node;
  while (cur != null) {
    if (identical(cur, root)) return true;
    cur = cur.parent;
  }
  return false;
}

bool _shouldCountAsMagicLiteral(IntegerLiteral literal, int signedValue) {
  final lexeme = literal.literal.lexeme;
  if (lexeme.startsWith('0x') || lexeme.startsWith('0X')) {
    return true;
  }
  final a = signedValue.abs();
  if (_knownDecimalMagic.contains(a)) {
    return true;
  }
  return a >= _largeDecimalAbsMin;
}
