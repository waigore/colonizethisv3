import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import 'seed42_observer_world_market_lock_recovery_diagnostic_run.dart';

/// Seed-42 Path F (World Market) lock-recovery diagnostic (Refs #2924).
///
/// Campaign loop lives in [runWorldMarketLockRecoveryDiagnosticTest].
void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  runWorldMarketLockRecoveryDiagnosticTest();
}
