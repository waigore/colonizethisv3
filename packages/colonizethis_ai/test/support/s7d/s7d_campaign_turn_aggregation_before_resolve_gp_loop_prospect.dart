// Supplier prospect-localization stage of the S7-D before-resolve GP loop (Refs #4602 Slice E).

import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart'
    show
        hasIdleExplorerUnit,
        ownsIdleExplorerColocatedWithMineralEligibleUnprospectedOldWorldFeedstockTile,
        ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile,
        ownsProspectedOldWorldMineralFeedstockTile,
        colocatedMineralEligibleUnprospectedOldWorldFeedstockProspectIntraPassGates,
        suggestsProspectForColocatedMineralEligibleUnprospectedOldWorldFeedstockTile;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 's7d_campaign_rollup.dart';

extension Seed42S7dCampaignTurnAggregationBeforeResolveProspect
    on Seed42S7dCampaignRollup {
  void recordBeforeResolveSupplierProspectCounters({
    required Game game,
    required MapTopology topology,
    required Map<String, TileMapResult> tileMap,
    required String gpId,
    required PlayerView view,
  }) {
    if (hasIdleExplorerUnit(game, gpId)) {
      supplierIdleExplorerPresentTurns[gpId] =
          (supplierIdleExplorerPresentTurns[gpId] ?? 0) + 1;
    }
    if (ownsProspectedOldWorldMineralFeedstockTile(
      game,
      gpId,
      castIronFeedstockIds,
    )) {
      supplierProspectedMineralFeedstockTileTurns[gpId] =
          (supplierProspectedMineralFeedstockTileTurns[gpId] ?? 0) + 1;
    }
    if (ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile(
      game,
      gpId,
      castIronFeedstockIds,
    )) {
      supplierIdleExplorerColocatedFeedstockTileTurns[gpId] =
          (supplierIdleExplorerColocatedFeedstockTileTurns[gpId] ?? 0) + 1;
    }
    if (ownsIdleExplorerColocatedWithMineralEligibleUnprospectedOldWorldFeedstockTile(
      game,
      gpId,
      castIronFeedstockIds,
      tileMap,
    )) {
      supplierIdleExplorerColocatedMineralEligibleFeedstockTileTurns[gpId] =
          (supplierIdleExplorerColocatedMineralEligibleFeedstockTileTurns[gpId] ??
              0) +
          1;
    }
    if (suggestsProspectForColocatedMineralEligibleUnprospectedOldWorldFeedstockTile(
      game,
      topology,
      view,
      gpId,
      castIronFeedstockIds,
      tileMap,
    )) {
      supplierIdleExplorerColocatedSuggestedProspectTileTurns[gpId] =
          (supplierIdleExplorerColocatedSuggestedProspectTileTurns[gpId] ?? 0) +
          1;
    }
    final intraPassGates =
        colocatedMineralEligibleUnprospectedOldWorldFeedstockProspectIntraPassGates(
          game: game,
          topology: topology,
          view: view,
          playerId: gpId,
          feedstockIds: castIronFeedstockIds,
          tileMapByRegion: tileMap,
        );
    if (intraPassGates.provinceFoggedVisibility) {
      supplierIdleExplorerColocatedFeedstockProspectProvinceVisibleTurns[gpId] =
          (supplierIdleExplorerColocatedFeedstockProspectProvinceVisibleTurns[gpId] ??
              0) +
          1;
    }
    if (intraPassGates.bundledMoveLeg) {
      supplierIdleExplorerColocatedFeedstockProspectBundledMoveLegTurns[gpId] =
          (supplierIdleExplorerColocatedFeedstockProspectBundledMoveLegTurns[gpId] ??
              0) +
          1;
    }
    if (intraPassGates.validatorAccepted) {
      supplierIdleExplorerColocatedFeedstockProspectValidatorTurns[gpId] =
          (supplierIdleExplorerColocatedFeedstockProspectValidatorTurns[gpId] ??
              0) +
          1;
    }
  }
}
