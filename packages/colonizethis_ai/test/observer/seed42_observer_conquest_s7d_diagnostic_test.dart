import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import 'support/s7d/run_seed42_s7d_diagnostic_campaign.dart';

/// Seed-42 turn-100 EXPAND-arm S7-D diagnostic (Refs #2847 / #3967 / #3977).
///
/// Historical findings live under `support/s7d/` (barrel
/// `s7d_diagnostic_findings.dart` + topic modules). Probe helpers and the
/// campaign runner live under `support/s7d/` as well. This file is
/// orchestration-only: test registration + harness invocation.
///
/// Skip: long-running (~4 min). Re-run with `dart test --run-skipped`.

void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  test(
    'seed 42 turn 100 S7-D diagnostic: per-GP EXPAND arm decision trace',
    runSeed42S7dDiagnosticCampaign,
    skip:
        'Refs #2847 S7-D: long-running (~4 min) per-GP EXPAND-arm '
        'diagnostic. Captured findings live in '
        'support/s7d/s7d_diagnostic_findings.dart and the issue S7-D '
        'note. Re-run with `dart test --run-skipped` when the '
        'diagnostic surface shifts after a tuning slice lands.',
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
