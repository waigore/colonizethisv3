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
    p.join(
      repoRoot,
      'packages',
      'colonizethis_app_debug',
      'lib',
      'src',
    ),
  );
  if (!servicesDir.existsSync()) {
    logE(
      'check_app_debug_handler_guard_helpers: '
      'packages/colonizethis_app_debug/lib/src not found.',
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
    _collectSpawnRawCountCapViolations(
      unit: unit,
      relativePath: relativePath,
      violations: violations,
    );
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

void _collectSpawnRawCountCapViolations({
  required CompilationUnit unit,
  required String relativePath,
  required List<String> violations,
}) {
  final basename = p.basename(relativePath);
  if (!basename.startsWith('app_event_handler_debug_spawn_') ||
      !basename.endsWith('.dart')) {
    return;
  }
  final collector = _IntegerLiteralCollector();
  unit.accept(collector);
  for (final value in collector.values) {
    if (value != 25) continue;
    violations.add(
      '$relativePath contains raw integer literal 25; clamp spawn counts via '
      'boundDebugSpawnCount (kDebugSpawnCountCap) instead (Refs #4484)',
    );
  }
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

class _IntegerLiteralCollector extends RecursiveAstVisitor<void> {
  final List<int> values = <int>[];

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    final value = node.value;
    if (value != null) {
      values.add(value);
    }
    super.visitIntegerLiteral(node);
  }
}

void main() {
  exit(runCheckAppDebugHandlerGuardHelpers(Directory.current.path));
}
