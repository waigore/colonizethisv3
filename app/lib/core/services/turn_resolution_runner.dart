import 'dart:async';
import 'dart:isolate';

import 'package:colonizethis_app/config/ct_debug_console.dart';
import 'package:colonizethis_app/core/services/ai_profile_resolution.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'turn_resolution_result_codec.dart';
import 'turn_resolution_worker_isolate.dart';

final _runnerLog = packageLogger('logic');

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

class TurnResolutionRunner {
  TurnResolutionRunner({this.inspectSuccessIsolateEnvelope});

  /// Optional hook (e.g. tests): receives the raw isolate `success` map before
  /// JSON-shaped fields are decoded. Refs #2277 (no huge trace blobs on SendPort).
  final void Function(Map<Object?, Object?> message)?
      inspectSuccessIsolateEnvelope;

  bool _active = false;

  bool get isActive => _active;

  /// Runs Full AI, [mergeOrderLists], and trusted-path resolution in one worker
  /// isolate. [orders] must be the **human** draft only (AI slots filled inside
  /// the worker). Refs #2277.
  TurnResolutionRunnerSession startResolution({
    required Game game,
    required Orders orders,
    required MapTopology topology,
    required Map<String, TileMapResult> tileMapByRegion,
    bool turnTraceEnabled = false,
    String turnTraceRootDirectory = kCtTurnTraceDirectory,
    Map<String, AiProfile>? aiProfiles,
  }) {
    if (_active) {
      throw StateError('Turn resolution already active');
    }
    _active = true;
    final sessionId = 'turn-${DateTime.now().microsecondsSinceEpoch}';
    final progressController = StreamController<TurnResolutionProgressEvent>();
    final doneCompleter = Completer<TurnResolutionTerminalEvent>();
    final receivePort = ReceivePort();
    final sessionStopwatch = Stopwatch()..start();
    Isolate? isolate;
    StreamSubscription<dynamic>? sub;

    final gameJson = game.toJson();
    final ordersJson = orders.toJson();
    final topologyJson = topology.toJson();
    final tileMapJson = tileMapByRegion.map((k, v) => MapEntry(k, v.toJson()));
    final aiProfilesJson = encodeAiProfilesForIsolate(aiProfiles);
    _runnerLog.i(
      'logic: turn_resolution_runner session_start sessionId=$sessionId '
      'gameId=${game.id} turnTraceEnabled=$turnTraceEnabled '
      'payloadBytes='
      'game:${safeTurnResolutionJsonUtf8Bytes(gameJson)},'
      'orders:${safeTurnResolutionJsonUtf8Bytes(ordersJson)},'
      'topology:${safeTurnResolutionJsonUtf8Bytes(topologyJson)},'
      'tileMap:${safeTurnResolutionJsonUtf8Bytes(tileMapJson)}',
    );

    Future<void> tearDownSession() async {
      await sub?.cancel();
      receivePort.close();
      isolate?.kill(priority: Isolate.immediate);
      if (!progressController.isClosed) {
        await progressController.close();
      }
    }

    Future<void> cleanup() async {
      // Clear re-entrancy flag before awaiting subscription cancel so callers
      // that await [TurnResolutionRunnerSession.done] observe a released runner
      // even if cancel is deferred (#2160).
      _active = false;
      await tearDownSession();
    }

    /// Never await [StreamSubscription.cancel] synchronously from inside the same
    /// [ReceivePort.listen] callback: it can deadlock the isolate after the last
    /// resolver phase event (UI stuck on "Finalizing turn..."). Refs #2277.
    void scheduleTearDownAfterPortMessage() {
      _active = false;
      scheduleMicrotask(() {
        unawaited(tearDownSession());
      });
    }

    try {
      sub = receivePort.listen((dynamic message) {
        if (message is! Map<Object?, Object?>) {
          return;
        }
        final kind = message['kind'];
        if (kind == 'phase') {
          final phaseName = message['phase'] as String;
          final markerName = message['marker'] as String;
          _runnerLog.d(
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
            _runnerLog.i(
              'logic: turn_resolution_runner session_complete sessionId=$sessionId '
              'outcome=success elapsedMs=${sessionStopwatch.elapsedMilliseconds} '
              'messageBytes=${safeTurnResolutionJsonUtf8Bytes(message)} '
              'workerToMainMs=${portTransitMs ?? -1}',
            );
            final decodeStopwatch = Stopwatch()..start();
            final decodedResult = decodeTurnResolutionResult(
              Map<String, dynamic>.from(
                message['result'] as Map<Object?, Object?>,
              ),
            );
            final phasesPayload = message['turnTracePhases'];
            final List<TurnTracePhaseTrace>? decodedPhases;
            if (phasesPayload is List<Object?>) {
              decodedPhases = phasesPayload
                  .map(
                    (Object? e) => TurnTracePhaseTrace.fromJson(
                      Map<String, Object?>.fromEntries(
                        (e as Map<Object?, Object?>).entries.map(
                          (MapEntry<Object?, Object?> entry) =>
                              MapEntry<String, Object?>(
                                entry.key as String,
                                entry.value,
                              ),
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false);
            } else {
              decodedPhases = null;
            }
            final startedRaw = message['turnTraceStartedAtUtc'];
            final DateTime? traceStartedAt = startedRaw is String
                ? DateTime.parse(startedRaw).toUtc()
                : null;
            final aiTracePayload = message['aiTraceSections'];
            final List<TurnTraceAiSection>? decodedAiSections;
            if (aiTracePayload is List<Object?>) {
              decodedAiSections = aiTracePayload
                  .map(
                    (Object? e) => TurnTraceAiSection.fromJson(
                      Map<String, Object?>.fromEntries(
                        (e as Map<Object?, Object?>).entries.map(
                          (MapEntry<Object?, Object?> entry) =>
                              MapEntry<String, Object?>(
                                entry.key as String,
                                entry.value,
                              ),
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false);
            } else {
              decodedAiSections = null;
            }
            final exportPath = message['turnTraceExportPath'] as String?;
            if (exportPath != null) {
              _runnerLog.d(
                'logic: turn_trace_exported_worker sessionId=$sessionId '
                'path=$exportPath',
              );
            }
            final terminal = TurnResolutionTerminalComplete(
              decodedResult,
              turnTracePhases: decodedPhases,
              aiTraceSections: decodedAiSections,
              turnTraceStartedAtUtc: traceStartedAt,
              turnTraceExportPath: exportPath,
            );
            if (!doneCompleter.isCompleted) {
              doneCompleter.complete(terminal);
            }
            _runnerLog.i(
              'logic: turn_resolution_runner decode_complete sessionId=$sessionId '
              'decodeMs=${decodeStopwatch.elapsedMilliseconds} '
              'resultType=${turnResolutionResultTypeName(decodedResult)} '
              'elapsedMs=${sessionStopwatch.elapsedMilliseconds}',
            );
          } catch (e, st) {
            _runnerLog.e(
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
          _runnerLog.e(
            'logic: turn_resolution_runner session_complete sessionId=$sessionId '
            'outcome=error elapsedMs=${sessionStopwatch.elapsedMilliseconds}',
            error: errMsg,
            stackTrace: stackStr.isEmpty
                ? null
                : StackTrace.fromString(stackStr),
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
      });

      Isolate.spawn<Map<String, Object?>>(turnResolutionWorkerIsolateMain, {
            'sendPort': receivePort.sendPort,
            'game': gameJson,
            'orders': ordersJson,
            'topology': topologyJson,
            'tileMapByRegion': tileMapJson,
            'turnTraceEnabled': turnTraceEnabled,
            'turnTraceRootDirectory': turnTraceRootDirectory,
            'aiProfiles': aiProfilesJson,
          })
          .then((spawned) {
            isolate = spawned;
            _runnerLog.d(
              'logic: turn_resolution_runner isolate_spawned '
              'sessionId=$sessionId',
            );
          })
          .catchError((Object e, StackTrace st) async {
            _runnerLog.e(
              'logic: turn_resolution_runner isolate_spawn_failed '
              'sessionId=$sessionId',
              error: e,
              stackTrace: st,
            );
            final terminal = TurnResolutionTerminalError(
              errorMessage: e.toString(),
              stackTrace: st.toString(),
            );
            if (!doneCompleter.isCompleted) {
              doneCompleter.complete(terminal);
            }
            await cleanup();
          });
    } on Object catch (e, st) {
      _runnerLog.e(
        'logic: turn_resolution_runner session_start_failed '
        'sessionId=$sessionId',
        error: e,
        stackTrace: st,
      );
      receivePort.close();
      if (!progressController.isClosed) {
        progressController.close();
      }
      _active = false;
      Error.throwWithStackTrace(e, st);
    }

    return TurnResolutionRunnerSession(
      sessionId: sessionId,
      progress: progressController.stream,
      done: doneCompleter.future,
      dispose: cleanup,
    );
  }
}
