import 'dart:io';

import 'package:path/path.dart' as p;

import 'check_orders_dedup_map_clones.dart';

const _ordersLibDir = 'packages/colonizethis_orders/lib/src/orders';

/// Canonical ownership projection helper (Refs #4258 Slice B).
const _canonicalHelperRelative =
    'packages/colonizethis_orders/lib/src/orders/order_suggestion_pass_context.dart';

/// Manual dual-region province ownership scans must delegate to
/// [ownedProvinceIdsForPlayer] / [ProvinceOwnerCache].
final RegExp _oldWorldProvincesPattern = RegExp(r'oldWorld\.provinces');
final RegExp _newWorldProvincesPattern = RegExp(r'newWorld\.provinces');
final RegExp _ownerIdEqualityPattern = RegExp(r'ownerId\s*==');

bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

List<OrdersDedupMapCloneViolation> findOrdersOwnedProvinceProjectionViolations({
  required String relativePath,
  required String source,
}) {
  if (relativePath == _canonicalHelperRelative) return const [];
  if (!relativePath.startsWith('packages/colonizethis_orders/lib/')) {
    return const [];
  }

  final hasOwnerLoop =
      _ownerIdEqualityPattern.hasMatch(source) &&
      (_oldWorldProvincesPattern.hasMatch(source) ||
          _newWorldProvincesPattern.hasMatch(source));
  if (!hasOwnerLoop) return const [];

  final violations = <OrdersDedupMapCloneViolation>[];
  final lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (_isCommentLine(line)) continue;
    if (_oldWorldProvincesPattern.hasMatch(line) ||
        _newWorldProvincesPattern.hasMatch(line)) {
      violations.add(
        OrdersDedupMapCloneViolation(
          path: relativePath,
          line: i + 1,
          message:
              'Manual region province ownership scan; use ownedProvinceIdsForPlayer '
              'from order_suggestion_pass_context.dart.',
        ),
      );
    }
  }
  return violations;
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckOrdersOwnedProvinceProjection(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final dir = Directory(p.join(root, _ordersLibDir));
  if (!dir.existsSync()) {
    logI('Orders owned-province projection check skipped (orders lib dir absent).');
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
      findOrdersOwnedProvinceProjectionViolations(
        relativePath: relativePath,
        source: source,
      ),
    );
  }

  if (violations.isEmpty) {
    logI('Orders owned-province projection check passed.');
    return 0;
  }

  logE('ERROR: Found manual province ownership projection regressions.');
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckOrdersOwnedProvinceProjection(Directory.current.path));
}
