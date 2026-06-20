import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'ct_repo_lint_scan_contract.dart';
import 'disallowed_ast_pattern_rules.dart';

export 'disallowed_ast_pattern_rules.dart';

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

  final allRules = parseDisallowedAstRulesFromYaml(
    loadYaml(configFile.readAsStringSync()),
  );
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
  final parsed = repoLintParseIncrementalRelativeDartPathsFromArgs(args);
  if (parsed.missingValueError) {
    stderr.writeln(
      'check_disallowed_ast_patterns: --files requires a comma-separated list',
    );
    exit(2);
  }
  exit(
    runCheckDisallowedAstPatterns(
      Directory.current.path,
      incrementalRelativeDartPaths: parsed.paths,
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
  if (repoLintPathShouldSkipAstRuleFile(relativePath)) {
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
      if (_fileIgnoresRule(content, relativePath, rule)) {
        continue;
      }
      if (_isSuppressedAtLine(content, relativePath, i + 1, rule)) {
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
    parseDisallowedAstRulesFromYaml(loadYaml(yamlText));

bool _fileIgnoresRule(
  String source,
  String _relativePath,
  DisallowedPatternRule rule,
) {
  return source.contains('ignore_for_file: disallowed_ast_${rule.id}');
}

bool _lineSuppressesRule(
  String line,
  String _relativePath,
  DisallowedPatternRule rule,
) {
  return line.contains('ignore: disallowed_ast_${rule.id}');
}

bool _isSuppressedAtLine(
  String source,
  String relativePath,
  int lineNumber1Based,
  DisallowedPatternRule rule,
) {
  final lines = const LineSplitter().convert(source);
  final idx = lineNumber1Based - 1;
  if (idx < 0 || idx >= lines.length) {
    return false;
  }
  if (_lineSuppressesRule(lines[idx], relativePath, rule)) {
    return true;
  }
  if (idx > 0 && _lineSuppressesRule(lines[idx - 1], relativePath, rule)) {
    return true;
  }
  return false;
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

/// True when [node] is a `.where(...)` invocation whose receiver chain is
/// `<expr>.where(...).toList()` (i.e. a `.where(...).toList().where(...)`
/// chain), allocating an intermediate `List` before the next filter.
bool _isRedundantWhereToListWhereChainPattern(MethodInvocation node) {
  if (node.methodName.name != 'where') {
    return false;
  }
  if (node.argumentList.arguments.length != 1) {
    return false;
  }
  final outerTarget = node.target;
  if (outerTarget is! MethodInvocation) {
    return false;
  }
  if (outerTarget.methodName.name != 'toList') {
    return false;
  }
  if (outerTarget.argumentList.arguments.isNotEmpty) {
    return false;
  }
  final innerTarget = outerTarget.target;
  if (innerTarget is! MethodInvocation) {
    return false;
  }
  if (innerTarget.methodName.name != 'where') {
    return false;
  }
  if (innerTarget.argumentList.arguments.length != 1) {
    return false;
  }
  return true;
}

bool _pathUnderAnyPrefix(String relativePath, List<String> prefixes) {
  if (prefixes.isEmpty) {
    return false;
  }
  final slashPath = relativePath.replaceAll('\\', '/');
  return prefixes.any((prefix) => slashPath.startsWith(prefix));
}

bool _isLinearCollectionWhereFirstOrNullPattern(
  PropertyAccess node,
  DisallowedPatternRule rule,
  String relativePath,
) {
  if (!_pathUnderAnyPrefix(relativePath, rule.linearCollectionPathPrefixes)) {
    return false;
  }
  if (rule.linearCollectionNames.isEmpty) {
    return false;
  }
  if (node.propertyName.name != 'firstOrNull') {
    return false;
  }
  final whereTarget = node.target;
  if (whereTarget is! MethodInvocation) {
    return false;
  }
  if (whereTarget.methodName.name != 'where') {
    return false;
  }
  if (whereTarget.argumentList.arguments.length != 1) {
    return false;
  }
  final collectionTarget = whereTarget.target;
  if (collectionTarget == null) {
    return false;
  }
  return _expressionEndsInNamedCollection(
    collectionTarget,
    rule.linearCollectionNames,
  );
}

bool _expressionEndsInNamedCollection(
  Expression target,
  Set<String> collectionNames,
) {
  final expr = _unwrapParenthesized(target);
  if (expr is PropertyAccess) {
    return collectionNames.contains(expr.propertyName.name);
  }
  if (expr is PrefixedIdentifier) {
    return collectionNames.contains(expr.identifier.name);
  }
  if (expr is SimpleIdentifier) {
    return collectionNames.contains(expr.name);
  }
  return false;
}

bool _isIncrementalValidatorForPlayerInLoopPattern(
  AstNode node,
  DisallowedPatternRule rule,
  String relativePath,
) {
  if (!_pathUnderAnyPrefix(relativePath, rule.linearCollectionPathPrefixes)) {
    return false;
  }
  if (node is InstanceCreationExpression) {
    final typeName = node.constructorName.type.name.lexeme;
    final constructorName = node.constructorName.name?.name;
    return typeName == 'IncrementalCandidateValidator' &&
        constructorName == 'forPlayer';
  }
  if (node is MethodInvocation) {
    if (node.target == null) {
      return node.methodName.name == 'buildIncrementalCandidateValidator';
    }
    final target = node.target;
    if (node.methodName.name == 'forPlayer') {
      if (target is SimpleIdentifier) {
        return target.name == 'IncrementalCandidateValidator';
      }
      if (target is PrefixedIdentifier) {
        return target.identifier.name == 'IncrementalCandidateValidator';
      }
    }
  }
  return false;
}

/// True when [node] is a `copyWith(...)` invocation that anchors a chain
/// **three or more** `copyWith` levels deep through the configured outer
/// named argument (default `worldState`). The detection is structural and
/// path-scoped to [DisallowedPatternRule.linearCollectionPathPrefixes]:
///
/// * Level 1: `<expr>.copyWith(<outerArgName>: <inner>)`.
/// * Level 2: `<inner>` is a `<expr2>.copyWith(<args2>)` invocation.
/// * Level 3: any named-argument value in `<args2>` is itself a
///   `<expr3>.copyWith(...)` invocation.
///
/// Two-level chains (`game.copyWith(worldState: world.copyWith(oldWorld: ow))`)
/// are **not** flagged so callers retain a thin escape hatch; deeper chains
/// must funnel through `updateWorldState` / `updateTurnState` helpers.
bool _isNestedWorldStateCopyWithChain(
  MethodInvocation node,
  DisallowedPatternRule rule,
  String relativePath,
) {
  if (!_pathUnderAnyPrefix(relativePath, rule.linearCollectionPathPrefixes)) {
    return false;
  }
  if (node.methodName.name != 'copyWith') {
    return false;
  }
  final outerArgumentName = rule.nestedCopyWithOuterArgumentName;
  if (outerArgumentName == null || outerArgumentName.isEmpty) {
    return false;
  }
  Expression? innerExpression;
  for (final arg in node.argumentList.arguments) {
    if (arg is! NamedExpression) {
      continue;
    }
    if (arg.name.label.name != outerArgumentName) {
      continue;
    }
    innerExpression = arg.expression;
    break;
  }
  if (innerExpression == null) {
    return false;
  }
  final inner = _unwrapParenthesized(innerExpression);
  if (inner is! MethodInvocation) {
    return false;
  }
  if (inner.methodName.name != 'copyWith') {
    return false;
  }
  for (final arg in inner.argumentList.arguments) {
    if (arg is! NamedExpression) {
      continue;
    }
    final value = _unwrapParenthesized(arg.expression);
    if (value is MethodInvocation && value.methodName.name == 'copyWith') {
      return true;
    }
  }
  return false;
}

bool _isSimpleReceiverRemoveAtZeroPattern(
  MethodInvocation node,
  DisallowedPatternRule rule,
  String relativePath,
) {
  final prefix = rule.removeAtZeroReceiverPathPrefix;
  final receiverName = rule.removeAtZeroReceiverIdentifier;
  if (prefix == null || receiverName == null) {
    return false;
  }
  final slashPath = relativePath.replaceAll('\\', '/');
  if (!slashPath.startsWith(prefix)) {
    return false;
  }
  if (node.methodName.name != 'removeAt') {
    return false;
  }
  final target = node.target;
  if (target is! SimpleIdentifier || target.name != receiverName) {
    return false;
  }
  final args = node.argumentList.arguments;
  if (args.length != 1) {
    return false;
  }
  final arg0 = args.first;
  if (arg0 is! IntegerLiteral) {
    return false;
  }
  return arg0.value == 0;
}

bool _isStaticMemberAccessPattern(
  PrefixedIdentifier node,
  DisallowedPatternRule rule,
  String relativePath,
) {
  final typeName = rule.staticMemberTypeName;
  final memberName = rule.staticMemberName;
  final prefix = rule.staticMemberPathPrefix;
  if (typeName == null || memberName == null || prefix == null) {
    return false;
  }
  final slashPath = relativePath.replaceAll('\\', '/');
  if (!slashPath.startsWith(prefix)) {
    return false;
  }
  return node.prefix.name == typeName && node.identifier.name == memberName;
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
  int _loopDepth = 0;

  void _recordIfAllowed(AstNode anchor, DisallowedPatternRule rule) {
    final line = lineInfo.getLocation(anchor.offset).lineNumber;
    if (_fileIgnoresRule(source, path, rule)) {
      return;
    }
    if (_isSuppressedAtLine(source, path, line, rule)) {
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

  void _recordIncrementalValidatorInLoopIfMatched(AstNode node) {
    if (_loopDepth == 0) {
      return;
    }
    for (final rule in rules) {
      if (rule.kind != DisallowedAstMatchKind.incrementalValidatorForPlayerInLoop) {
        continue;
      }
      if (_isIncrementalValidatorForPlayerInLoopPattern(node, rule, path)) {
        _recordIfAllowed(node, rule);
      }
    }
  }

  @override
  void visitForStatement(ForStatement node) {
    _loopDepth++;
    super.visitForStatement(node);
    _loopDepth--;
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _loopDepth++;
    super.visitWhileStatement(node);
    _loopDepth--;
  }

  @override
  void visitDoStatement(DoStatement node) {
    _loopDepth++;
    super.visitDoStatement(node);
    _loopDepth--;
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _recordIncrementalValidatorInLoopIfMatched(node);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _recordIncrementalValidatorInLoopIfMatched(node);
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
      } else if (rule.kind ==
              DisallowedAstMatchKind.simpleReceiverRemoveAtZero &&
          _isSimpleReceiverRemoveAtZeroPattern(node, rule, path)) {
        _recordIfAllowed(node, rule);
      } else if (rule.kind ==
              DisallowedAstMatchKind.redundantWhereToListWhereChain &&
          _isRedundantWhereToListWhereChainPattern(node)) {
        _recordIfAllowed(node, rule);
      } else if (rule.kind ==
              DisallowedAstMatchKind.nestedWorldStateCopyWith &&
          _isNestedWorldStateCopyWithChain(node, rule, path)) {
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
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    for (final rule in rules) {
      if (rule.kind != DisallowedAstMatchKind.staticMemberAccess) {
        continue;
      }
      if (_isStaticMemberAccessPattern(node, rule, path)) {
        _recordIfAllowed(node, rule);
      }
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    for (final rule in rules) {
      if (rule.kind !=
          DisallowedAstMatchKind.linearCollectionWhereFirstOrNull) {
        continue;
      }
      if (_isLinearCollectionWhereFirstOrNullPattern(node, rule, path)) {
        _recordIfAllowed(node, rule);
      }
    }
    super.visitPropertyAccess(node);
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
      if (rule.kind != DisallowedAstMatchKind.scopedPackageImportContract) {
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
