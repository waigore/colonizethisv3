import 'tech_catalog_cost.dart';
import 'tech_definition.dart';
import 'tech_ids.dart';

void addTechCatalogNewWorldHarvestAndOre(Map<String, TechDefinition> m) {
  // --- New World harvest and ore: furs, spices, precious metals/gems (13) ---
  m[kTechIdDiscoveryOfFurs] = TechDefinition(
    id: kTechIdDiscoveryOfFurs,
    era: 1,
    category: 'new-world',
    cost: techCatalogCostForTier(1),
    displayName: 'Discovery of Furs',
    discoveryResourceIds: ['furs'],
  );
  m[kTechIdImprovedTrappingTechniques] = TechDefinition(
    id: kTechIdImprovedTrappingTechniques,
    era: 1,
    category: 'new-world',
    cost: techCatalogCostForTier(1),
    displayName: 'Improved Trapping Techniques',
    prerequisiteIds: [kTechIdDiscoveryOfFurs],
  );
  m[kTechIdHatProduction] = TechDefinition(
    id: kTechIdHatProduction,
    era: 1,
    category: 'new-world',
    cost: techCatalogCostForTier(1),
    displayName: 'Hat Production',
    prerequisiteIds: [kTechIdDiscoveryOfFurs],
  );
  m[kTechIdRiverboats] = TechDefinition(
    id: kTechIdRiverboats,
    era: 3,
    category: 'new-world',
    cost: techCatalogCostForTier(3),
    displayName: 'Riverboats',
    prerequisiteIds: [
      kTechIdImprovedTrappingTechniques,
      kTechIdEarlySteamEngine,
    ],
  );
  m[kTechIdExcessiveFurHarvesting] = TechDefinition(
    id: kTechIdExcessiveFurHarvesting,
    era: 4,
    category: 'new-world',
    cost: techCatalogCostForTier(4),
    displayName: 'Excessive Fur Harvesting',
    prerequisiteIds: [kTechIdLaterSteamEngine, kTechIdRiverboats],
  );
  m[kTechIdDiscoveryOfSpices] = TechDefinition(
    id: kTechIdDiscoveryOfSpices,
    era: 1,
    category: 'new-world',
    cost: techCatalogCostForTier(1),
    displayName: 'Discovery of Spices',
    discoveryResourceIds: ['spices'],
  );
  m[kTechIdImprovedSeaRoutes] = TechDefinition(
    id: kTechIdImprovedSeaRoutes,
    era: 1,
    category: 'new-world',
    cost: techCatalogCostForTier(1),
    displayName: 'Improved Sea Routes',
    prerequisiteIds: [kTechIdDiscoveryOfSpices],
  );
  m[kTechIdLargeSpicePlantations] = TechDefinition(
    id: kTechIdLargeSpicePlantations,
    era: 2,
    category: 'new-world',
    cost: techCatalogCostForTier(2),
    displayName: 'Large Spice Plantations',
    prerequisiteIds: [kTechIdSeedDrill, kTechIdImprovedSeaRoutes],
  );
  m[kTechIdImprovedFoodPreservation] = TechDefinition(
    id: kTechIdImprovedFoodPreservation,
    era: 3,
    category: 'new-world',
    cost: techCatalogCostForTier(3),
    displayName: 'Improved Food Preservation',
    prerequisiteIds: [kTechIdLargeSpicePlantations],
  );
  m[kTechIdDiscoveryOfGoldOrSilver] = TechDefinition(
    id: kTechIdDiscoveryOfGoldOrSilver,
    era: 1,
    category: 'new-world',
    cost: techCatalogCostForTier(1),
    displayName: 'Discovery of Gold or Silver',
    discoveryResourceIds: ['gold', 'silver'],
  );
  m[kTechIdPreciousMetalsMining] = TechDefinition(
    id: kTechIdPreciousMetalsMining,
    era: 1,
    category: 'new-world',
    cost: techCatalogCostForTier(1),
    displayName: 'Precious Metals Mining',
    prerequisiteIds: [kTechIdDiscoveryOfGoldOrSilver, kTechIdMineEngineering],
  );
  m[kTechIdDiscoveryOfGemsOrDiamonds] = TechDefinition(
    id: kTechIdDiscoveryOfGemsOrDiamonds,
    era: 1,
    category: 'new-world',
    cost: techCatalogCostForTier(1),
    displayName: 'Discovery of Gems or Diamonds',
    discoveryResourceIds: ['gems', 'diamonds'],
  );
  m[kTechIdPreciousStoneMining] = TechDefinition(
    id: kTechIdPreciousStoneMining,
    era: 1,
    category: 'new-world',
    cost: techCatalogCostForTier(1),
    displayName: 'Precious Stone Mining',
    prerequisiteIds: [kTechIdDiscoveryOfGemsOrDiamonds],
  );
}
