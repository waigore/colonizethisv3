import 'dart:developer' as developer;

/// Flutter DevTools timeline markers for new-game → game-screen startup.
/// Names are prefixed with [kAppPerfTimelinePrefix] for filtering (GitHub #1710,
/// SPEC/program/flutter-performance-tracing.md).
const String kAppPerfTimelinePrefix = 'CtAppPerf';

void ctAppPerfInstant(String name) {
  developer.Timeline.instantSync('$kAppPerfTimelinePrefix.$name');
}

T ctAppPerfSync<T>(String name, T Function() action) {
  return developer.Timeline.timeSync('$kAppPerfTimelinePrefix.$name', action);
}
