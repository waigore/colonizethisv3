import 'dart:io';

import 'check_app_narrow_logic_import.dart';

/// SPEC: SPEC/program/logic-package-barrel-contracts.md (Refs #4224 Slice C).
/// Rule `repo.app_core_services_narrow_logic_import`.
///
/// Legacy entrypoint retained for Slice C tests; scans only `app/lib/core/services`.
int runCheckAppCoreServicesNarrowLogicImport(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  try {
    final violations = scanAppNarrowLogicImportViolations(
      repoRoot,
      const [coreServicesRelativeDir],
    );
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
  } on StateError catch (e) {
    logE('check_app_core_services_narrow_logic_import: ${e.message}');
    return 1;
  }
}

void main() {
  exit(runCheckAppCoreServicesNarrowLogicImport(Directory.current.path));
}
