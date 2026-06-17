import 'dart:io';

import 'package:path/path.dart' as p;

/// Orders module whose snapshot clones must delegate to canonical helpers
/// instead of inlining raw `Map<...>.from(...)` clones (Refs #3404):
/// - stockpile-quantities clones use `Stockpile.copyQuantities()` rather than
///   `Map<String, int>.from(<stockpile>.quantities)`.
/// - unit-by-id clones use `copyUnitsById(...)` rather than
///   `Map<String, Unit>.from(...)`.
const _ordersLibDir = 'packages/colonizethis_orders/lib/src/orders';

const _orderSuggestionContextRelative =
    'packages/colonizethis_orders/lib/src/orders/order_suggestion_context.dart';

const _statefulValidatorRelative =
    'packages/colonizethis_orders/lib/src/orders/validators/stateful_validator.dart';

/// Matches a raw clone of a stockpile quantities map, e.g.
/// `Map<String, int>.from(snap.stockpile.quantities)`.
final RegExp _rawQuantitiesClonePattern = RegExp(
  r'Map<\s*String\s*,\s*int\s*>\.from\([^)]*\.quantities\)',
);

/// Matches a raw clone of a unit-by-id map, e.g.
/// `Map<String, Unit>.from(work.oldUnitsById)`. The canonical
/// `copyUnitsById(...)` helper uses a spread literal, so it does not match.
final RegExp _rawUnitsClonePattern = RegExp(
  r'Map<\s*String\s*,\s*Unit\s*>\.from\(',
);

/// True when [line] is a pure comment line (`//`, `///`, or a `*` doc/block
/// continuation), so a pattern mentioned in prose is not flagged.
bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckOrdersDedupMapClones(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final dir = Directory(p.join(root, _ordersLibDir));
  if (!dir.existsSync()) {
    logI('Orders dedup map-clone check skipped (orders lib dir absent).');
    return 0;
  }

  final violations = <OrdersDedupMapCloneViolation>[];
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    if (entity.path.endsWith('.g.dart')) continue;
    final relativePath = p.relative(entity.path, from: root);
    final source = entity.readAsStringSync();
    violations.addAll(
      findOrdersDedupMapCloneViolations(
        relativePath: relativePath,
        source: source,
      ),
    );
    violations.addAll(
      findDuplicateWithProjectedEconomyViolations(
        relativePath: relativePath,
        source: source,
      ),
    );
    violations.addAll(
      findOrderAcceptedProbeDuplicateViolations(
        relativePath: relativePath,
        source: source,
      ),
    );
    violations.addAll(
      findDuplicateWorkVisibilityHelperViolations(
        relativePath: relativePath,
        source: source,
      ),
    );
  }

  if (violations.isEmpty) {
    logI('Orders dedup map-clone check passed.');
    return 0;
  }

  logE(
    'ERROR: Found orders deduplication regressions in the orders module.',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckOrdersDedupMapClones(Directory.current.path));
}

List<OrdersDedupMapCloneViolation> findOrdersDedupMapCloneViolations({
  required String relativePath,
  required String source,
}) {
  final lines = source.split('\n');
  final violations = <OrdersDedupMapCloneViolation>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (_isCommentLine(line)) continue;
    if (_rawQuantitiesClonePattern.hasMatch(line)) {
      violations.add(
        OrdersDedupMapCloneViolation(
          path: relativePath,
          line: i + 1,
          message:
              'Raw stockpile quantities clone detected; call '
              'Stockpile.copyQuantities() instead.',
        ),
      );
    }
    if (_rawUnitsClonePattern.hasMatch(line)) {
      violations.add(
        OrdersDedupMapCloneViolation(
          path: relativePath,
          line: i + 1,
          message:
              'Raw unit-by-id map clone detected; call copyUnitsById(...) '
              'instead.',
        ),
      );
    }
  }
  return violations;
}

/// Flags subclass [withProjectedEconomy] constructors that do not delegate to
/// [StatefulValidator.withProjectedEconomy] (Refs #3500).
List<OrdersDedupMapCloneViolation> findDuplicateWithProjectedEconomyViolations({
  required String relativePath,
  required String source,
}) {
  if (relativePath == _statefulValidatorRelative) return const [];
  if (!relativePath.contains('/validators/')) return const [];
  if (!source.contains('.withProjectedEconomy(')) return const [];

  final violations = <OrdersDedupMapCloneViolation>[];
  final lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (_isCommentLine(line)) continue;
    if (!line.contains('.withProjectedEconomy(')) continue;
    final windowEnd = (i + 15).clamp(0, lines.length);
    final window = lines.sublist(i, windowEnd).join('\n');
    if (!window.contains('super.withProjectedEconomy(')) {
      violations.add(
        OrdersDedupMapCloneViolation(
          path: relativePath,
          line: i + 1,
          message:
              'withProjectedEconomy constructor must delegate to '
              'StatefulValidator.withProjectedEconomy.',
        ),
      );
    }
  }
  return violations;
}

