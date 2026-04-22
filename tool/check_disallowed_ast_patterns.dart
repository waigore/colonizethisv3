import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'ct_repo_lint_scan_contract.dart';

/// PR-blocking structural AST checks driven by [tool/disallowed_ast_patterns.yaml].
///
/// SPEC: SPEC/program/disallowed-ast-patterns.md
///
/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckDisallowedAstPatterns(
  String repoRoot, {
  List<String>? incrementalRelativeDartPaths,
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final configFile = File(
    p.join(repoRoot, 'tool', 'disallowed_ast_patterns.yaml'),
  );
  if (!configFile.existsSync()) {
    logE('check_disallowed_ast_patterns: missing ${configFile.path}');
    return 1;
  }

  final rules = _loadRules(configFile.readAsStringSync());
  if (rules.isEmpty) {
    logE(
      'check_disallowed_ast_patterns: no rules in disallowed_ast_patterns.yaml',
    );
    return 1;
  }

  final dartFiles = collectRepoLintDomainDartFiles(repoRoot);
  final violations = <DisallowedAstViolation>[];
  final incrementalSet = incrementalRelativeDartPaths == null
      ? null
      : incrementalRelativeDartPaths.toSet();

  for (final file in dartFiles) {
    final relativePath = p.relative(file.path, from: repoRoot);
    if (incrementalSet != null && !incrementalSet.contains(relativePath)) {
      continue;
    }
    final content = file.readAsStringSync();
    violations.addAll(
      findDisallowedAstViolations(relativePath, content, rules),
    );
  }

  if (violations.isEmpty) {
    logI('check_disallowed_ast_patterns: no violations found.');
    return 0;
  }

  logE(
    'check_disallowed_ast_patterns: found ${violations.length} violation(s):',
  );
  for (final v in violations) {
    logE(' - ${v.path}:${v.line}: [${v.ruleId}] ${v.message}');
  }
  return 1;
}

void main(List<String> args) {
  List<String>? incrementalRelativeDartPaths;
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg.startsWith('--files=')) {
      incrementalRelativeDartPaths = repoLintSplitRelativeDartPathsArg(
        arg.substring('--files='.length),
      );
      continue;
    }
    if (arg == '--files') {
      if (i + 1 >= args.length) {
        stderr.writeln(
          'check_disallowed_ast_patterns: --files requires a comma-separated list',
        );
        exit(2);
      }
      incrementalRelativeDartPaths = repoLintSplitRelativeDartPathsArg(
        args[++i],
      );
      continue;
    }
  }
  exit(
    runCheckDisallowedAstPatterns(
      Directory.current.path,
      incrementalRelativeDartPaths: incrementalRelativeDartPaths,
    ),
  );
}

/// Exposed for unit tests (same behavior as production scan).
List<DisallowedAstViolation> findDisallowedAstViolations(
  String relativePath,
  String content,
  List<DisallowedPatternRule> rules,
) {
  if (rules.isEmpty) {
    return const [];
  }
  if (repoLintPathIsExcludedTestOrGeneratedDart(relativePath)) {
    return const [];
  }

  final parsed = parseString(
    content: content,
    path: relativePath,
    throwIfDiagnostics: false,
  );
  final visitor = _DisallowedAstVisitor(
    relativePath,
    content,
    parsed.lineInfo,
    rules,
  );
  parsed.unit.accept(visitor);
  final violations = <DisallowedAstViolation>[...visitor.violations];
  final lines = const LineSplitter().convert(content);
  for (final rule in rules) {
    if (rule.kind != DisallowedAstMatchKind.commentSubstring) {
      continue;
    }
    final needle = rule.commentSubstring;
    if (needle == null || needle.isEmpty) {
      continue;
    }
    for (var i = 0; i < lines.length; i++) {
      if (!lines[i].contains(needle)) {
        continue;
      }
      if (_fileIgnoresRule(content, rule.id)) {
        continue;
      }
      if (_isSuppressedAtLine(content, i + 1, rule.id)) {
        continue;
      }
      violations.add(
        DisallowedAstViolation(
          path: relativePath,
          line: i + 1,
          ruleId: rule.id,
          message: rule.message,
        ),
      );
    }
  }
  return violations;
}

List<DisallowedPatternRule> loadDisallowedAstRulesForTest(String yamlText) =>
    _parseRulesYaml(loadYaml(yamlText));

List<DisallowedPatternRule> _loadRules(String yamlText) =>
    _parseRulesYaml(loadYaml(yamlText));

