/// Old-World food and fibre extraction-cap rows.
/// SPEC/game/tech-and-extraction-cap.md.

import 'resource.dart';
import 'tech_ids.dart';

/// Grain, wool, and meat cap progression by gathering tech.
final Map<String, Map<String, int>> extractionCapTableOwFoodFibre = {
  Resource.grain.name: const {
    kTechIdLandEnclosure: 2,
    kTechIdSeedDrill: 3,
    kTechIdMoldboardPlow: 4,
  },
  Resource.wool.name: const {
    kTechIdSheepRanching: 2,
    kTechIdScientificSheepBreeding: 3,
  },
  Resource.meat.name: const {
    kTechIdAnimalHusbandry: 3,
    kTechIdScientificCattleBreeding: 4,
  },
};
