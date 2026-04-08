// Startup save check: testable logic for lock detection. SPEC/tui/ctterm.md §5.1.

import 'package:ctterm/save_service.dart';
import 'package:ctterm/package_logger.dart';

final _log = packageLogger();

/// Runs the save-service readiness check. Returns true if a lock was detected
/// ([StaleLockException]), so the app should show the lock-prompt screen.
/// Used by main() and by tests.
Future<bool> runStartupSaveCheck(
  String? dataDirOverride, {
  Future<void> Function(String?)? ensureReady,
}) async {
  final fn = ensureReady ?? ensureSaveServiceReady;
  try {
    await fn(dataDirOverride);
    return false;
  } on StaleLockException {
    return true;
  } on Exception catch (error, stackTrace) {
    _log.w(
      'startup_check: save readiness failed with non-lock exception',
      error: error,
      stackTrace: stackTrace,
    );
    return false;
  }
}
