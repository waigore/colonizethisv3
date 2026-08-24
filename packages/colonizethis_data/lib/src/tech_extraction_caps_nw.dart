/// New-World plantation and harvest extraction-cap rows.
/// SPEC/game/tech-and-extraction-cap.md.

import 'resource.dart';
import 'tech_ids.dart';

/// Sugar, tobacco, cotton, furs, and spices cap progression by tech.
final Map<String, Map<String, int>> extractionCapTableNwPlantationHarvest = {
  Resource.sugarCane.name: const {
    kTechIdSugarPlanting: 2,
    kTechIdLargeSugarPlantations: 3,
    kTechIdSugarIndustry: 4,
  },
  Resource.tobacco.name: const {
    kTechIdTobaccoPlanting: 2,
    kTechIdLargeTobaccoPlantations: 3,
    kTechIdTobaccoIndustry: 4,
  },
  Resource.cotton.name: const {
    kTechIdCottonPlanting: 2,
    kTechIdLargeCottonPlantations: 3,
    kTechIdCottonGin: 4,
  },
  Resource.furs.name: const {
    kTechIdImprovedTrappingTechniques: 2,
    kTechIdRiverboats: 3,
    kTechIdExcessiveFurHarvesting: 4,
  },
  Resource.spices.name: const {
    kTechIdImprovedSeaRoutes: 2,
    kTechIdLargeSpicePlantations: 3,
    kTechIdImprovedFoodPreservation: 4,
  },
};
