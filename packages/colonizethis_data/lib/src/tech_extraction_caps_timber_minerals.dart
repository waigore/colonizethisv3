/// Timber and Old-World mineral extraction-cap rows.
/// SPEC/game/tech-and-extraction-cap.md.

import 'resource.dart';
import 'tech_ids.dart';

/// Timber, iron, copper, tin, and coal cap progression by gathering tech.
final Map<String, Map<String, int>> extractionCapTableTimberMinerals = {
  Resource.timber.name: const {
    kTechIdSawMill: 2,
    kTechIdWindSawMill: 3,
    kTechIdCircularSaw: 4,
  },
  Resource.iron.name: const {
    kTechIdIronMining: 2,
    kTechIdSteamInMining: 3,
    kTechIdIndustrialIronMining: 4,
  },
  Resource.copper.name: const {
    kTechIdCopperAndTinMining: 2,
    kTechIdLargeCopperAndTinMines: 3,
    kTechIdEfficientExtractionOfCopperAndTin: 4,
  },
  Resource.tin.name: const {
    kTechIdCopperAndTinMining: 2,
    kTechIdLargeCopperAndTinMines: 3,
    kTechIdEfficientExtractionOfCopperAndTin: 4,
  },
  Resource.coal.name: const {
    kTechIdCoalMining: 1,
    kTechIdSquareSetTimbering: 2,
    kTechIdLargeCoalMines: 3,
    kTechIdSafetyLamp: 4,
  },
};
