/// Compile-time gate aligned with the Flutter app (`app/lib/config/ct_debug_console.dart`).
///
/// When true, ctdev enables merged turn-trace file export for [SimGameController]
/// (`turnTraceEnabled`), matching SPEC/program #2498 / `run_observer_game-tool.md`.
const bool kCtDebugConsoleEnabled = bool.fromEnvironment(
  'CT_DEBUG_CONSOLE',
  defaultValue: false,
);
