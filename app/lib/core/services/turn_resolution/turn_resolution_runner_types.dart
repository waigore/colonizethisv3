import 'package:colonizethis_logic/colonizethis_logic.dart';

class TurnResolutionProgressEvent {
  const TurnResolutionProgressEvent({
    required this.sessionId,
    required this.phase,
    required this.marker,
  });

  final String sessionId;
  final String phase;
  final String marker;
}

sealed class TurnResolutionTerminalEvent {
  const TurnResolutionTerminalEvent();
}

class TurnResolutionTerminalComplete extends TurnResolutionTerminalEvent {
  const TurnResolutionTerminalComplete(
    this.result, {
    this.turnTracePhases,
    this.aiTraceSections,
    this.turnTraceStartedAtUtc,
    this.turnTraceExportPath,
  });

  final TurnResolutionResult result;

  /// Phase-level traces from the worker isolate when [TurnResolutionRunner]
  /// was started with `turnTraceEnabled: true`.
  ///
  /// Omitted when the worker wrote the merged trace file directly (Refs #2277)
  /// to avoid multi-copy full-game JSON across [SendPort].
  final List<TurnTracePhaseTrace>? turnTracePhases;

  /// Full-AI diagnostic sections from the worker isolate when tracing is enabled;
  /// aligned with [turnTracePhases].
  final List<TurnTraceAiSection>? aiTraceSections;

  /// UTC time resolution tracing started (after AI merge, before phase handlers).
  final DateTime? turnTraceStartedAtUtc;

  /// Path of exported merged turn trace JSON on disk when tracing ran in the worker.
  final String? turnTraceExportPath;
}

class TurnResolutionTerminalError extends TurnResolutionTerminalEvent {
  const TurnResolutionTerminalError({
    required this.errorMessage,
    required this.stackTrace,
  });

  final String errorMessage;
  final String stackTrace;
}

class TurnResolutionRunnerSession {
  TurnResolutionRunnerSession({
    required this.sessionId,
    required this.progress,
    required this.done,
    required this.dispose,
  });

  final String sessionId;
  final Stream<TurnResolutionProgressEvent> progress;
  final Future<TurnResolutionTerminalEvent> done;
  final Future<void> Function() dispose;
}
