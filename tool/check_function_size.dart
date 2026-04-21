import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'ct_repo_lint_scan_contract.dart';

const _failThreshold = 20;
const _logicScopePrefix = 'packages/colonizethis_logic/lib/src/';

int runCheckFunctionSize(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final allowlist = _loadAllowlist(repoRoot);
  final files = collectRepoLintDomainDartFiles(repoRoot).where((file) {
    final rel = p.relative(file.path, from: repoRoot);
    return rel.startsWith(_logicScopePrefix);
  });
  final violations = <String>[];

  for (final file in files) {
    final relativePath = p.relative(file.path, from: repoRoot);
    final content = file.readAsStringSync();
    final parsed = parseString(content: content, path: relativePath);
    final unit = parsed.unit;
    final sourceLines = const LineSplitter().convert(content);
    final lineInfo = unit.lineInfo;
    _scanCompilationUnit(
      unit: unit,
      relativePath: relativePath,
      sourceLines: sourceLines,
      lineInfo: lineInfo,
      allowlist: allowlist,
      violations: violations,
    );
  }

  if (violations.isEmpty) {
    logI('check_function_size: no function-size violations.');
    return 0;
  }
  logE('check_function_size: ${violations.length} violation(s):');
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void _scanCompilationUnit({
  required CompilationUnit unit,
  required String relativePath,
  required List<String> sourceLines,
  required LineInfo lineInfo,
  required Map<String, int> allowlist,
  required List<String> violations,
}) {
  for (final decl in unit.declarations) {
    if (decl is FunctionDeclaration) {
      _scanFunction(
        node: decl,
        qualifiedName: decl.name.lexeme,
        relativePath: relativePath,
        sourceLines: sourceLines,
        lineInfo: lineInfo,
        allowlist: allowlist,
        violations: violations,
      );
      _scanNestedLocalFunctions(
        body: decl.functionExpression.body,
        parentQualifiedName: decl.name.lexeme,
        relativePath: relativePath,
        sourceLines: sourceLines,
        lineInfo: lineInfo,
        allowlist: allowlist,
        violations: violations,
      );
      continue;
    }
    if (decl is! ClassDeclaration) {
      continue;
    }
    for (final member in decl.members) {
      if (member is MethodDeclaration) {
        final qualified = '${decl.name.lexeme}.${member.name.lexeme}';
        _scanFunction(
          node: member,
          qualifiedName: qualified,
          relativePath: relativePath,
          sourceLines: sourceLines,
          lineInfo: lineInfo,
          allowlist: allowlist,
          violations: violations,
        );
        _scanNestedLocalFunctions(
          body: member.body,
          parentQualifiedName: qualified,
          relativePath: relativePath,
          sourceLines: sourceLines,
          lineInfo: lineInfo,
          allowlist: allowlist,
          violations: violations,
        );
      } else if (member is ConstructorDeclaration) {
        final ctorSuffix = member.name == null ? '' : ':${member.name!.lexeme}';
        final qualified = '${decl.name.lexeme}.<ctor$ctorSuffix>';
        _scanFunction(
          node: member,
          qualifiedName: qualified,
          relativePath: relativePath,
          sourceLines: sourceLines,
          lineInfo: lineInfo,
          allowlist: allowlist,
          violations: violations,
        );
        _scanNestedLocalFunctions(
          body: member.body,
          parentQualifiedName: qualified,
          relativePath: relativePath,
          sourceLines: sourceLines,
          lineInfo: lineInfo,
          allowlist: allowlist,
          violations: violations,
        );
      }
    }
  }
}

void _scanNestedLocalFunctions({
  required FunctionBody body,
  required String parentQualifiedName,
  required String relativePath,
  required List<String> sourceLines,
  required LineInfo lineInfo,
  required Map<String, int> allowlist,
  required List<String> violations,
}) {
  body.accept(
    _NestedLocalFunctionCollector(
      onLocalFunction: (node) {
        final qualifiedName = '$parentQualifiedName::${node.name.lexeme}';
        _scanFunction(
          node: node,
          qualifiedName: qualifiedName,
          relativePath: relativePath,
          sourceLines: sourceLines,
          lineInfo: lineInfo,
          allowlist: allowlist,
          violations: violations,
        );
      },
    ),
  );
}

void _scanFunction({
  required AstNode node,
  required String qualifiedName,
  required String relativePath,
  required List<String> sourceLines,
  required LineInfo lineInfo,
  required Map<String, int> allowlist,
  required List<String> violations,
}) {
  final start = lineInfo.getLocation(node.offset).lineNumber;
  final end = lineInfo.getLocation(node.end).lineNumber;
  final measured = _countMeasuredLines(sourceLines, start, end);
  if (measured <= _failThreshold) {
    return;
  }
  final key = '$relativePath|$qualifiedName';
  final allowedMax = allowlist[key];
  if (allowedMax != null && measured <= allowedMax) {
    return;
  }
  violations.add(
    '$relativePath:$start: `$qualifiedName` measured line count is $measured '
    '(fail >$_failThreshold${allowedMax != null ? ', allowlisted max=$allowedMax' : ''})',
  );
}

int _countMeasuredLines(
  List<String> lines,
  int startLine1Based,
  int endLine1Based,
) {
  var count = 0;
  final start = startLine1Based < 1 ? 1 : startLine1Based;
  final end = endLine1Based > lines.length ? lines.length : endLine1Based;
  for (var i = start; i <= end; i++) {
    final trimmed = lines[i - 1].trim();
    if (trimmed.isEmpty) {
      continue;
    }
    if (trimmed.startsWith('//')) {
      continue;
    }
    count++;
  }
  return count;
}

Map<String, int> _loadAllowlist(String repoRoot) {
  final file = File(p.join(repoRoot, 'tool', 'function_size_allowlist.yaml'));
  if (!file.existsSync()) {
    return const {};
  }
  final dynamic doc = loadYaml(file.readAsStringSync());
  if (doc is! YamlMap) {
    return const {};
  }
  final node = doc['allowed_over_20'];
  if (node is! YamlList) {
    return const {};
  }
  final out = <String, int>{};
  for (final dynamic item in node) {
    if (item is! YamlMap) {
      continue;
    }
    final filePath = item['file']?.toString();
    final symbol = item['symbol']?.toString();
    final maxMeasuredLines = item['max_measured_lines'];
    if (filePath == null || symbol == null || maxMeasuredLines is! int) {
      continue;
    }
    out['$filePath|$symbol'] = maxMeasuredLines;
  }
  return out;
}

List<({String symbol, int measuredLines, int startLine})>
scanFunctionSizesFromSourceForTest(String source) {
  final parsed = parseString(content: source, path: 'test.dart');
  final unit = parsed.unit;
  final sourceLines = const LineSplitter().convert(source);
  final lineInfo = unit.lineInfo;
  final out = <({String symbol, int measuredLines, int startLine})>[];

  void add(AstNode node, String symbol) {
    final start = lineInfo.getLocation(node.offset).lineNumber;
    final end = lineInfo.getLocation(node.end).lineNumber;
    out.add((
      symbol: symbol,
      measuredLines: _countMeasuredLines(sourceLines, start, end),
      startLine: start,
    ));
  }

  for (final decl in unit.declarations) {
    if (decl is FunctionDeclaration) {
      add(decl, decl.name.lexeme);
    } else if (decl is ClassDeclaration) {
      for (final member in decl.members) {
        if (member is MethodDeclaration) {
          add(member, '${decl.name.lexeme}.${member.name.lexeme}');
        }
      }
    }
  }
  return out;
}

final class _NestedLocalFunctionCollector extends RecursiveAstVisitor<void> {
  _NestedLocalFunctionCollector({required this.onLocalFunction});

  final void Function(FunctionDeclaration node) onLocalFunction;

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    onLocalFunction(node);
    super.visitFunctionDeclaration(node);
  }
}

void main() {
  exit(runCheckFunctionSize(Directory.current.path));
}
