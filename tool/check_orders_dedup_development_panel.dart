import 'dart:io';

import 'package:path/path.dart' as p;

import 'check_orders_dedup_map_clones.dart';

const _ordersLibDir = 'packages/colonizethis_orders/lib/src/orders';

const _canonicalIdleCiviliansRelative =
    'packages/colonizethis_orders/lib/src/orders/development_panel/idle_civilians.dart';

const _canonicalImproveOrderingRelative =
    'packages/colonizethis_orders/lib/src/orders/development_panel/improve_tile_ordering.dart';

const _canonicalMaterialAffordanceRelative =
    'packages/colonizethis_orders/lib/src/orders/development_panel/material_affordance.dart';

/// Duplicate idle-scan bodies outside the canonical helper file.
final RegExp _idleBuilderScanBodyPattern = RegExp(
  r'if \(unit\.type != kUnitTypeBuilder\) continue;',
);

final RegExp _idleEngineerScanBodyPattern = RegExp(
  r'if \(unit\.type != kUnitTypeEngineer\) continue;',
);

/// Inline connected-first improve tile sort outside the ordering module.
final RegExp _inlineConnectedFirstSortPattern = RegExp(
  r'if \(aConnected != bConnected\)',
);

/// Inline pending-material stockpile projection outside material_affordance.
final RegExp _inlinePendingMaterialProjectionPattern = RegExp(
  r'_developmentPanelPendingMaterialWorkTargets',
);

bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

List<OrdersDedupMapCloneViolation> findDevelopmentPanelIdleScanViolations({
  required String relativePath,
  required String source,
}) {
  if (relativePath == _canonicalIdleCiviliansRelative) return const [];
  if (!relativePath.startsWith('packages/colonizethis_orders/lib/')) {
    return const [];
  }
  if (!relativePath.contains('development_panel')) return const [];

  final violations = <OrdersDedupMapCloneViolation>[];
  final lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (_isCommentLine(line)) continue;
    if (_idleBuilderScanBodyPattern.hasMatch(line) ||
        _idleEngineerScanBodyPattern.hasMatch(line)) {
      violations.add(
        OrdersDedupMapCloneViolation(
          path: relativePath,
          line: i + 1,
          message:
              'Duplicate idle civilian scan; use idleDevelopmentCiviliansForAssign '
              'from development_panel/idle_civilians.dart.',
        ),
      );
    }
  }
  return violations;
}

List<OrdersDedupMapCloneViolation>
findDevelopmentPanelImproveOrderingViolations({
  required String relativePath,
  required String source,
}) {
  if (relativePath == _canonicalImproveOrderingRelative) return const [];
  if (!relativePath.startsWith('packages/colonizethis_orders/lib/')) {
    return const [];
  }
  if (!relativePath.contains('development_panel')) return const [];

  final violations = <OrdersDedupMapCloneViolation>[];
  final lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (_isCommentLine(line)) continue;
    if (_inlineConnectedFirstSortPattern.hasMatch(line)) {
      violations.add(
        OrdersDedupMapCloneViolation(
          path: relativePath,
          line: i + 1,
          message:
              'Inline connected-first improve tile sort; use '
              'orderDevelopmentImproveTiles from development_panel/improve_tile_ordering.dart.',
        ),
      );
    }
  }
  return violations;
}

List<OrdersDedupMapCloneViolation>
findDevelopmentPanelMaterialAffordanceViolations({
  required String relativePath,
  required String source,
}) {
  if (relativePath == _canonicalMaterialAffordanceRelative) return const [];
  if (!relativePath.startsWith('packages/colonizethis_orders/lib/')) {
    return const [];
  }

  final violations = <OrdersDedupMapCloneViolation>[];
  final lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (_isCommentLine(line)) continue;
    if (_inlinePendingMaterialProjectionPattern.hasMatch(line)) {
      violations.add(
        OrdersDedupMapCloneViolation(
          path: relativePath,
          line: i + 1,
          message:
              'Inline pending-material projection; use '
              'effectiveStockpileAfterPendingDevelopmentMaterialWork from '
              'development_panel/material_affordance.dart.',
        ),
      );
    }
  }
  return violations;
}

int runCheckOrdersDedupDevelopmentPanel(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final dir = Directory(p.join(root, _ordersLibDir));
  if (!dir.existsSync()) {
    logI('Orders dedup development-panel check skipped (orders lib dir absent).');
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
      findDevelopmentPanelIdleScanViolations(
        relativePath: relativePath,
        source: source,
      ),
    );
    violations.addAll(
      findDevelopmentPanelImproveOrderingViolations(
        relativePath: relativePath,
        source: source,
      ),
    );
    violations.addAll(
      findDevelopmentPanelMaterialAffordanceViolations(
        relativePath: relativePath,
        source: source,
      ),
    );
  }

  if (violations.isEmpty) {
    logI('Orders dedup development-panel check passed.');
    return 0;
  }

  logE('ERROR: Found development-panel deduplication regressions.');
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckOrdersDedupDevelopmentPanel(Directory.current.path));
}
