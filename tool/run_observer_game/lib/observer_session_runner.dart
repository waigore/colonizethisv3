import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'observer_minimal_trace.dart';
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
  bool verifyConquest = false,
  bool verifyColonialExpansion = false,
  bool verifyWorkforce = false,
  int verifyArtifactCapBytes = kObserverVerifyArtifactSizeCapBytes,
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

  final minimalTraceMode =
      verifyConquest || verifyColonialExpansion || verifyWorkforce;
  final requiredSnapshotTurns = minimalTraceMode
      ? requiredObserverSnapshotTurns(
          verifyConquest: verifyConquest,
          verifyColonialExpansion: verifyColonialExpansion,
          verifyWorkforce: verifyWorkforce,
        )
      : null;

  TurnTraceFileExporter? exporter;
  if (!minimalTraceMode) {
    exporter = TurnTraceFileExporter(
      rootDirectory: '$outputRoot/observer-traces',
      traceDirectorySegment: '',
      pruningEnabled: false,
    );
  }

  Game game = _greatPowersAiOnly(init.game);
  final traceRoot = '$outputRoot/observer-traces';
  final artifactBudget = minimalTraceMode
      ? ObserverArtifactBudget(capBytes: verifyArtifactCapBytes)
      : null;

  var resolvedCount = 0;
  var terminationReason = 'unknown';

  Future<void> writeTraceArtifact(
    String gameId,
    String relativeName,
    String content,
  ) async {
    final budget = artifactBudget;
    final byteLength = utf8.encode(content).length;
    if (budget != null) {
      if (budget.wouldExceed(byteLength)) {
        stderr.writeln(
          'observer:artifact_size_cap_exceeded gameId=$gameId '
          'capBytes=${budget.capBytes} '
          'written=${budget.bytesWritten} '
          'nextWrite=$byteLength',
        );
        throw _ArtifactSizeCapExceeded();
      }
    }

    final traceDir = Directory('$traceRoot/$gameId');
    await traceDir.create(recursive: true);
    await File('${traceDir.path}/$relativeName').writeAsString(content);

    budget?.recordBytes(byteLength);
  }

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
      final gameForResolution = fullAi.game;

      final mergedOrders = mergeOrderLists(
        humanOrders: const Orders(),
        aiOrders: fullAi.orders,
      );
      final defaultAssignmentsByPlayerId = fullAi.economyPlansByPlayerId.map(
        (pid, plan) => MapEntry(pid, plan.productionAssignments),
      );

      Map<String, Map<String, int>>? lastTurnProductionByRecipeByPlayerId;
      void captureProductionComplete(
        Map<String, Map<String, int>> productionByRecipeByPlayerId,
      ) {
        lastTurnProductionByRecipeByPlayerId = productionByRecipeByPlayerId.map(
          (pid, byRecipe) =>
              MapEntry(pid, Map<String, int>.unmodifiable(byRecipe)),
        );
      }

      final TurnResolutionResult result;
      if (minimalTraceMode) {
        result = validateOrdersAndResolveTurnFromTrustedOrders(
          game: gameForResolution,
          topology: init.combinedTopology,
          orders: mergedOrders,
          tileMapByRegion: init.tileMapByRegion,
          defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
          onProductionComplete: captureProductionComplete,
        );
      } else {
        final phaseTraces = <TurnTracePhaseTrace>[];
        final traceStartedAt = DateTime.now().toUtc();
        final traceRuntime = TurnTraceRuntime();

        result = validateOrdersAndResolveTurnFromTrustedOrders(
          game: gameForResolution,
          topology: init.combinedTopology,
          orders: mergedOrders,
          tileMapByRegion: init.tileMapByRegion,
          defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
          onProductionComplete: captureProductionComplete,
          onTurnTracePhase: phaseTraces.add,
          turnTraceRuntime: traceRuntime,
        );

        if (result is TurnResolutionComplete) {
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
          await exporter!.export(document);
        }
      }

      if (result is! TurnResolutionComplete) {
        _sessionLog.e(
          'observer:resolution_pending turn=${before.worldState.turnState.turnNumber} '
          'result=${result.runtimeType}',
        );
        return 3;
      }

      game = requireTurnResolutionComplete(result);

      final postTurn = game.worldState.turnState.turnNumber;
      final turnLabel = postTurn.toString().padLeft(6, '0');

      final writeSnapshot = requiredSnapshotTurns == null ||
          requiredSnapshotTurns.contains(postTurn);
      if (writeSnapshot) {
        final snap = buildObserverSnapshotJson(
          game,
          postResolutionTurnNumber: postTurn,
          tileMapByRegion: init.tileMapByRegion,
          lastTurnProductionByRecipeByPlayerId:
              lastTurnProductionByRecipeByPlayerId,
        );
        final snapshotText = encodeObserverSnapshotJson(snap);
        await writeTraceArtifact(
          before.id,
          'turn-$turnLabel.snapshot.json',
          snapshotText,
        );

        if (!minimalTraceMode) {
          await writeTraceArtifact(
            before.id,
            'turn-$turnLabel.html',
            renderObserverSnapshotHtml(snapshotText.trimRight()),
          );
        }
      }

      resolvedCount++;

      _sessionLog.i(
        'observer:turn_resolved count=$resolvedCount postTurn=$postTurn '
        'gameId=${game.id} minimalTrace=$minimalTraceMode',
      );
    }
  } on _ArtifactSizeCapExceeded {
    return kExitArtifactSizeCapExceeded;
  } on Object catch (e, st) {
    _sessionLog.e('observer:run_loop_failed', error: e, stackTrace: st);
    stderr.writeln('observer:run_loop_failed: $e');
    stderr.writeln(st);
    return 2;
  }

  final summaryDir = Directory('$traceRoot/${game.id}');
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
    if (minimalTraceMode) 'minimal_trace_mode': true,
  };

  final summaryText =
      '${const JsonEncoder.withIndent('  ').convert(summary)}\n';
  try {
    await writeTraceArtifact(game.id, 'run-summary.json', summaryText);
  } on _ArtifactSizeCapExceeded {
    return kExitArtifactSizeCapExceeded;
  }

  return 0;
}

class _ArtifactSizeCapExceeded implements Exception {}
