import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/logic-package-barrel-contracts.md (Refs #4240 Slice A).
/// Rule `repo.app_narrow_logic_import`.
///
/// Forbids the broad `package:colonizethis_logic/colonizethis_logic.dart` barrel
/// under scoped app trees. Domain barrels and narrow logic contract entrypoints
/// remain allowed.
const forbiddenImportNeedle =
    'package:colonizethis_logic/colonizethis_logic.dart';

/// Scoped app trees migrated in wave 12 slice A (Refs #4240).
const scopedRelativeDirs = <String>[
  'app/lib/core/services',
  'app/lib/providers',
  'app/lib/features/game/screens/trade',
  'app/lib/features/game/screens/diplomacy',
  'app/lib/features/game/screens/production',
  'app/lib/features/game/widgets/units',
  'app/lib/features/game/widgets/diplomacy',
  'app/lib/features/game/widgets/production',
];

const coreServicesRelativeDir = 'app/lib/core/services';

/// Narrow logic contract libraries permitted in scoped trees.
const allowedLogicContractNeedles = <String>[
  'package:colonizethis_logic/ai_api.dart',
  'package:colonizethis_logic/order_suggestion_api.dart',
  'package:colonizethis_logic/industry_counsel_api.dart',
  'package:colonizethis_logic/debug_console_api.dart',
];

/// Domain package barrels permitted in scoped trees.
const allowedDomainBarrelNeedles = <String>[
  'package:colonizethis_world/colonizethis_world.dart',
  'package:colonizethis_orders/colonizethis_orders.dart',
  'package:colonizethis_turn/colonizethis_turn.dart',
  'package:colonizethis_combat/colonizethis_combat.dart',
  'package:colonizethis_diplomacy/colonizethis_diplomacy.dart',
  'package:colonizethis_economy/colonizethis_economy.dart',
  'package:colonizethis_setup/colonizethis_setup.dart',
];

List<String> scanAppNarrowLogicImportViolations(
  String repoRoot,
  List<String> relativeDirs,
) {
  final violations = <String>[];
  for (final relativeDir in relativeDirs) {
    final dir = Directory(p.join(repoRoot, relativeDir));
    if (!dir.existsSync()) {
      throw StateError('target not found: $relativeDir');
    }
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final relativePath = p.relative(entity.path, from: repoRoot);
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final trimmed = lines[i].trim();
        if (trimmed.startsWith('//')) {
          continue;
        }
        if (!trimmed.startsWith('import ')) {
          continue;
        }
        if (!trimmed.contains(forbiddenImportNeedle)) {
          continue;
        }
        violations.add(
          '$relativePath:${i + 1}: broad colonizethis_logic barrel import is '
          'disallowed; use a domain barrel (${allowedDomainBarrelNeedles.first}) '
          'or a narrow logic contract (${allowedLogicContractNeedles.first})',
        );
      }
    }
  }
  return violations;
}

int runCheckAppNarrowLogicImport(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  try {
    final violations = scanAppNarrowLogicImportViolations(
      repoRoot,
      scopedRelativeDirs,
    );
    if (violations.isEmpty) {
      logI(
        'check_app_narrow_logic_import: no broad logic barrel imports found.',
      );
      return 0;
    }

    logE(
      'check_app_narrow_logic_import: found ${violations.length} violation(s):',
    );
    for (final violation in violations) {
      logE(' - $violation');
    }
    return 1;
  } on StateError catch (e) {
    logE('check_app_narrow_logic_import: ${e.message}');
    return 1;
  }
}

void main() {
  exit(runCheckAppNarrowLogicImport(Directory.current.path));
}
