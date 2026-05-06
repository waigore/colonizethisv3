/// Compile-time flag for local debug console UI.
/// Pass `--dart-define=CT_DEBUG_CONSOLE=true` to enable in-game debug console.
const bool kCtDebugConsoleEnabled = bool.fromEnvironment(
  'CT_DEBUG_CONSOLE',
  defaultValue: false,
);
