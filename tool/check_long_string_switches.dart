// Flags Dart switches whose case patterns are predominantly string literals.
// Warn when >= 20 such cases; exit 1 when >= 50 (see issue #1748).
//
// Run from repo root: dart tool/check_long_string_switches.dart

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

int runCheckLongStringSwitches(
  String repoRoot, {
  void Function(String line)? warn,
  void Function(String line)? err,
}) {
  final logW = warn ?? stderr.writeln;
  final logE = err ?? stderr.writeln;
  final fails = <String>[];
  final warns = <String>[];

  for (final file in collectRepoLintRepoWideDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot);
    final source = file.readAsStringSync();
    warns.addAll(scanLongStringSwitchWarnings(rel, source));
    fails.addAll(scanLongStringSwitchErrors(rel, source));
  }

  for (final w in warns) {
    logW('warning: $w');
  }
  for (final f in fails) {
    logE('error: $f');
  }
  return fails.isNotEmpty ? 1 : 0;
}

class _SwitchVisitor extends RecursiveAstVisitor<void> {
  _SwitchVisitor(this.filePath, this.lineInfo, this.warns, this.fails);

  final String filePath;
  final LineInfo lineInfo;
  final List<String> warns;
  final List<String> fails;

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _report(node.members, node.switchKeyword.offset);
    super.visitSwitchStatement(node);
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    _reportExpressionCases(node.cases, node.switchKeyword.offset);
    super.visitSwitchExpression(node);
  }

  void _report(List<SwitchMember> members, int offset) {
    final n = _countStringCases(members);
    _threshold(n, offset);
  }

  void _reportExpressionCases(List<SwitchExpressionCase> cases, int offset) {
    var n = 0;
    for (final c in cases) {
      if (_isStringConstantPattern(c.guardedPattern.pattern)) {
        n++;
      }
    }
    _threshold(n, offset);
  }

  void _threshold(int n, int offset) {
    if (n == 0) {
      return;
    }
    final line = lineInfo.getLocation(offset).lineNumber;
    final loc = '$filePath:$line';
    if (n >= 50) {
      fails.add('$loc — switch has $n string-literal cases (limit 49)');
    } else if (n >= 20) {
      warns.add(
        '$loc — switch has $n string-literal cases (warn threshold 20)',
      );
    }
  }
}

int _countStringCases(List<SwitchMember> members) {
  var n = 0;
  for (final m in members) {
    if (m is! SwitchPatternCase) {
      continue;
    }
    if (_isStringConstantPattern(m.guardedPattern.pattern)) {
      n++;
    }
  }
  return n;
}

bool _isStringConstantPattern(AstNode? pattern) {
  if (pattern is ConstantPattern) {
    return pattern.expression is SimpleStringLiteral;
  }
  return false;
}

List<String> scanLongStringSwitchWarnings(String relativePath, String content) {
  return _scanLongStringSwitches(relativePath, content).warns;
}

List<String> scanLongStringSwitchErrors(String relativePath, String content) {
  return _scanLongStringSwitches(relativePath, content).fails;
}

({List<String> warns, List<String> fails}) _scanLongStringSwitches(
  String relativePath,
  String content,
) {
  final parsed = parseString(
    content: content,
    path: relativePath,
    throwIfDiagnostics: false,
  );
  if (parsed.errors.isNotEmpty) {
    return (
      warns: <String>[
        '$relativePath — skipping AST switch scan (${parsed.errors.length} parse errors)',
      ],
      fails: <String>[],
    );
  }
  final warns = <String>[];
  final fails = <String>[];
  parsed.unit.accept(
    _SwitchVisitor(relativePath, parsed.lineInfo, warns, fails),
  );
  return (warns: warns, fails: fails);
}

void main() {
  exit(runCheckLongStringSwitches(Directory.current.path));
}
