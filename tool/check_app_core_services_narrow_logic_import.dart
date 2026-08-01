import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/logic-package-barrel-contracts.md (Refs #4224 Slice C).
/// Rule `repo.app_core_services_narrow_logic_import`.
///
/// Forbids the broad `package:colonizethis_logic/colonizethis_logic.dart` barrel
/// under `app/lib/core/services/**`. Domain barrels and narrow logic contract
/// entrypoints remain allowed.
const _servicesRelativeDir = 'app/lib/core/services';

const _forbiddenImportNeedle =
    'package:colonizethis_logic/colonizethis_logic.dart';

/// Narrow logic contract libraries permitted under core services.
const _allowedLogicContractNeedles = <String>[
  'package:colonizethis_logic/ai_api.dart',
  'package:colonizethis_logic/order_suggestion_api.dart',
  'package:colonizethis_logic/industry_counsel_api.dart',
  'package:colonizethis_logic/debug_console_api.dart',
];

/// Domain package barrels permitted under core services.
const _allowedDomainBarrelNeedles = <String>[
  'package:colonizethis_world/colonizethis_world.dart',
  'package:colonizethis_orders/colonizethis_orders.dart',
  'package:colonizethis_turn/colonizethis_turn.dart',
  'package:colonizethis_combat/colonizethis_combat.dart',
  'package:colonizethis_diplomacy/colonizethis_diplomacy.dart',
  'package:colonizethis_economy/colonizethis_economy.dart',
  'package:colonizethis_setup/colonizethis_setup.dart',
];

int runCheckAppCoreServicesNarrowLogicImport(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final servicesDir = Directory(p.join(repoRoot, _servicesRelativeDir));
  if (!servicesDir.existsSync()) {
    logE(
      'check_app_core_services_narrow_logic_import: target not found: '
      '$_servicesRelativeDir',
    );
    return 1;
  }

  final violations = <String>[];
  for (final entity in servicesDir.listSync(recursive: true)) {
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
      if (!trimmed.contains(_forbiddenImportNeedle)) {
        continue;
      }
      violations.add(
        '$relativePath:${i + 1}: broad colonizethis_logic barrel import is '
        'disallowed; use a domain barrel (${_allowedDomainBarrelNeedles.first}) '
        'or a narrow logic contract (${_allowedLogicContractNeedles.first})',
      );
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_app_core_services_narrow_logic_import: no broad logic barrel '
      'imports found.',
    );
    return 0;
  }

  logE(
    'check_app_core_services_narrow_logic_import: found '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAppCoreServicesNarrowLogicImport(Directory.current.path));
}
