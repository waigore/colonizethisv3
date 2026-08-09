import 'dart:io';

import 'check_ai_no_part_directives.dart';

/// CLI entry for `repo.ai_contracts_no_part_directives` (Refs #4084).
/// Reuses the parameterized scanner in [check_ai_no_part_directives.dart].
void main() {
  exit(runCheckAiContractsNoPartDirectives(Directory.current.path));
}
