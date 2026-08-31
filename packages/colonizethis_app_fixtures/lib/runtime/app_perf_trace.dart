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

/// Wall-clock segment for game-app UI surface open budgets (Refs #4687).
///
/// [surfaceId] matches the `CtAppPerf.<surfaceId>.*` marker family
/// (e.g. `development` → `development.interactiveReady`).
final Map<String, Stopwatch> _surfaceOpenSegments = <String, Stopwatch>{};

/// Starts (or restarts) the open segment for [surfaceId].
void ctAppPerfSurfaceOpenBegin(String surfaceId) {
  _surfaceOpenSegments[surfaceId] = Stopwatch()..start();
}

/// Elapsed wall-clock ms since [ctAppPerfSurfaceOpenBegin] for [surfaceId].
int? ctAppPerfSurfaceOpenElapsedMs(String surfaceId) {
  return _surfaceOpenSegments[surfaceId]?.elapsedMilliseconds;
}

/// Emits [surfaceId].interactiveReady and returns elapsed ms when tracked.
int? ctAppPerfSurfaceOpenInteractiveReady(String surfaceId) {
  final elapsedMs = ctAppPerfSurfaceOpenElapsedMs(surfaceId);
  ctAppPerfInstant('$surfaceId.interactiveReady');
  return elapsedMs;
}
