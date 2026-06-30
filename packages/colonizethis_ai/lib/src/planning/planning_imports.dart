// Shared planning-layer imports (Refs #2521). Only re-exports narrow logic contracts.
// The deterministic AI planning heuristics moved out of `colonizethis_logic`
// into the `colonizethis_ai_contracts` package (Refs #3290 C4); this hub
// re-exports the same narrow AI symbol set that `ai_api.dart` previously
// provided so dependent planners are unchanged.
export 'package:colonizethis_ai/package_logger.dart';
export 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart'
    show
        ColocatedFeedstockProspectIntraPassGates,
        colocatedMineralEligibleUnprospectedOldWorldFeedstockProspectIntraPassGates,
        FullAiCivilianWorkIdle,
        FullAiCivilianWorkSelectionResult,
        hasIdleExplorerUnit,
        ownsIdleExplorerColocatedWithMineralEligibleUnprospectedOldWorldFeedstockTile,
        ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile,
        ownsProspectedOldWorldMineralFeedstockTile,
        selectFullAiCivilianWorkOrders,
        selfLockRecoverySellerStageableImprovementInputs,
        sellerFeedstockTileAcquisitionTarget,
        sellerFeedstockTileAcquisitionTargetProvinceIdsSorted,
        sellerFeedstockTileAcquisitionTargetsAmongAcquirable,
        sellerNeedsImprovementInputFeedstockTileAcquisition,
        suggestsProspectForColocatedMineralEligibleUnprospectedOldWorldFeedstockTile,
        turnSeedForPlayer;
export 'package:colonizethis_data/colonizethis_data.dart';
export 'package:colonizethis_logic/ai_api.dart';
export 'package:colonizethis_models/colonizethis_models.dart';
