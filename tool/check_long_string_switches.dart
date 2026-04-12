// Flags Dart switches whose case patterns are predominantly string literals.
// Warn when >= 20 such cases; exit 1 when >= 50 (see issue #1748).
//
// Run from repo root: dart tool/check_long_string_switches.dart

import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

void main() {
  final root = _repoRoot();
  final fails = <String>[];
  final warns = <String>[];

  for (final file in _dartSources(Directory(root))) {
    final rel = p.relative(file.path, from: root);
    if (_isExcluded(rel)) {
      continue;
    }
    final parsed = parseFile(
      path: file.path,
      featureSet: FeatureSet.latestLanguageVersion(),
      throwIfDiagnostics: false,
    );
    if (parsed.errors.isNotEmpty) {
      stderr.writeln(
        'warning: $rel — skipping AST switch scan (${parsed.errors.length} parse errors)',
      );
      continue;
    }
    final unit = parsed.unit;
    unit.accept(_SwitchVisitor(rel, parsed.lineInfo, fails, warns));
  }

  for (final w in warns) {
    stderr.writeln('warning: $w');
  }
  for (final f in fails) {
    stderr.writeln('error: $f');
  }
  if (fails.isNotEmpty) {
    exitCode = 1;
  }
}

bool _isExcluded(String relativePath) {
  final normalized = p.normalize(relativePath);
  final parts = p.split(normalized);
  if (parts.contains('.dart_tool') ||
      parts.contains('.pub-cache') ||
      parts.contains('build')) {
    return true;
  }
  if (normalized.endsWith('.g.dart')) {
    return true;
  }
  if (normalized.endsWith('tech_effect_summary_embed.dart')) {
    return true;
  }
  return false;
}

Iterable<File> _dartSources(Directory root) sync* {
  if (!root.existsSync()) {
    return;
  }
  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) {
      continue;
    }
    if (!entity.path.endsWith('.dart')) {
      continue;
    }
    yield entity;
  }
}

/// Workspace root `pubspec.yaml` uses exactly `name: colonizethis` (not
/// `colonizethis_app`, `colonizethis_data`, etc.) so nested packages are not
/// mistaken for the monorepo root when this tool is run from a subdirectory.
String _repoRoot() {
  final rootName = RegExp(r'^name:\s*colonizethis\s*$', multiLine: true);
  var dir = Directory.current;
  while (true) {
    final pub = File(p.join(dir.path, 'pubspec.yaml'));
    if (pub.existsSync() && rootName.hasMatch(pub.readAsStringSync())) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('repo root not found');
    }
    dir = parent;
  }
}

class _SwitchVisitor extends RecursiveAstVisitor<void> {
  _SwitchVisitor(this.filePath, this.lineInfo, this.fails, this.warns);

  final String filePath;
  final LineInfo lineInfo;
  final List<String> fails;
  final List<String> warns;

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
