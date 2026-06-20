import 'dart:io';

import 'package:path/path.dart' as p;

import 'check_orders_dedup_map_clones.dart';

const _diplomaticValidatorsDir =
    'packages/colonizethis_orders/lib/src/orders/validators/diplomatic';

const _diplomaticSubValidatorRelative =
    'packages/colonizethis_orders/lib/src/orders/validators/diplomatic/diplomatic_sub_validator.dart';

/// Ensures per-type diplomatic sub-validators reuse shared helpers from
/// [diplomatic_sub_validator.dart] instead of inlining relation/amount/stage
/// checks (Refs #3500).
int runCheckOrdersDedupDiplomaticHelpers(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final diplomaticDir = Directory(p.join(root, _diplomaticValidatorsDir));
  if (!diplomaticDir.existsSync()) {
    logI('Orders dedup diplomatic-helpers check skipped (dir absent).');
    return 0;
  }

  final violations = <OrdersDedupMapCloneViolation>[];
  for (final entity in diplomaticDir.listSync(recursive: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final relativePath = p.relative(entity.path, from: root);
    if (relativePath == _diplomaticSubValidatorRelative) continue;
    final source = entity.readAsStringSync();
    violations.addAll(
      findInlinedDiplomaticRelationGuardViolations(
        relativePath: relativePath,
        source: source,
      ),
    );
    violations.addAll(
      findInlinedGreatPowerGuardViolations(
        relativePath: relativePath,
        source: source,
      ),
    );
  }

  if (violations.isEmpty) {
    logI('Orders dedup diplomatic-helpers check passed.');
    return 0;
  }

  logE(
    'ERROR: Found diplomatic sub-validator deduplication regressions.',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckOrdersDedupDiplomaticHelpers(Directory.current.path));
}
