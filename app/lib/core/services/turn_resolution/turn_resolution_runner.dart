import 'dart:async';
import 'dart:isolate';

import 'package:colonizethis_app_fixtures/config/ct_debug_console.dart';
import 'package:colonizethis_app/core/services/ai/ai_profile_resolution.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'turn_resolution_result_codec.dart';
import 'turn_resolution_worker_isolate.dart';

part 'turn_resolution_runner_types.dart';
part 'turn_resolution_runner_isolate_listener.dart';

final _runnerLog = packageLogger('logic');

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
        _handleIsolateMessage(
          message: message,
          sessionId: sessionId,
          sessionStopwatch: sessionStopwatch,
          progressController: progressController,
          doneCompleter: doneCompleter,
          scheduleTearDownAfterPortMessage: scheduleTearDownAfterPortMessage,
        );
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
