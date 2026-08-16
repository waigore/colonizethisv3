/// Attaches improvement-level and material-cost preview to a Development assign
/// candidate. Refs #4472.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'civilian_work_affordance.dart' show previewWorkOrderAffordAtTile;
import 'development_panel_assign_types.dart';
import 'order_work_constants.dart';

/// Copies [candidate] with level + `previewWorkOrderAffordAtTile` costs.
DevelopmentImproveAssignCandidate enrichDevelopmentImproveAssignCandidate({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required DevelopmentImproveAssignCandidate candidate,
}) {
  final preview = previewWorkOrderAffordAtTile(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
    workTarget: kWorkTargetBuildImprovement,
    targetTileKey: candidate.targetTileKey,
  );
  return DevelopmentImproveAssignCandidate(
    builderUnitId: candidate.builderUnitId,
    targetTileKey: candidate.targetTileKey,
    isCapitalConnected: candidate.isCapitalConnected,
    currentImprovementLevel: game.worldState.tileState.improvementLevel(
      candidate.targetTileKey,
    ),
    materialCosts: Map<String, int>.unmodifiable(
      preview.materialCosts ?? const <String, int>{},
    ),
    canAffordPreview: preview.canAfford,
  );
}
