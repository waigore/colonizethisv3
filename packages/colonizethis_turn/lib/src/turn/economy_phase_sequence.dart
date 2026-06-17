import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'phases/consumption_phase.dart';
import 'phases/extraction_phase.dart';
import 'phases/production_phase.dart';
import 'phases/riches_to_treasury_phase.dart';
import 'turn_pipeline_state.dart';
import 'turn_resolver_config.dart';

/// Inputs shared across economy phase steps for real and preview pipelines.
class EconomyPhaseStepContext {
  const EconomyPhaseStepContext({
    required this.topology,
    this.tileMapByRegion,
    this.extractedByPlayerId = const {},
    this.defaultAssignments = const [],
    this.defaultAssignmentsByPlayerId,
    this.onProductionComplete,
    this.applyPurchasedTileRichesHandoff = false,
    this.overseasShippedTonnageOut,
  });

  final MapTopology topology;
  final Map<String, TileMapResult>? tileMapByRegion;
  final Map<String, Map<CommodityId, int>> extractedByPlayerId;
  final List<AssignedRecipe> defaultAssignments;
  final Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId;
  final void Function(Map<String, Map<String, int>> productionByRecipeByPlayerId)?
  onProductionComplete;
  final bool applyPurchasedTileRichesHandoff;
  final Map<String, int>? overseasShippedTonnageOut;
}

EconomyPhaseStepContext economyPhaseStepContextFromConfig(
  TurnResolverConfig config, {
  Map<String, int>? overseasShippedTonnageOut,
  bool applyPurchasedTileRichesHandoff = false,
}) {
  return EconomyPhaseStepContext(
    topology: config.topology,
    tileMapByRegion: config.tileMapByRegion,
    extractedByPlayerId: config.extractedByPlayerId,
    defaultAssignments: config.defaultAssignments,
    defaultAssignmentsByPlayerId: config.defaultAssignmentsByPlayerId,
    onProductionComplete: config.onProductionComplete,
    applyPurchasedTileRichesHandoff: applyPurchasedTileRichesHandoff,
    overseasShippedTonnageOut: overseasShippedTonnageOut,
  );
}

typedef EconomyPhaseStepRunner =
    TurnPipelineState Function(
      TurnPipelineState acc,
      EconomyPhaseStepContext ctx,
    );

TurnPipelineState runEconomyExtractionStep(
  TurnPipelineState acc,
  EconomyPhaseStepContext ctx,
) {
  final nextGame = runExtractionPhase(
    acc.game,
    ctx.topology,
    ctx.tileMapByRegion,
    ctx.extractedByPlayerId,
    overseasShippedTonnageOut: ctx.overseasShippedTonnageOut,
  );
  if (ctx.overseasShippedTonnageOut != null) {
    return acc.copyWith(
      game: nextGame,
      overseasExtractionShippedTonnageByPlayerId: ctx.overseasShippedTonnageOut,
    );
  }
  return acc.copyWith(game: nextGame);
}

TurnPipelineState runEconomyRichesToTreasuryStep(
  TurnPipelineState acc,
  EconomyPhaseStepContext ctx,
) {
  var game = runRichesToTreasuryPhase(acc.game);
  if (ctx.applyPurchasedTileRichesHandoff) {
    game = applyPurchasedTileRichesHandoff(
      game,
      tileMapByRegion: ctx.tileMapByRegion,
    );
  }
  return acc.copyWith(game: game);
}

TurnPipelineState runEconomyConsumptionStep(
  TurnPipelineState acc,
  EconomyPhaseStepContext ctx,
) => runConsumptionPipelinePhase(acc);

TurnPipelineState runEconomyProductionStep(
  TurnPipelineState acc,
  EconomyPhaseStepContext ctx,
) => runProductionPipelinePhase(
  acc,
  ctx.defaultAssignments,
  ctx.defaultAssignmentsByPlayerId,
  ctx.onProductionComplete,
);

/// Ordered economy steps shared by the real pipeline handlers and preview callers.
const List<EconomyPhaseStepRunner> economyPhaseSteps = <EconomyPhaseStepRunner>[
  runEconomyExtractionStep,
  runEconomyRichesToTreasuryStep,
  runEconomyConsumptionStep,
  runEconomyProductionStep,
];

TurnPipelineState runEconomyPhaseSequence(
  TurnPipelineState acc,
  EconomyPhaseStepContext ctx,
) {
  var state = acc;
  for (final step in economyPhaseSteps) {
    state = step(state, ctx);
  }
  return state;
}
