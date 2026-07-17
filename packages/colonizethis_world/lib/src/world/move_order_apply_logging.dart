import 'package:colonizethis_world/src/logging.dart';
import 'package:logger/logger.dart';

/// Shared debug-gated ignore logging for army and civilian move apply paths.
///
/// Keeps ignore-reason message text at the call site so army vs civilian
/// wording stays distinct; only the [Level.debug] gate is shared.
/// SPEC/program/movement.md § Apply logging; Refs #4038.
void logMoveOrderIgnoredIfDebug(String message) {
  if (Level.debug.value >= Logger.level.value) {
    worldLog.d(message);
  }
}

/// Shared info-level apply summary when any order was applied or ignored.
///
/// Message text stays at the call site (army region vs civilian tile wording).
/// SPEC/program/movement.md § Apply logging; Refs #4038.
void logMoveOrderApplySummary({
  required String message,
  required int applied,
  required int ignored,
}) {
  if (applied + ignored > 0) {
    worldLog.i(message);
  }
}
