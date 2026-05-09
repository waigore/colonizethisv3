import 'dart:async';
import 'dart:isolate';

import 'package:colonizethis_ai/colonizethis_ai.dart';
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
  });

  final TurnResolutionResult result;

  /// Phase-level traces from the worker isolate when [TurnResolutionRunner]
  /// was started with `turnTraceEnabled: true`.
  final List<TurnTracePhaseTrace>? turnTracePhases;

  /// Full-AI diagnostic sections captured on the main isolate before the worker
  /// ran; aligned with [turnTracePhases] when tracing is enabled.
  final List<TurnTraceAiSection>? aiTraceSections;

  /// UTC time tracing started for this resolution (after AI orders merged).
  final DateTime? turnTraceStartedAtUtc;
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
  TurnResolutionRunner();

  bool _active = false;

  bool get isActive => _active;

  TurnResolutionRunnerSession startResolution({
    required Game game,
    required Orders orders,
    required MapTopology topology,
    required Map<String, TileMapResult> tileMapByRegion,
    bool turnTraceEnabled = false,
  }) {
    if (_active) {
      throw StateError('Turn resolution already active');
    }
    _active = true;
    final sessionId = 'turn-${DateTime.now().microsecondsSinceEpoch}';
    final progressController = StreamController<TurnResolutionProgressEvent>();
    final doneCompleter = Completer<TurnResolutionTerminalEvent>();
    final receivePort = ReceivePort();
    Isolate? isolate;
    StreamSubscription<dynamic>? sub;

    _runnerLog.i(
      'logic: turn_resolution_runner session_start sessionId=$sessionId '
      'gameId=${game.id}',
    );

    Future<void> cleanup() async {
      // Clear re-entrancy flag before awaiting subscription cancel so callers
      // that await [TurnResolutionRunnerSession.done] observe a released runner
      // even if cancel is deferred (#2160).
      _active = false;
      await sub?.cancel();
      receivePort.close();
      isolate?.kill(priority: Isolate.immediate);
      if (!progressController.isClosed) {
        await progressController.close();
      }
    }

    try {
      final fullAi = generateOrdersForGameFullAI(
        game,
        topology,
        tileMapByRegion: tileMapByRegion,
      );
      final mergedOrders = mergeOrderLists(
        humanOrders: orders,
        aiOrders: fullAi.orders,
      );
      final traceStartedAt =
          turnTraceEnabled ? DateTime.now().toUtc() : null;
      final aiTraceForExport = turnTraceEnabled
          ? List<TurnTraceAiSection>.unmodifiable(fullAi.aiTraceSections)
          : null;

      sub = receivePort.listen((dynamic message) async {
        if (message is! Map<Object?, Object?>) {
          return;
        }
        final kind = message['kind'];
        if (kind == 'phase') {
          final phaseName = message['phase'] as String;
          final markerName = message['marker'] as String;
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
          _runnerLog.i(
            'logic: turn_resolution_runner session_complete sessionId=$sessionId '
            'outcome=success',
          );
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
          final terminal = TurnResolutionTerminalComplete(
            decodedResult,
            turnTracePhases: decodedPhases,
            aiTraceSections: aiTraceForExport,
            turnTraceStartedAtUtc: traceStartedAt,
          );
          if (!doneCompleter.isCompleted) {
            doneCompleter.complete(terminal);
          }
          await cleanup();
          return;
        }
        if (kind == 'error') {
          final errMsg = (message['error'] as String?) ?? 'Unknown error';
          final stackStr = (message['stackTrace'] as String?) ?? '';
          _runnerLog.e(
            'logic: turn_resolution_runner session_complete sessionId=$sessionId '
            'outcome=error',
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
          await cleanup();
        }
      });

      Isolate.spawn<Map<String, Object?>>(_turnResolutionIsolateMain, {
            'sendPort': receivePort.sendPort,
            'game': game.toJson(),
            'orders': mergedOrders.toJson(),
            'topology': topology.toJson(),
            'tileMapByRegion': tileMapByRegion.map(
              (k, v) => MapEntry(k, v.toJson()),
            ),
            'turnTraceEnabled': turnTraceEnabled,
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
  final sendPort = args['sendPort']! as SendPort;
  try {
    final game = Game.fromJson(
      Map<String, dynamic>.from(args['game']! as Map<Object?, Object?>),
    );
    final orders = Orders.fromJson(
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
    final phaseTraces = <TurnTracePhaseTrace>[];
    final traceRuntime = turnTraceEnabled ? TurnTraceRuntime() : null;
    final result = validateOrdersAndResolveTurnFromTrustedOrders(
      game: game,
      topology: topology,
      orders: orders,
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
    sendPort.send({
      'kind': 'success',
      'result': _encodeTurnResolutionResult(result),
      if (turnTraceEnabled)
        'turnTracePhases':
            phaseTraces.map((TurnTracePhaseTrace p) => p.toJson()).toList(),
    });
  } catch (e, st) {
    sendPort.send({
      'kind': 'error',
      'error': e.toString(),
      'stackTrace': st.toString(),
    });
  }
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
