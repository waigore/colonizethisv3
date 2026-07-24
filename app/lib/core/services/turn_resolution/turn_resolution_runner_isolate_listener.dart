import 'dart:async';

import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

import 'turn_resolution_result_codec.dart';
import 'turn_resolution_runner_types.dart';

final _isolateListenerLog = packageLogger('logic');

List<TurnTracePhaseTrace>? decodeTurnTracePhases(Object? phasesPayload) {
  if (phasesPayload is! List<Object?>) {
    return null;
  }
  return phasesPayload
      .map(
        (Object? e) => TurnTracePhaseTrace.fromJson(
          Map<String, Object?>.fromEntries(
            (e as Map<Object?, Object?>).entries.map(
              (MapEntry<Object?, Object?> entry) => MapEntry<String, Object?>(
                entry.key as String,
                entry.value,
              ),
            ),
          ),
        ),
      )
      .toList(growable: false);
}

List<TurnTraceAiSection>? decodeAiTraceSections(Object? aiTracePayload) {
  if (aiTracePayload is! List<Object?>) {
    return null;
  }
  return aiTracePayload
      .map(
        (Object? e) => TurnTraceAiSection.fromJson(
          Map<String, Object?>.fromEntries(
            (e as Map<Object?, Object?>).entries.map(
              (MapEntry<Object?, Object?> entry) => MapEntry<String, Object?>(
                entry.key as String,
                entry.value,
              ),
            ),
          ),
        ),
      )
      .toList(growable: false);
}

TurnResolutionTerminalComplete decodeSuccessTurnResolutionTerminal(
  Map<Object?, Object?> message, {
  required String sessionId,
}) {
  final decodedResult = decodeTurnResolutionResult(
    Map<String, dynamic>.from(
      message['result'] as Map<Object?, Object?>,
    ),
  );
  final startedRaw = message['turnTraceStartedAtUtc'];
  final DateTime? traceStartedAt = startedRaw is String
      ? DateTime.parse(startedRaw).toUtc()
      : null;
  final exportPath = message['turnTraceExportPath'] as String?;
  if (exportPath != null) {
    _isolateListenerLog.d(
      'logic: turn_trace_exported_worker sessionId=$sessionId '
      'path=$exportPath',
    );
  }
  return TurnResolutionTerminalComplete(
    decodedResult,
    turnTracePhases: decodeTurnTracePhases(message['turnTracePhases']),
    aiTraceSections: decodeAiTraceSections(message['aiTraceSections']),
    turnTraceStartedAtUtc: traceStartedAt,
    turnTraceExportPath: exportPath,
  );
}

void handleTurnResolutionIsolateMessage({
  required dynamic message,
  required String sessionId,
  required Stopwatch sessionStopwatch,
  required StreamController<TurnResolutionProgressEvent> progressController,
  required Completer<TurnResolutionTerminalEvent> doneCompleter,
  required void Function() scheduleTearDownAfterPortMessage,
  void Function(Map<Object?, Object?> message)? inspectSuccessIsolateEnvelope,
}) {
  if (message is! Map<Object?, Object?>) {
    return;
  }
  final kind = message['kind'];
  if (kind == 'phase') {
    final phaseName = message['phase'] as String;
    final markerName = message['marker'] as String;
    _isolateListenerLog.d(
      'logic: turn_resolution_runner phase sessionId=$sessionId '
      'phase=$phaseName marker=$markerName '
      'elapsedMs=${sessionStopwatch.elapsedMilliseconds}',
    );
    progressController.add(
      TurnResolutionProgressEvent(
        sessionId: sessionId,
        phase: phaseName,
        marker: markerName,
      ),
    );
    return;
  }
  if (kind == 'success') {
    try {
      final successReceivedAtUtc = DateTime.now().toUtc();
      final workerFinishedRaw = message['workerFinishedAtUtc'];
      final workerFinishedAtUtc = workerFinishedRaw is String
          ? DateTime.tryParse(workerFinishedRaw)?.toUtc()
          : null;
      final portTransitMs = workerFinishedAtUtc == null
          ? null
          : successReceivedAtUtc
                .difference(workerFinishedAtUtc)
                .inMilliseconds;
      inspectSuccessIsolateEnvelope?.call(message);
      _isolateListenerLog.i(
        'logic: turn_resolution_runner session_complete sessionId=$sessionId '
        'outcome=success elapsedMs=${sessionStopwatch.elapsedMilliseconds} '
        'messageBytes=${safeTurnResolutionJsonUtf8Bytes(message)} '
        'workerToMainMs=${portTransitMs ?? -1}',
      );
      final decodeStopwatch = Stopwatch()..start();
      final terminal = decodeSuccessTurnResolutionTerminal(
        message,
        sessionId: sessionId,
      );
      if (!doneCompleter.isCompleted) {
        doneCompleter.complete(terminal);
      }
      _isolateListenerLog.i(
        'logic: turn_resolution_runner decode_complete sessionId=$sessionId '
        'decodeMs=${decodeStopwatch.elapsedMilliseconds} '
        'resultType=${turnResolutionResultTypeName(terminal.result)} '
        'elapsedMs=${sessionStopwatch.elapsedMilliseconds}',
      );
    } catch (e, st) {
      _isolateListenerLog.e(
        'logic: turn_resolution_runner session_complete_decode_failed '
        'sessionId=$sessionId',
        error: e,
        stackTrace: st,
      );
      if (!doneCompleter.isCompleted) {
        doneCompleter.complete(
          TurnResolutionTerminalError(
            errorMessage: e.toString(),
            stackTrace: st.toString(),
          ),
        );
      }
    }
    scheduleTearDownAfterPortMessage();
    return;
  }
  if (kind == 'error') {
    final errMsg = (message['error'] as String?) ?? 'Unknown error';
    final stackStr = (message['stackTrace'] as String?) ?? '';
    _isolateListenerLog.e(
      'logic: turn_resolution_runner session_complete sessionId=$sessionId '
      'outcome=error elapsedMs=${sessionStopwatch.elapsedMilliseconds}',
      error: errMsg,
      stackTrace: stackStr.isEmpty ? null : StackTrace.fromString(stackStr),
    );
    final terminal = TurnResolutionTerminalError(
      errorMessage: errMsg,
      stackTrace: stackStr,
    );
    if (!doneCompleter.isCompleted) {
      doneCompleter.complete(terminal);
    }
    scheduleTearDownAfterPortMessage();
  }
}