List<DisallowedPatternRule> _parseRulesYaml(Object? yamlRoot) {
  if (yamlRoot is! YamlMap) {
    return const [];
  }
  final rulesNode = yamlRoot['rules'];
  if (rulesNode is! YamlList) {
    return const [];
  }
  final out = <DisallowedPatternRule>[];
  for (final entry in rulesNode.nodes) {
    final value = entry.value;
    if (value is! YamlMap) {
      continue;
    }
    final id = value['id']?.toString();
    final message = value['message']?.toString().trim();
    final match = value['match'];
    if (id == null || id.isEmpty || message == null || message.isEmpty) {
      continue;
    }
    if (match is! YamlMap) {
      continue;
    }
    final kind = match['kind']?.toString();
    if (kind == 'cascaded_method_invocation') {
      final namesNode = match['method_names'];
      if (namesNode is! YamlList) {
        continue;
      }
      final names = <String>{};
      for (final n in namesNode.nodes) {
        final s = n.value?.toString();
        if (s != null && s.isNotEmpty) {
          names.add(s);
        }
      }
      if (names.isEmpty) {
        continue;
      }
      out.add(
        DisallowedPatternRule(
          id: id,
          message: message,
          kind: DisallowedAstMatchKind.cascadedMethodInvocation,
          cascadedMethodNames: names,
          commentSubstring: null,
          rawNamedTypeNames: const {},
        ),
      );
    } else if (kind == 'stream_where_is_map_as') {
      out.add(
        DisallowedPatternRule(
          id: id,
          message: message,
          kind: DisallowedAstMatchKind.streamWhereIsMapAs,
          cascadedMethodNames: const {},
          commentSubstring: null,
          rawNamedTypeNames: const {},
        ),
      );
    } else if (kind == 'comment_substring') {
      final needle = match['contains']?.toString();
      if (needle == null || needle.isEmpty) {
        continue;
      }
      out.add(
        DisallowedPatternRule(
          id: id,
          message: message,
          kind: DisallowedAstMatchKind.commentSubstring,
          cascadedMethodNames: const {},
          commentSubstring: needle,
          rawNamedTypeNames: const {},
        ),
      );
    } else if (kind == 'raw_named_type') {
      final namesNode = match['type_names'];
      if (namesNode is! YamlList) {
        continue;
      }
      final names = <String>{};
      for (final n in namesNode.nodes) {
        final s = n.value?.toString();
        if (s != null && s.isNotEmpty) {
          names.add(s);
        }
      }
      if (names.isEmpty) {
        continue;
      }
      out.add(
        DisallowedPatternRule(
          id: id,
          message: message,
          kind: DisallowedAstMatchKind.rawNamedType,
          cascadedMethodNames: const {},
          commentSubstring: null,
          rawNamedTypeNames: names,
        ),
      );
    }
  }
  return out;
}

bool _fileIgnoresRule(String source, String ruleId) {
  return source.contains('ignore_for_file: disallowed_ast_$ruleId');
}

bool _lineSuppressesRule(String line, String ruleId) {
  return line.contains('ignore: disallowed_ast_$ruleId');
}

bool _isSuppressedAtLine(String source, int lineNumber1Based, String ruleId) {
  final lines = const LineSplitter().convert(source);
  final idx = lineNumber1Based - 1;
  if (idx < 0 || idx >= lines.length) {
    return false;
  }
  if (_lineSuppressesRule(lines[idx], ruleId)) {
    return true;
  }
  if (idx > 0 && _lineSuppressesRule(lines[idx - 1], ruleId)) {
    return true;
  }
  return false;
}

/// Kinds of structural matches defined in [tool/disallowed_ast_patterns.yaml].
enum DisallowedAstMatchKind {
  cascadedMethodInvocation,
  streamWhereIsMapAs,
  commentSubstring,
  rawNamedType,
}

class DisallowedPatternRule {
  const DisallowedPatternRule({
    required this.id,
    required this.message,
    required this.kind,
    required this.cascadedMethodNames,
    required this.commentSubstring,
    required this.rawNamedTypeNames,
  });

  final String id;
  final String message;
  final DisallowedAstMatchKind kind;
  final Set<String> cascadedMethodNames;
  final String? commentSubstring;
  final Set<String> rawNamedTypeNames;
}

class DisallowedAstViolation {
  const DisallowedAstViolation({
    required this.path,
    required this.line,
    required this.ruleId,
    required this.message,
  });

  final String path;
  final int line;
  final String ruleId;
  final String message;
}

Expression _unwrapParenthesized(Expression expr) {
  var e = expr;
  while (e is ParenthesizedExpression) {
    e = e.expression;
  }
  return e;
}

