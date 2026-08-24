/// Precious-metal and precious-stone extraction-cap rows.
/// SPEC/game/tech-and-extraction-cap.md.

import 'resource.dart';
import 'tech_ids.dart';

/// Silver, gold, gems, and diamonds cap progression by mining tech.
final Map<String, Map<String, int>> extractionCapTablePrecious = {
  Resource.silver.name: const {
    kTechIdPreciousMetalsMining: 2,
    kTechIdExtractionOfPreciousMetals: 3,
    kTechIdAmalgamationProcess: 4,
  },
  Resource.gold.name: const {
    kTechIdPreciousMetalsMining: 2,
    kTechIdExtractionOfPreciousMetals: 3,
    kTechIdAmalgamationProcess: 4,
  },
  Resource.gems.name: const {
    kTechIdPreciousStoneMining: 2,
    kTechIdLargePreciousStoneMines: 3,
    kTechIdGeologicalProspecting: 4,
  },
  Resource.diamonds.name: const {
    kTechIdPreciousStoneMining: 2,
    kTechIdLargePreciousStoneMines: 3,
    kTechIdGeologicalProspecting: 4,
  },
};
