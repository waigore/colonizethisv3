// custom_lint / analyzer still surface ErrorSeverity + ErrorReporter on these APIs.
// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// True for non-generated Dart under `colonizethis_logic/lib/`.
bool shouldEnforceNoRawHomeFleetId(String filePath) {
  final p = filePath.replaceAll(r'\', '/');
  if (!p.contains('colonizethis_logic/lib/')) {
    return false;
  }
  if (p.contains('/test/') || p.endsWith('_test.dart')) {
    return false;
  }
  if (p.endsWith('.g.dart') ||
      p.endsWith('.freezed.dart') ||
      p.endsWith('.mocks.dart')) {
    return false;
  }
  return true;
}

bool _isFleetPrefixInterpolation(StringInterpolation node) {
  final elements = node.elements;
  if (elements.isEmpty) return false;
  final first = elements.first;
  if (first is! InterpolationString) return false;
  if (!first.value.startsWith('fleet_')) return false;
  return elements.any((e) => e is InterpolationExpression);
}

bool _isCanonicalHomeFleetIdForDefinition(
  StringInterpolation node,
  String filePath,
) {
  final p = filePath.replaceAll(r'\', '/');
  if (!p.contains('colonizethis_logic/lib/src/world/naval.dart')) {
    return false;
  }
  AstNode? current = node.parent;
  while (current != null) {
    if (current is FunctionDeclaration) {
      return current.name.lexeme == 'homeFleetIdFor';
    }
    if (current is MethodDeclaration) {
      return current.name.lexeme == 'homeFleetIdFor';
    }
    current = current.parent;
  }
  return false;
}

/// Forbids `'fleet_$…'` string interpolation in `colonizethis_logic` lib code;
/// use `homeFleetIdFor` from `naval.dart` instead. The canonical
/// `homeFleetIdFor` implementation is exempt.
class NoRawHomeFleetIdRule extends DartLintRule {
  NoRawHomeFleetIdRule()
    : super(
        code: LintCode(
          name: 'no_raw_home_fleet_id',
          problemMessage:
              "Do not build Home Fleet ids with 'fleet_\$…' interpolation; "
              'use homeFleetIdFor(playerId) from naval.dart.',
          errorSeverity: ErrorSeverity.ERROR,
        ),
      );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addStringInterpolation((node) {
      if (!shouldEnforceNoRawHomeFleetId(resolver.path)) return;
      if (!_isFleetPrefixInterpolation(node)) return;
      if (_isCanonicalHomeFleetIdForDefinition(node, resolver.path)) return;
      reporter.atNode(node, code);
    });
  }
}
