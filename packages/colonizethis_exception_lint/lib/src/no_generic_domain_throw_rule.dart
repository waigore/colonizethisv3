// custom_lint / analyzer still surface ErrorSeverity + ErrorReporter on these APIs.
// ignore_for_file: deprecated_member_use

import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'enforcement.dart';

/// Forbids `throw ArgumentError`, `throw Exception`, and `throw ArgumentError.value`
/// in domain runtime paths. SPEC/program/exception-enforcement.md
class NoGenericDomainThrowRule extends DartLintRule {
  NoGenericDomainThrowRule()
    : super(
        code: LintCode(
          name: 'no_generic_domain_throw',
          problemMessage:
              'Generic throws (ArgumentError / Exception) are disallowed in '
              'domain runtime code; use a domain-specific exception type. '
              'See SPEC/program/exception-enforcement.md.',
          errorSeverity: ErrorSeverity.ERROR,
        ),
      );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addThrowExpression((node) {
      if (!shouldEnforceDomainExceptions(resolver.path)) {
        return;
      }
      if (forbiddenGenericThrowLabel(node.expression) != null) {
        reporter.atNode(node, code);
      }
    });
  }
}
