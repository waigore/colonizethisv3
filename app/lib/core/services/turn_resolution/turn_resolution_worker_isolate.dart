import 'dart:async';
import 'dart:isolate';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_app_fixtures/config/ct_debug_console.dart';
import 'package:colonizethis_app/core/services/ai/ai_profile_resolution.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'turn_resolution_result_codec.dart';

final _workerLog = packageLogger('logic');

/// Isolate entry for Full AI + merge + trusted-path resolution (Refs #3878).
void turnResolutionWorkerIsolateMain(Map<String, Object?> args) {
  unawaited(turnResolutionWorkerIsolateBody(args));
}

Future<void> turnResolutionWorkerIsolateBody(Map<String, Object?> args) async {
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
    final aiProfiles = decodeAiProfilesFromIsolate(args['aiProfiles']);
    _workerLog.i(
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
      profiles: aiProfiles,
      onStagedPlannerProgress: (String phase) {
        sendPort.send(<String, Object?>{
          'kind': 'phase',
          'phase': phase,
          'marker': 'start',
        });
      },
    );
    _workerLog.i(
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
    _workerLog.d(
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
    _workerLog.i(
      'logic: turn_resolution_worker resolve_complete gameId=${game.id} '
      'resultType=${turnResolutionResultTypeName(result)} '
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
      _workerLog.i(
        'logic: turn_resolution_worker trace_export_complete gameId=${game.id} '
        'exportMs=$exportMs path=$exportedTracePath',
      );
    }

    final encodedResult = encodeTurnResolutionResult(result);
    final workerFinishedAtUtc = DateTime.now().toUtc();
    _workerLog.i(
      'logic: turn_resolution_worker success_ready gameId=${game.id} '
      'elapsedMs=${workerStopwatch.elapsedMilliseconds} '
      'resultBytes=${safeTurnResolutionJsonUtf8Bytes(encodedResult)} '
      'exportMs=$exportMs',
    );
    sendPort.send(<String, Object?>{
      'kind': 'success',
      'result': encodedResult,
      'turnTraceStartedAtUtc': traceStartedAt?.toIso8601String(),
      'turnTraceExportPath': exportedTracePath,
      'workerFinishedAtUtc': workerFinishedAtUtc.toIso8601String(),
    });
  } catch (e, st) {
    _workerLog.e(
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
