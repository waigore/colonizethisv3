/// Compile-time flag for local debug console UI.
/// Pass `--dart-define=CT_DEBUG_CONSOLE=true` to enable in-game debug console.
const bool kCtDebugConsoleEnabled = bool.fromEnvironment(
  'CT_DEBUG_CONSOLE',
  defaultValue: false,
);

/// Optional compile-time override for JSON turn trace exports.
/// Pass `--dart-define=CT_TURN_TRACE_DIR=/absolute/or/relative/path`.
const String kCtTurnTraceDirectory = String.fromEnvironment(
  'CT_TURN_TRACE_DIR',
  defaultValue: 'tmp',
);
