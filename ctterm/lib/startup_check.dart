// Startup save check: testable logic for lock detection. SPEC/tui/ctterm.md §5.1.

import 'package:ctterm/save_service.dart';

/// Runs the save-service readiness check. Returns true if a lock was detected
/// ([StaleLockException]), so the app should show the lock-prompt screen.
/// Used by main() and by tests.
Future<bool> runStartupSaveCheck(
  String? dataDirOverride, {
  Future<void> Function(String?)? ensureReady,
}) async {
  ensureReady ??= ensureSaveServiceReady;
  try {
    await ensureReady!(dataDirOverride);
    return false;
  } on StaleLockException {
    return true;
  } catch (_) {
    return false;
  }
}
