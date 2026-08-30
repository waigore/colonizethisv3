import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import 'seed42_observer_colonial_c0_diagnostic_run.dart';

/// Seed-42 turn-150 COLONIAL-arm C0 diagnostic (Refs #2852).
///
/// Per #2852 § C0, this test mirrors the #2847 § S7-D pattern for the
/// COLONIAL phase. The campaign loop lives in
/// [runC0ColonialDiagnosticTest]. See that helper for refresh notes.
void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  runC0ColonialDiagnosticTest();
}