String? _singleFormalParameterId(FormalParameterList? list) {
  if (list == null || list.parameters.length != 1) {
    return null;
  }
  return _formalParameterId(list.parameters.first);
}

String? _formalParameterId(FormalParameter param) {
  if (param is SimpleFormalParameter) {
    return param.name?.lexeme;
  }
  if (param is DefaultFormalParameter) {
    return _formalParameterId(param.parameter);
  }
  return null;
}

Expression? _expressionFromFunctionBody(FunctionBody body) {
  if (body is ExpressionFunctionBody) {
    return body.expression;
  }
  if (body is BlockFunctionBody) {
    final stmts = body.block.statements;
    if (stmts.length != 1) {
      return null;
    }
    final first = stmts.first;
    if (first is! ReturnStatement) {
      return null;
    }
    return first.expression;
  }
  return null;
}

bool _whereCallbackIsParamIsTypeCheck(FunctionExpression fn) {
  final paramId = _singleFormalParameterId(fn.parameters);
  if (paramId == null) {
    return false;
  }
  final bodyExpr = _expressionFromFunctionBody(fn.body);
  if (bodyExpr == null) {
    return false;
  }
  final inner = _unwrapParenthesized(bodyExpr);
  if (inner is! IsExpression) {
    return false;
  }
  final left = _unwrapParenthesized(inner.expression);
  if (left is! SimpleIdentifier) {
    return false;
  }
  return left.name == paramId;
}

bool _mapCallbackIsParamAsCast(FunctionExpression fn) {
  final paramId = _singleFormalParameterId(fn.parameters);
  if (paramId == null) {
    return false;
  }
  final bodyExpr = _expressionFromFunctionBody(fn.body);
  if (bodyExpr == null) {
    return false;
  }
  final inner = _unwrapParenthesized(bodyExpr);
  if (inner is! AsExpression) {
    return false;
  }
  final subj = _unwrapParenthesized(inner.expression);
  if (subj is! SimpleIdentifier) {
    return false;
  }
  return subj.name == paramId;
}

bool _isRedundantWhereIsMapAsChain(MethodInvocation node) {
  if (node.methodName.name != 'map') {
    return false;
  }
  final target = node.target;
  if (target is! MethodInvocation) {
    return false;
  }
  if (target.methodName.name != 'where') {
    return false;
  }
  final whereArgs = target.argumentList.arguments;
  final mapArgs = node.argumentList.arguments;
  if (whereArgs.length != 1 || mapArgs.length != 1) {
    return false;
  }
  final whereArg = whereArgs.first;
  final mapArg = mapArgs.first;
  if (whereArg is! FunctionExpression || mapArg is! FunctionExpression) {
    return false;
  }
  return _whereCallbackIsParamIsTypeCheck(whereArg) &&
      _mapCallbackIsParamAsCast(mapArg);
}

class _DisallowedAstVisitor extends RecursiveAstVisitor<void> {
  _DisallowedAstVisitor(this.path, this.source, this.lineInfo, this.rules);

  final String path;
  final String source;
  final LineInfo lineInfo;
  final List<DisallowedPatternRule> rules;
  final List<DisallowedAstViolation> violations = [];

  void _recordIfAllowed(AstNode anchor, DisallowedPatternRule rule) {
    final line = lineInfo.getLocation(anchor.offset).lineNumber;
    if (_fileIgnoresRule(source, rule.id)) {
      return;
    }
    if (_isSuppressedAtLine(source, line, rule.id)) {
      return;
    }
    violations.add(
      DisallowedAstViolation(
        path: path,
        line: line,
        ruleId: rule.id,
        message: rule.message,
      ),
    );
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    for (final rule in rules) {
      if (rule.kind == DisallowedAstMatchKind.streamWhereIsMapAs &&
          _isRedundantWhereIsMapAsChain(node)) {
        _recordIfAllowed(node, rule);
      }
    }
    if (node.isCascaded) {
      final name = node.methodName.name;
      for (final rule in rules) {
        if (rule.kind != DisallowedAstMatchKind.cascadedMethodInvocation) {
          continue;
        }
        if (!rule.cascadedMethodNames.contains(name)) {
          continue;
        }
        _recordIfAllowed(node, rule);
      }
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitNamedType(NamedType node) {
    for (final rule in rules) {
      if (rule.kind != DisallowedAstMatchKind.rawNamedType) {
        continue;
      }
      if (node.typeArguments != null) {
        continue;
      }
      final name = node.name2.lexeme;
      if (!rule.rawNamedTypeNames.contains(name)) {
        continue;
      }
      _recordIfAllowed(node, rule);
    }
    super.visitNamedType(node);
  }
}
