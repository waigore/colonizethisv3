import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_app/config/ct_debug_console.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

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
    _runnerLog.i(
      'logic: turn_resolution_runner session_start sessionId=$sessionId '
      'gameId=${game.id} turnTraceEnabled=$turnTraceEnabled '
      'payloadBytes='
      'game:${_safeJsonUtf8Bytes(gameJson)},'
      'orders:${_safeJsonUtf8Bytes(ordersJson)},'
      'topology:${_safeJsonUtf8Bytes(topologyJson)},'
      'tileMap:${_safeJsonUtf8Bytes(tileMapJson)}',
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
              'messageBytes=${_safeJsonUtf8Bytes(message)} '
              'workerToMainMs=${portTransitMs ?? -1}',
            );
            final decodeStopwatch = Stopwatch()..start();
            final decodedResult = _decodeTurnResolutionResult(
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
              'resultType=${_resultTypeName(decodedResult)} '
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

      Isolate.spawn<Map<String, Object?>>(_turnResolutionIsolateMain, {
            'sendPort': receivePort.sendPort,
            'game': gameJson,
            'orders': ordersJson,
            'topology': topologyJson,
            'tileMapByRegion': tileMapJson,
            'turnTraceEnabled': turnTraceEnabled,
            'turnTraceRootDirectory': turnTraceRootDirectory,
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

void _turnResolutionIsolateMain(Map<String, Object?> args) {
  unawaited(_turnResolutionIsolateBody(args));
}

Future<void> _turnResolutionIsolateBody(Map<String, Object?> args) async {
  final sendPort = args['sendPort']! as SendPort;
  final workerStopwatch = Stopwatch()..start();
  try {
    final decodeStopwatch = Stopwatch()..start();
    final game = Game.fromJson(
      Map<String, dynamic>.from(args['game']! as Map<Object?, Object?>),
    );
    final humanOrders = Orders.fromJson(
      Map<String, dynamic>.from(args['orders']! as Map<Object?, Object?>),
    );
    final topology = MapTopology.fromJson(
      Map<String, dynamic>.from(args['topology']! as Map<Object?, Object?>),
    );
    final rawTileMap = Map<String, dynamic>.from(
      args['tileMapByRegion']! as Map<Object?, Object?>,
    );
    final tileMapByRegion = rawTileMap.map<String, TileMapResult>(
      (key, value) => MapEntry(
        key,
        TileMapResult.fromJson(
          Map<String, dynamic>.from(value as Map<Object?, Object?>),
        ),
      ),
    );
    final turnTraceEnabled = args['turnTraceEnabled'] == true;
    final turnTraceRootDirectory =
        (args['turnTraceRootDirectory'] as String?) ?? kCtTurnTraceDirectory;
    _runnerLog.i(
      'logic: turn_resolution_worker start gameId=${game.id} '
      'turnTraceEnabled=$turnTraceEnabled decodeMs=${decodeStopwatch.elapsedMilliseconds}',
    );
    sendPort.send(<String, Object?>{
      'kind': 'phase',
      'phase': 'aiPlanning',
      'marker': 'start',
    });
    final aiStopwatch = Stopwatch()..start();
    final fullAi = generateOrdersForGameFullAI(
      game,
      topology,
      tileMapByRegion: tileMapByRegion,
      onStagedPlannerProgress: (String phase) {
        sendPort.send(<String, Object?>{
          'kind': 'phase',
          'phase': phase,
          'marker': 'start',
        });
      },
    );
    _runnerLog.i(
      'logic: turn_resolution_worker ai_complete gameId=${game.id} '
      'aiMs=${aiStopwatch.elapsedMilliseconds}',
    );
    sendPort.send(<String, Object?>{
      'kind': 'phase',
      'phase': 'aiMerge',
      'marker': 'start',
    });
    final mergeStopwatch = Stopwatch()..start();
    final mergedOrders = mergeOrderLists(
      humanOrders: humanOrders,
      aiOrders: fullAi.orders,
    );
    _runnerLog.d(
      'logic: turn_resolution_worker merge_complete gameId=${game.id} '
      'mergeMs=${mergeStopwatch.elapsedMilliseconds}',
    );
    final traceStartedAt = turnTraceEnabled ? DateTime.now().toUtc() : null;
    final phaseTraces = <TurnTracePhaseTrace>[];
    final traceRuntime = turnTraceEnabled ? TurnTraceRuntime() : null;
    final resolveStopwatch = Stopwatch()..start();
    final result = validateOrdersAndResolveTurnFromTrustedOrders(
      game: fullAi.game,
      topology: topology,
      orders: mergedOrders,
      tileMapByRegion: tileMapByRegion,
      onPhaseProgress: (phase, marker) {
        sendPort.send({
          'kind': 'phase',
          'phase': phase.name,
          'marker': marker.name,
        });
      },
      onTurnTracePhase: turnTraceEnabled ? phaseTraces.add : null,
      turnTraceRuntime: traceRuntime,
    );
    _runnerLog.i(
      'logic: turn_resolution_worker resolve_complete gameId=${game.id} '
      'resultType=${_resultTypeName(result)} '
      'resolveMs=${resolveStopwatch.elapsedMilliseconds}',
    );

    String? exportedTracePath;
    int exportMs = 0;
    if (turnTraceEnabled &&
        traceStartedAt != null &&
        result is TurnResolutionComplete) {
      final exportStopwatch = Stopwatch()..start();
      final now = DateTime.now().toUtc();
      final document = TurnTraceMergedDocument(
        schemaVersion: kTurnTraceSchemaVersionV1,
        meta: TurnTraceMeta(
          gameId: game.id,
          turnNumber: game.worldState.turnState.turnNumber,
          traceEnabled: true,
          source: 'app_turn_worker',
          exportedAt: now.toIso8601String(),
          turnStartAt: traceStartedAt.toIso8601String(),
          turnEndAt: now.toIso8601String(),
        ),
        ai: List<TurnTraceAiSection>.unmodifiable(fullAi.aiTraceSections),
        turnResolution: TurnTraceResolutionSection(
          phases: List<TurnTracePhaseTrace>.unmodifiable(phaseTraces),
        ),
      );
      final file = await TurnTraceFileExporter(
        rootDirectory: turnTraceRootDirectory,
      ).export(document);
      exportedTracePath = file.path;
      exportMs = exportStopwatch.elapsedMilliseconds;
      _runnerLog.i(
        'logic: turn_resolution_worker trace_export_complete gameId=${game.id} '
        'exportMs=$exportMs path=$exportedTracePath',
      );
    }

    final encodedResult = _encodeTurnResolutionResult(result);
    final workerFinishedAtUtc = DateTime.now().toUtc();
    _runnerLog.i(
      'logic: turn_resolution_worker success_ready gameId=${game.id} '
      'elapsedMs=${workerStopwatch.elapsedMilliseconds} '
      'resultBytes=${_safeJsonUtf8Bytes(encodedResult)} '
      'exportMs=$exportMs',
    );
    sendPort.send(<String, Object?>{
      'kind': 'success',
      'result': encodedResult,
      if (traceStartedAt != null)
        'turnTraceStartedAtUtc': traceStartedAt.toIso8601String(),
      if (exportedTracePath != null) 'turnTraceExportPath': exportedTracePath,
      'workerFinishedAtUtc': workerFinishedAtUtc.toIso8601String(),
    });
  } catch (e, st) {
    _runnerLog.e(
      'logic: turn_resolution_worker failed '
      'elapsedMs=${workerStopwatch.elapsedMilliseconds}',
      error: e,
      stackTrace: st,
    );
    sendPort.send({
      'kind': 'error',
      'error': e.toString(),
      'stackTrace': st.toString(),
    });
  }
}

int _safeJsonUtf8Bytes(Object? value) {
  try {
    return utf8.encode(jsonEncode(value)).length;
  } catch (_) {
    return -1;
  }
}

String _resultTypeName(TurnResolutionResult result) {
  return switch (result) {
    TurnResolutionComplete() => 'complete',
    TurnResolutionPendingOvertures() => 'pendingOvertures',
    TurnResolutionPendingFtp() => 'pendingFtp',
    TurnResolutionPendingIntervention() => 'pendingIntervention',
    TurnResolutionPendingCallToArms() => 'pendingCallToArms',
  };
}

Map<String, Object?> _encodeTurnResolutionResult(TurnResolutionResult result) {
  switch (result) {
    case TurnResolutionComplete():
      return {'type': 'complete', 'game': result.game.toJson()};
    case TurnResolutionPendingOvertures():
      return {
        'type': 'pendingOvertures',
        'game': result.game.toJson(),
        'pendingOvertures': result.pendingOvertures
            .map(
              (offer) => {
                'offererGpId': offer.offererGpId,
                'targetFactionId': offer.targetFactionId,
                'stage': offer.stage.name,
              },
            )
            .toList(growable: false),
      };
    case TurnResolutionPendingFtp():
      return {
        'type': 'pendingFtp',
        'game': result.game.toJson(),
        'pendingFtpOffers': result.pendingFtpOffers
            .map(
              (offer) => {
                'proposerGpId': offer.proposerGpId,
                'targetGpId': offer.targetGpId,
              },
            )
            .toList(growable: false),
      };
    case TurnResolutionPendingIntervention():
      return {
        'type': 'pendingIntervention',
        'game': result.game.toJson(),
        'pendingInterventions': result.pendingInterventions
            .map(
              (prompt) => {
                'aggressorGpId': prompt.aggressorGpId,
                'defenderMinorOrTribeId': prompt.defenderMinorOrTribeId,
                'interveningGpId': prompt.interveningGpId,
              },
            )
            .toList(growable: false),
      };
    case TurnResolutionPendingCallToArms():
      return {
        'type': 'pendingCallToArms',
        'game': result.game.toJson(),
        'pendingCallToArms': result.pendingCallToArms
            .map(
              (pending) => {
                'allyGpId': pending.allyGpId,
                'defenderGpId': pending.defenderGpId,
                'aggressorGpId': pending.aggressorGpId,
              },
            )
            .toList(growable: false),
      };
  }
}

TurnResolutionResult _decodeTurnResolutionResult(Map<String, dynamic> json) {
  final game = Game.fromJson(
    Map<String, dynamic>.from(json['game'] as Map<Object?, Object?>),
  );
  final type = json['type'] as String;
  switch (type) {
    case 'complete':
      return TurnResolutionComplete(game);
    case 'pendingOvertures':
      final list = (json['pendingOvertures'] as List<dynamic>)
          .map(
            (entry) =>
                Map<String, dynamic>.from(entry as Map<Object?, Object?>),
          )
          .map(
            (entry) => OvertureOffer(
              offererGpId: entry['offererGpId'] as String,
              targetFactionId: entry['targetFactionId'] as String,
              stage: OvertureStage.values.byName(entry['stage'] as String),
            ),
          )
          .toList(growable: false);
      return TurnResolutionPendingOvertures(game: game, pendingOvertures: list);
    case 'pendingFtp':
      final ftpList = (json['pendingFtpOffers'] as List<dynamic>)
          .map(
            (entry) =>
                Map<String, dynamic>.from(entry as Map<Object?, Object?>),
          )
          .map(
            (entry) => FtpOffer(
              proposerGpId: entry['proposerGpId'] as String,
              targetGpId: entry['targetGpId'] as String,
            ),
          )
          .toList(growable: false);
      return TurnResolutionPendingFtp(game: game, pendingFtpOffers: ftpList);
    case 'pendingIntervention':
      final list = (json['pendingInterventions'] as List<dynamic>)
          .map(
            (entry) =>
                Map<String, dynamic>.from(entry as Map<Object?, Object?>),
          )
          .map(
            (entry) => InterventionPrompt(
              aggressorGpId: entry['aggressorGpId'] as String,
              defenderMinorOrTribeId: entry['defenderMinorOrTribeId'] as String,
              interveningGpId: entry['interveningGpId'] as String,
            ),
          )
          .toList(growable: false);
      return TurnResolutionPendingIntervention(
        game: game,
        pendingInterventions: list,
      );
    case 'pendingCallToArms':
      final list = (json['pendingCallToArms'] as List<dynamic>)
          .map(
            (entry) =>
                Map<String, dynamic>.from(entry as Map<Object?, Object?>),
          )
          .map(
            (entry) => CallToArmsPending(
              allyGpId: entry['allyGpId'] as String,
              defenderGpId: entry['defenderGpId'] as String,
              aggressorGpId: entry['aggressorGpId'] as String,
            ),
          )
          .toList(growable: false);
      return TurnResolutionPendingCallToArms(
        game: game,
        pendingCallToArms: list,
      );
    default:
      throw StateError('Unknown turn resolution result type: $type');
  }
}
