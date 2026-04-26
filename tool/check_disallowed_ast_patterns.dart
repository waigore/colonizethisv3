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
  Set<String>? enabledRuleIds,
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

  final allRules = _loadRules(configFile.readAsStringSync());
  final rules = enabledRuleIds == null
      ? allRules
      : allRules.where((rule) => enabledRuleIds.contains(rule.id)).toList();
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
          functionName: null,
          maxBodyLineSpan: null,
          requireWidgetClassExtends: false,
          argumentIndex: null,
          invocationMethodNames: const {},
          allowedRelativePaths: const {},
          scopedRelativePathPrefixes: const {},
          packageName: null,
          allowedPackageImports: const {},
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
          functionName: null,
          maxBodyLineSpan: null,
          requireWidgetClassExtends: false,
          argumentIndex: null,
          invocationMethodNames: const {},
          allowedRelativePaths: const {},
          scopedRelativePathPrefixes: const {},
          packageName: null,
          allowedPackageImports: const {},
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
          functionName: null,
          maxBodyLineSpan: null,
          requireWidgetClassExtends: false,
          argumentIndex: null,
          invocationMethodNames: const {},
          allowedRelativePaths: const {},
          scopedRelativePathPrefixes: const {},
          packageName: null,
          allowedPackageImports: const {},
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
          functionName: null,
          maxBodyLineSpan: null,
          requireWidgetClassExtends: false,
          argumentIndex: null,
          invocationMethodNames: const {},
          allowedRelativePaths: const {},
          scopedRelativePathPrefixes: const {},
          packageName: null,
          allowedPackageImports: const {},
        ),
      );
    } else if (kind == 'method_body_line_span') {
      final functionName = match['function_name']?.toString();
      final maxBodyLineSpan = int.tryParse(
        match['max_body_line_span']?.toString() ?? '',
      );
      final requireWidgetClassExtends =
          match['require_widget_class_extends'] == true;
      if (functionName == null ||
          functionName.isEmpty ||
          maxBodyLineSpan == null ||
          maxBodyLineSpan < 1) {
        continue;
      }
      out.add(
        DisallowedPatternRule(
          id: id,
          message: message,
          kind: DisallowedAstMatchKind.methodBodyLineSpan,
          cascadedMethodNames: const {},
          commentSubstring: null,
          rawNamedTypeNames: const {},
          functionName: functionName,
          maxBodyLineSpan: maxBodyLineSpan,
          requireWidgetClassExtends: requireWidgetClassExtends,
          argumentIndex: null,
          invocationMethodNames: const {},
          allowedRelativePaths: const {},
          scopedRelativePathPrefixes: const {},
          packageName: null,
          allowedPackageImports: const {},
        ),
      );
    } else if (kind == 'unprefixed_province_id_string_literal_argument') {
      final namesNode = match['method_names'];
      final argumentIndex = int.tryParse(
        match['argument_index']?.toString() ?? '',
      );
      if (namesNode is! YamlList ||
          argumentIndex == null ||
          argumentIndex < 0) {
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
          kind:
              DisallowedAstMatchKind.unprefixedProvinceIdStringLiteralArgument,
          cascadedMethodNames: const {},
          commentSubstring: null,
          rawNamedTypeNames: const {},
          functionName: null,
          maxBodyLineSpan: null,
          requireWidgetClassExtends: false,
          argumentIndex: argumentIndex,
          invocationMethodNames: names,
          allowedRelativePaths: const {},
          scopedRelativePathPrefixes: const {},
          packageName: null,
          allowedPackageImports: const {},
        ),
      );
    } else if (kind == 'sea_zone_local_id_extraction') {
      out.add(
        DisallowedPatternRule(
          id: id,
          message: message,
          kind: DisallowedAstMatchKind.seaZoneLocalIdExtraction,
          cascadedMethodNames: const {},
          commentSubstring: null,
          rawNamedTypeNames: const {},
          functionName: null,
          maxBodyLineSpan: null,
          requireWidgetClassExtends: false,
          argumentIndex: null,
          invocationMethodNames: const {},
          allowedRelativePaths: const {},
          scopedRelativePathPrefixes: const {},
          packageName: null,
          allowedPackageImports: const {},
        ),
      );
    } else if (kind == 'sea_zone_bucket_lookup_without_canonical_key') {
      out.add(
        DisallowedPatternRule(
          id: id,
          message: message,
          kind: DisallowedAstMatchKind.seaZoneBucketLookupWithoutCanonicalKey,
          cascadedMethodNames: const {},
          commentSubstring: null,
          rawNamedTypeNames: const {},
          functionName: null,
          maxBodyLineSpan: null,
          requireWidgetClassExtends: false,
          argumentIndex: null,
          invocationMethodNames: const {},
          allowedRelativePaths: const {},
          scopedRelativePathPrefixes: const {},
          packageName: null,
          allowedPackageImports: const {},
        ),
      );
    } else if (kind == 'province_local_segment_boundary_only') {
      out.add(
        DisallowedPatternRule(
          id: id,
          message: message,
          kind: DisallowedAstMatchKind.provinceLocalSegmentBoundaryOnly,
          cascadedMethodNames: const {},
          commentSubstring: null,
          rawNamedTypeNames: const {},
          functionName: null,
          maxBodyLineSpan: null,
          requireWidgetClassExtends: false,
          argumentIndex: null,
          invocationMethodNames: const {},
          allowedRelativePaths: const {},
          scopedRelativePathPrefixes: const {},
          packageName: null,
          allowedPackageImports: const {},
        ),
      );
    } else if (kind == 'package_import_allowlist') {
      final scopeNode = match['scoped_relative_path_prefixes'];
      final packageName = match['package_name']?.toString();
      final allowlistNode = match['allowed_imports'];
      if (scopeNode is! YamlList ||
          packageName == null ||
          packageName.isEmpty ||
          allowlistNode is! YamlList) {
        continue;
      }
      final scopedRelativePathPrefixes = <String>{};
      for (final scopeEntry in scopeNode.nodes) {
        final scope = scopeEntry.value?.toString();
        if (scope != null && scope.isNotEmpty) {
          scopedRelativePathPrefixes.add(scope);
        }
      }
      final allowedPackageImports = <String>{};
      for (final allowlistEntry in allowlistNode.nodes) {
        final importPath = allowlistEntry.value?.toString();
        if (importPath != null && importPath.isNotEmpty) {
          allowedPackageImports.add(importPath);
        }
      }
      if (scopedRelativePathPrefixes.isEmpty || allowedPackageImports.isEmpty) {
        continue;
      }
      out.add(
        DisallowedPatternRule(
          id: id,
          message: message,
          kind: DisallowedAstMatchKind.packageImportAllowlist,
          cascadedMethodNames: const {},
          commentSubstring: null,
          rawNamedTypeNames: const {},
          functionName: null,
          maxBodyLineSpan: null,
          requireWidgetClassExtends: false,
          argumentIndex: null,
          invocationMethodNames: const {},
          allowedRelativePaths: const {},
          scopedRelativePathPrefixes: scopedRelativePathPrefixes,
          packageName: packageName,
          allowedPackageImports: allowedPackageImports,
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
  methodBodyLineSpan,
  seaZoneLocalIdExtraction,
  seaZoneBucketLookupWithoutCanonicalKey,
  unprefixedProvinceIdStringLiteralArgument,
  provinceLocalSegmentBoundaryOnly,
  packageImportAllowlist,
}

class DisallowedPatternRule {
  const DisallowedPatternRule({
    required this.id,
    required this.message,
    required this.kind,
    required this.cascadedMethodNames,
    required this.commentSubstring,
    required this.rawNamedTypeNames,
    required this.functionName,
    required this.maxBodyLineSpan,
    required this.requireWidgetClassExtends,
    required this.argumentIndex,
    required this.invocationMethodNames,
    required this.allowedRelativePaths,
    required this.scopedRelativePathPrefixes,
    required this.packageName,
    required this.allowedPackageImports,
  });

  final String id;
  final String message;
  final DisallowedAstMatchKind kind;
  final Set<String> cascadedMethodNames;
  final String? commentSubstring;
  final Set<String> rawNamedTypeNames;
  final String? functionName;
  final int? maxBodyLineSpan;
  final bool requireWidgetClassExtends;
  final int? argumentIndex;
  final Set<String> invocationMethodNames;
  final Set<String> allowedRelativePaths;
  final Set<String> scopedRelativePathPrefixes;
  final String? packageName;
  final Set<String> allowedPackageImports;
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

bool _isProvinceLocalIdFromInvocation(MethodInvocation node) {
  final target = node.target;
  return target is SimpleIdentifier &&
      target.name == 'ProvinceId' &&
      node.methodName.name == 'localIdFrom' &&
      node.argumentList.arguments.length == 1;
}

bool _isProvinceLocalSegmentInvocation(MethodInvocation node) {
  final target = node.target;
  return target is SimpleIdentifier &&
      target.name == 'ProvinceId' &&
      node.methodName.name == 'localSegmentFromStoredGameState' &&
      node.argumentList.arguments.length == 1;
}

bool _expressionLooksSeaZoneRelated(Expression expression) {
  final text = expression.toSource().toLowerCase();
  return text.contains('seazone') ||
      text.contains('sea_zone') ||
      text.contains('seadest') ||
      text.contains('seadestination') ||
      text.contains('zoneid');
}

bool _isCanonicalSeaZoneBucketKeyExpression(Expression expression) {
  final e = _unwrapParenthesized(expression);
  if (e is MethodInvocation) {
    final method = e.methodName.name;
    return method == 'canonicalSeaZoneTileBucketKey' ||
        method == 'canonicalizeSeaZoneId';
  }
  if (e is SimpleIdentifier) {
    final name = e.name.toLowerCase();
    if ((name.contains('seazone') || name.contains('sea_zone')) &&
        (name.contains('bucket') || name.contains('key'))) {
      return true;
    }
  }
  if (e is StringLiteral) {
    return e.stringValue?.contains('|') == true;
  }
  return false;
}

bool _looksLikeTileKeysByRegionAndProvinceLookup(IndexExpression node) {
  final src = node.toSource();
  return src.contains('tileKeysByRegionAndProvince[');
}

bool _isUnprefixedProvinceIdStringLiteralInvocation(
  MethodInvocation node,
  DisallowedPatternRule rule,
) {
  if (!rule.invocationMethodNames.contains(node.methodName.name)) {
    return false;
  }
  final argumentIndex = rule.argumentIndex;
  if (argumentIndex == null) {
    return false;
  }
  final args = node.argumentList.arguments;
  if (argumentIndex >= args.length) {
    return false;
  }
  final arg = args[argumentIndex];
  if (arg is! StringLiteral) {
    return false;
  }
  final value = arg.stringValue;
  if (value == null) {
    return false;
  }
  return !value.contains('|');
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
      } else if (rule.kind == DisallowedAstMatchKind.seaZoneLocalIdExtraction &&
          _isProvinceLocalIdFromInvocation(node) &&
          _expressionLooksSeaZoneRelated(node.argumentList.arguments.single)) {
        _recordIfAllowed(node, rule);
      } else if (rule.kind ==
              DisallowedAstMatchKind.provinceLocalSegmentBoundaryOnly &&
          _isProvinceLocalSegmentInvocation(node)) {
        _recordIfAllowed(node, rule);
      }
      if (rule.kind ==
              DisallowedAstMatchKind
                  .unprefixedProvinceIdStringLiteralArgument &&
          _isUnprefixedProvinceIdStringLiteralInvocation(node, rule)) {
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
  void visitIndexExpression(IndexExpression node) {
    for (final rule in rules) {
      if (rule.kind !=
          DisallowedAstMatchKind.seaZoneBucketLookupWithoutCanonicalKey) {
        continue;
      }
      if (!_looksLikeTileKeysByRegionAndProvinceLookup(node)) {
        continue;
      }
      final index = node.index;
      if (!_expressionLooksSeaZoneRelated(index)) {
        continue;
      }
      if (_isCanonicalSeaZoneBucketKeyExpression(index)) {
        continue;
      }
      _recordIfAllowed(node, rule);
    }
    super.visitIndexExpression(node);
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

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    for (final rule in rules) {
      if (rule.kind != DisallowedAstMatchKind.methodBodyLineSpan) {
        continue;
      }
      if (node.name.lexeme != rule.functionName) {
        continue;
      }
      if (rule.requireWidgetClassExtends &&
          !_methodBelongsToWidgetClass(node)) {
        continue;
      }
      final bodyLineSpan = _lineSpan(node.body);
      final maxBodyLineSpan = rule.maxBodyLineSpan!;
      if (bodyLineSpan > maxBodyLineSpan) {
        _recordIfAllowed(node, rule);
      }
    }
    super.visitMethodDeclaration(node);
  }

  bool _methodBelongsToWidgetClass(MethodDeclaration node) {
    final parent = node.parent;
    if (parent is! ClassDeclaration) {
      return false;
    }
    final extendsClause = parent.extendsClause;
    if (extendsClause == null) {
      return false;
    }
    final superName = extendsClause.superclass.name2.lexeme;
    return superName == 'StatelessWidget' || superName == 'StatefulWidget';
  }

  int _lineSpan(AstNode node) {
    final start = lineInfo.getLocation(node.offset).lineNumber;
    final end = lineInfo.getLocation(node.end).lineNumber;
    return end - start + 1;
  }

  bool _pathIsInScopedPrefix(DisallowedPatternRule rule) {
    for (final prefix in rule.scopedRelativePathPrefixes) {
      if (path.startsWith(prefix)) {
        return true;
      }
    }
    return false;
  }

  @override
  void visitImportDirective(ImportDirective node) {
    for (final rule in rules) {
      if (rule.kind != DisallowedAstMatchKind.packageImportAllowlist) {
        continue;
      }
      if (!_pathIsInScopedPrefix(rule)) {
        continue;
      }
      final uri = node.uri.stringValue;
      final packageName = rule.packageName;
      if (uri == null || packageName == null || packageName.isEmpty) {
        continue;
      }
      final packagePrefix = 'package:$packageName/';
      if (!uri.startsWith(packagePrefix)) {
        continue;
      }
      if (rule.allowedPackageImports.contains(uri)) {
        continue;
      }
      _recordIfAllowed(node, rule);
    }
    super.visitImportDirective(node);
  }
}
