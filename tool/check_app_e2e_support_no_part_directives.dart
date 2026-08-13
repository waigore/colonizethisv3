import 'dart:io';

import 'check_ai_no_part_directives.dart';

/// CLI entry for `repo.app_e2e_support_no_part_directives` (Refs #4344).
/// Reuses the parameterized scanner in [check_ai_no_part_directives.dart]
/// with package-root prefix so both `lib/` and `test/` are covered.
void main() {
  exit(runCheckAppE2eSupportNoPartDirectives(Directory.current.path));
}
