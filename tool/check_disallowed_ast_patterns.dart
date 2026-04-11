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

  for (final file in dartFiles) {
    final relativePath = p.relative(file.path, from: repoRoot);
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

void main() {
  exit(runCheckDisallowedAstPatterns(Directory.current.path));
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
  return visitor.violations;
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
          cascadedMethodNames: names,
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

class DisallowedPatternRule {
  const DisallowedPatternRule({
    required this.id,
    required this.message,
    required this.cascadedMethodNames,
  });

  final String id;
  final String message;
  final Set<String> cascadedMethodNames;
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

class _DisallowedAstVisitor extends RecursiveAstVisitor<void> {
  _DisallowedAstVisitor(this.path, this.source, this.lineInfo, this.rules);

  final String path;
  final String source;
  final LineInfo lineInfo;
  final List<DisallowedPatternRule> rules;
  final List<DisallowedAstViolation> violations = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!node.isCascaded) {
      super.visitMethodInvocation(node);
      return;
    }
    final name = node.methodName.name;
    for (final rule in rules) {
      if (!rule.cascadedMethodNames.contains(name)) {
        continue;
      }
      final line = lineInfo.getLocation(node.offset).lineNumber;
      if (_fileIgnoresRule(source, rule.id)) {
        continue;
      }
      if (_isSuppressedAtLine(source, line, rule.id)) {
        continue;
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
    super.visitMethodInvocation(node);
  }
}