/// Flags [is*OrderAccepted] wrappers that re-inline
/// [incrementalValidatorForCandidateProbe] instead of [_probeOrderAccepted].
List<OrdersDedupMapCloneViolation> findOrderAcceptedProbeDuplicateViolations({
  required String relativePath,
  required String source,
}) {
  if (relativePath != _orderSuggestionContextRelative) return const [];
  final violations = <OrdersDedupMapCloneViolation>[];
  final fnPattern = RegExp(r'^bool\s+is\w+OrderAccepted\(');
  final lines = source.split('\n');
  var inCandidateFn = false;
  var fnStartLine = 0;
  var braceDepth = 0;
  final fnBody = <String>[];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (!inCandidateFn && fnPattern.hasMatch(line.trimLeft())) {
      inCandidateFn = true;
      fnStartLine = i + 1;
      braceDepth = 0;
      fnBody.clear();
    }
    if (!inCandidateFn) continue;

    fnBody.add(line);
    braceDepth += '{'.allMatches(line).length;
    braceDepth -= '}'.allMatches(line).length;
    if (braceDepth <= 0 && fnBody.length > 1) {
      final body = fnBody.join('\n');
      if (body.contains('incrementalValidatorForCandidateProbe(')) {
        violations.add(
          OrdersDedupMapCloneViolation(
            path: relativePath,
            line: fnStartLine,
            message:
                'is*OrderAccepted wrappers must delegate to _probeOrderAccepted '
                'instead of inlining incrementalValidatorForCandidateProbe.',
          ),
        );
      }
      inCandidateFn = false;
    }
  }
  return violations;
}

/// Forbids reintroducing the deleted duplicate visibility helper (Refs #3500).
List<OrdersDedupMapCloneViolation> findDuplicateWorkVisibilityHelperViolations({
  required String relativePath,
  required String source,
}) {
  if (!relativePath.contains('order_visibility.dart')) return const [];
  if (!source.contains('_workVisFoggedOrBetterProvince')) return const [];
  final line = source
          .split('\n')
          .indexWhere((l) => l.contains('_workVisFoggedOrBetterProvince')) +
      1;
  return [
    OrdersDedupMapCloneViolation(
      path: relativePath,
      line: line,
      message:
          '_workVisFoggedOrBetterProvince duplicates _workVisFoggedProvince; '
          'reuse the canonical helper.',
    ),
  ];
}

/// Inline `relation?.atWar` checks must use shared diplomatic sub-validator
/// helpers (Refs #3500).
List<OrdersDedupMapCloneViolation> findInlinedDiplomaticRelationGuardViolations({
  required String relativePath,
  required String source,
}) {
  final violations = <OrdersDedupMapCloneViolation>[];
  final lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (_isCommentLine(line)) continue;
    if (line.contains('relation?.atWar')) {
      violations.add(
        OrdersDedupMapCloneViolation(
          path: relativePath,
          line: i + 1,
          message:
              'Use rejectDiplomaticSubIfAtWar / rejectDiplomaticSubIfAtPeace '
              'from diplomatic_sub_validator.dart instead of inline atWar checks.',
        ),
      );
    }
  }
  return violations;
}

/// Inline `if (!isGreatPower(` rejection guards must use
/// [rejectIfNotGreatPowerTarget] (Refs #3500).
List<OrdersDedupMapCloneViolation> findInlinedGreatPowerGuardViolations({
  required String relativePath,
  required String source,
}) {
  final violations = <OrdersDedupMapCloneViolation>[];
  final lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (_isCommentLine(line)) continue;
    if (line.contains('if (!isGreatPower(')) {
      violations.add(
        OrdersDedupMapCloneViolation(
          path: relativePath,
          line: i + 1,
          message:
              'Use rejectIfNotGreatPowerTarget from diplomatic_sub_validator.dart '
              'instead of inlining Great Power rejection guards.',
        ),
      );
    }
  }
  return violations;
}

class OrdersDedupMapCloneViolation {
  const OrdersDedupMapCloneViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
