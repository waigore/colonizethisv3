import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'observer_snapshot_v1.dart';
import 'package_logger.dart';

final _sessionLog = packageLogger('session');

Game _greatPowersAiOnly(Game game) {
  return game.copyWith(
    aiControlByGpId: {for (final p in game.players) p.id: true},
  );
}

/// Runs init + Full AI loop; writes traces, snapshots, and `run-summary.json`.
/// Exit code 0 on success; non-zero on setup/resolve/export failure.
Future<int> runObserverSession({
  required String outputRoot,
  required GameSetupConfig setupConfig,
  int? maxTurnsCap,
}) async {
  late final InitGameResult init;
  try {
    init = runInitGame(
      config: setupConfig,
      options: const InitGameOptions(
        cellSize: 24,
        renderPng: false,
        skipFillLakes: false,
      ),
    );
  } on Object catch (e, st) {
    _sessionLog.e('observer:init_failed', error: e, stackTrace: st);
    return 2;
  }

  Game game = _greatPowersAiOnly(init.game);
  final exporter = TurnTraceFileExporter(
    rootDirectory: '$outputRoot/observer-traces',
    traceDirectorySegment: '',
    pruningEnabled: false,
  );

  var resolvedCount = 0;
  var terminationReason = 'unknown';

  try {
    while (true) {
      if (maxTurnsCap != null && resolvedCount >= maxTurnsCap) {
        terminationReason = 'max_turns_override';
        break;
      }
      if (game.victory != null) {
        terminationReason = 'military_victory';
        break;
      }
      if (game.calendarCampaignHalted) {
        terminationReason = 'calendar_1800';
        break;
      }

      final before = game;

      final fullAi = generateOrdersForGameFullAI(
        before,
        init.combinedTopology,
        tileMapByRegion: init.tileMapByRegion,
      );

      final mergedOrders = mergeOrderLists(
        humanOrders: const Orders(),
        aiOrders: fullAi.orders,
      );
      final defaultAssignmentsByPlayerId = fullAi.economyPlansByPlayerId.map(
        (pid, plan) => MapEntry(pid, plan.productionAssignments),
      );

      final phaseTraces = <TurnTracePhaseTrace>[];
      final traceStartedAt = DateTime.now().toUtc();
      final traceRuntime = TurnTraceRuntime();

      final result = validateOrdersAndResolveTurnFromTrustedOrders(
        game: before,
        topology: init.combinedTopology,
        orders: mergedOrders,
        tileMapByRegion: init.tileMapByRegion,
        defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
        onTurnTracePhase: phaseTraces.add,
        turnTraceRuntime: traceRuntime,
      );

      if (result is! TurnResolutionComplete) {
        _sessionLog.e(
          'observer:resolution_pending turn=${before.worldState.turnState.turnNumber} '
          'result=${result.runtimeType}',
        );
        return 3;
      }

      game = requireTurnResolutionComplete(result);

      final nowUtc = DateTime.now().toUtc();
      final document = TurnTraceMergedDocument(
        schemaVersion: kTurnTraceSchemaVersionV1,
        meta: TurnTraceMeta(
          gameId: before.id,
          turnNumber: before.worldState.turnState.turnNumber,
          traceEnabled: true,
          source: 'run_observer_game',
          exportedAt: nowUtc.toIso8601String(),
          turnStartAt: traceStartedAt.toIso8601String(),
          turnEndAt: nowUtc.toIso8601String(),
        ),
        ai: List<TurnTraceAiSection>.unmodifiable(fullAi.aiTraceSections),
        turnResolution: TurnTraceResolutionSection(
          phases: List<TurnTracePhaseTrace>.unmodifiable(phaseTraces),
        ),
      );
      await exporter.export(document);

      final postTurn = game.worldState.turnState.turnNumber;
      final turnLabel = postTurn.toString().padLeft(6, '0');

      final traceDir = Directory('${exporter.rootDirectory}/${before.id}');

      final snap = buildObserverSnapshotJson(
        game,
        postResolutionTurnNumber: postTurn,
      );
      final snapshotText = encodeObserverSnapshotJson(snap);
      await File(
        '${traceDir.path}/turn-$turnLabel.snapshot.json',
      ).writeAsString(snapshotText);
      await File(
        '${traceDir.path}/turn-$turnLabel.html',
      ).writeAsString(renderObserverSnapshotHtml(snapshotText.trimRight()));

      resolvedCount++;

      _sessionLog.i(
        'observer:turn_resolved count=$resolvedCount postTurn=$postTurn '
        'gameId=${game.id}',
      );
    }
  } on Object catch (e, st) {
    _sessionLog.e('observer:run_loop_failed', error: e, stackTrace: st);
    return 2;
  }

  final summaryDir = Directory('$outputRoot/observer-traces/${game.id}');
  await summaryDir.create(recursive: true);

  final winnerId = game.victory != null
      ? game.victory!.winnerPlayerId
      : pickUniqueGreatPowerLeaderByPowerScore(game);

  final summary = <String, Object?>{
    'runSummarySchemaVersion': 1,
    'termination_reason': terminationReason,
    'declared_winner_player_id': winnerId,
    'final_turn_number': game.worldState.turnState.turnNumber,
    'resolved_full_turns': resolvedCount,
    'seed': setupConfig.seed,
    'game_id': game.id,
    'observer_traces_relative': 'observer-traces/${game.id}',
  };

  await File(
    '${summaryDir.path}/run-summary.json',
  ).writeAsString('${const JsonEncoder.withIndent('  ').convert(summary)}\n');

  return 0;
}
