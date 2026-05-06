import 'dart:async';
import 'dart:isolate';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

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
  const TurnResolutionTerminalComplete(this.result);
  final TurnResolutionResult result;
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

    final aiOrders = generateOrdersForGameFullAI(
      game,
      topology,
      tileMapByRegion: tileMapByRegion,
    ).orders;
    final mergedOrders = mergeOrderLists(
      humanOrders: orders,
      aiOrders: aiOrders,
    );

    Future<void> cleanup() async {
      await sub?.cancel();
      receivePort.close();
      isolate?.kill(priority: Isolate.immediate);
      if (!progressController.isClosed) {
        await progressController.close();
      }
      _active = false;
    }

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
        doneCompleter.complete(
          TurnResolutionTerminalComplete(
            _decodeTurnResolutionResult(
              Map<String, dynamic>.from(message['result'] as Map),
            ),
          ),
        );
        await cleanup();
        return;
      }
      if (kind == 'error') {
        doneCompleter.complete(
          TurnResolutionTerminalError(
            errorMessage: (message['error'] as String?) ?? 'Unknown error',
            stackTrace: (message['stackTrace'] as String?) ?? '',
          ),
        );
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
        })
        .then((spawned) {
          isolate = spawned;
        })
        .catchError((Object e, StackTrace st) async {
          doneCompleter.complete(
            TurnResolutionTerminalError(
              errorMessage: e.toString(),
              stackTrace: st.toString(),
            ),
          );
          await cleanup();
        });

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
    final game = Game.fromJson(Map<String, dynamic>.from(args['game']! as Map));
    final orders = Orders.fromJson(
      Map<String, dynamic>.from(args['orders']! as Map),
    );
    final topology = MapTopology.fromJson(
      Map<String, dynamic>.from(args['topology']! as Map),
    );
    final rawTileMap = Map<String, dynamic>.from(
      args['tileMapByRegion']! as Map,
    );
    final tileMapByRegion = rawTileMap.map<String, TileMapResult>(
      (key, value) => MapEntry(
        key,
        TileMapResult.fromJson(Map<String, dynamic>.from(value as Map)),
      ),
    );
    final result = resolveTurnForGame(
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
    );
    sendPort.send({
      'kind': 'success',
      'result': _encodeTurnResolutionResult(result),
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
  final game = Game.fromJson(Map<String, dynamic>.from(json['game'] as Map));
  final type = json['type'] as String;
  switch (type) {
    case 'complete':
      return TurnResolutionComplete(game);
    case 'pendingOvertures':
      final list = (json['pendingOvertures'] as List<dynamic>)
          .map((entry) => Map<String, dynamic>.from(entry as Map))
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
          .map((entry) => Map<String, dynamic>.from(entry as Map))
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
          .map((entry) => Map<String, dynamic>.from(entry as Map))
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
