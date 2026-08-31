import 'dart:developer' as developer;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, kIsWeb, kProfileMode, kReleaseMode,
        TargetPlatform;

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

/// Emits `ui_surface_open` for profile/release evidence capture (Refs #4687, #4688).
///
/// [debugPrint] reaches logcat on Android; [print] reaches `flutter drive` stdout.
void ctAppPerfLogUiSurfaceOpen(
  String surfaceId,
  int elapsedMs, {
  bool warm = false,
}) {
  if (!kProfileMode && !kReleaseMode) {
    return;
  }
  final host = ctAppPerfSurfaceOpenBindingHost();
  final warmSuffix = warm ? ' warm=1' : '';
  final line =
      'ui_surface_open surface=$surfaceId elapsed_ms=$elapsedMs '
      'budget_ms=$kUiSurfaceOpenBudgetMs host=$host$warmSuffix';
  debugPrint(line);
  // ignore: avoid_print — intentional profile evidence on binding hosts.
  print(line);
}

/// Binding-host label for profile/release `ui_surface_open` evidence (Refs #4687).
///
/// Values: `linux_desktop_profile`, `android_emulator_profile`, etc.
String ctAppPerfSurfaceOpenBindingHost() {
  if (kIsWeb) {
    return 'web_profile';
  }
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android_emulator_profile',
    TargetPlatform.iOS => 'ios_simulator_profile',
    TargetPlatform.linux => 'linux_desktop_profile',
    TargetPlatform.macOS => 'macos_desktop_profile',
    TargetPlatform.windows => 'windows_desktop_profile',
    TargetPlatform.fuchsia => 'fuchsia_profile',
  };
}
