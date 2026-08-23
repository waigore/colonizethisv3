// Shared sync `debugPrint` capture for `E2ePerfLog` marker pins (#4598).
//
// `registerE2ePerfLogMarkersGuardGroup` lives in a sibling library, so the
// helper cannot stay private on the host test file.
library;

import 'package:flutter/foundation.dart';

/// Captures every `debugPrint` line emitted while [body] runs and restores
/// the original printer afterwards (defensive in `finally` so a thrown
/// expectation does not leak the override into later tests).
List<String> captureE2ePerfLogDebugPrints(void Function() body) {
  final captured = <String>[];
  final original = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    captured.add(message ?? '');
  };
  try {
    body();
  } finally {
    debugPrint = original;
  }
  return captured;
}
