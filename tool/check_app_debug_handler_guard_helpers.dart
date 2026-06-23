import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

/// Canonical guard message fragments that must originate from the shared helpers
/// in `debug_command_helpers.dart`, never inline in individual debug handlers.
///
/// Re-introducing any of these as an inline string literal in an
/// `app_event_handler_debug_*.dart` handler reintroduces the duplication that
/// #3655 removed. Example detected violation: a handler that inlines
/// `'Debug spawn ignored: no active game.'` instead of calling
/// `debugNoActiveGame(...)`.
const _bannedGuardFragments = <String>[
  'no active game.',
  'human Orders phase.',
  'credited amount must be >= 1.',
  'count must be >= 1.',
  'unknown player ',
  'is not human.',
  'has no capital province.',
];

int runCheckAppDebugHandlerGuardHelpers(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final servicesDir = Directory(
    p.join(repoRoot, 'app', 'lib', 'core', 'services'),
  );
  if (!servicesDir.existsSync()) {
    logE(
      'check_app_debug_handler_guard_helpers: app/lib/core/services not found.',
    );
    return 1;
  }

  final handlerFiles =
      servicesDir
          .listSync(recursive: false, followLinks: false)
          .whereType<File>()
          .where(
            (file) =>
                p.basename(file.path).startsWith('app_event_handler_debug_') &&
                file.path.endsWith('.dart'),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  final violations = <String>[];
  for (final file in handlerFiles) {
    final relativePath = p.relative(file.path, from: repoRoot);
    final unit = parseString(
      content: file.readAsStringSync(),
      path: relativePath,
    ).unit;
    final collector = _GuardLiteralCollector();
    unit.accept(collector);
    for (final literal in collector.literals) {
      for (final fragment in _bannedGuardFragments) {
        if (literal.contains(fragment)) {
          violations.add(
            '$relativePath inlines guard string "$fragment"; use the shared '
            'helpers in debug_command_helpers.dart (e.g. debugNoActiveGame, '
            'debugUnknownPlayer, debugOrdersPhaseRejected) instead',
          );
        }
      }
    }
  }

  if (violations.isEmpty) {
    logI('check_app_debug_handler_guard_helpers: no violations found.');
    return 0;
  }
  logE(
    'check_app_debug_handler_guard_helpers: ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

class _GuardLiteralCollector extends RecursiveAstVisitor<void> {
  final List<String> literals = <String>[];

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    literals.add(node.value);
    super.visitSimpleStringLiteral(node);
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    literals.add(node.value);
    super.visitInterpolationString(node);
  }
}

void main() {
  exit(runCheckAppDebugHandlerGuardHelpers(Directory.current.path));
}
