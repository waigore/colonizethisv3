import 'tech_catalog_cost.dart';
import 'tech_definition.dart';
import 'tech_ids.dart';

void addTechCatalogNewWorld(Map<String, TechDefinition> m) {
  // --- New World (28) ---
  m[kTechIdDiscoveryOfSugar] = TechDefinition(
    id: kTechIdDiscoveryOfSugar,
    era: 1,
    category: 'new-world',
    cost: techCatalogCostForTier(1),
    displayName: 'Discovery of Sugar',
    discoveryResourceIds: ['sugarCane'],
  );
  m[kTechIdSugarPlanting] = TechDefinition(
    id: kTechIdSugarPlanting,
    era: 1,
    category: 'new-world',
    cost: techCatalogCostForTier(1),
    displayName: 'Sugar Planting',
    prerequisiteIds: [kTechIdDiscoveryOfSugar],
  );
  m[kTechIdSugarRefining] = TechDefinition(
    id: kTechIdSugarRefining,
    era: 1,
    category: 'new-world',
    cost: techCatalogCostForTier(1),
    displayName: 'Sugar Refining',
    prerequisiteIds: [kTechIdDiscoveryOfSugar],
  );
  m[kTechIdLargeSugarPlantations] = TechDefinition(
    id: kTechIdLargeSugarPlantations,
    era: 2,
    category: 'new-world',
    cost: techCatalogCostForTier(2),
    displayName: 'Large Sugar Plantations',
    prerequisiteIds: [kTechIdSugarPlanting],
  );
  m[kTechIdSugarIndustry] = TechDefinition(
    id: kTechIdSugarIndustry,
    era: 3,
    category: 'new-world',
    cost: techCatalogCostForTier(3),
    displayName: 'Sugar Industry',
    prerequisiteIds: [kTechIdLargeSugarPlantations],
  );
  m[kTechIdDiscoveryOfTobacco] = TechDefinition(
    id: kTechIdDiscoveryOfTobacco,
    era: 1,
    category: 'new-world',
    cost: techCatalogCostForTier(1),
    displayName: 'Discovery of Tobacco',
    discoveryResourceIds: ['tobacco'],
  );
  m[kTechIdTobaccoPlanting] = TechDefinition(
    id: kTechIdTobaccoPlanting,
    era: 1,
    category: 'new-world',
    cost: techCatalogCostForTier(1),
    displayName: 'Tobacco Planting',
    prerequisiteIds: [kTechIdDiscoveryOfTobacco],
  );
  m[kTechIdCigarProduction] = TechDefinition(
    id: kTechIdCigarProduction,
    era: 1,
    category: 'new-world',
    cost: techCatalogCostForTier(1),
    displayName: 'Cigar Production',
    prerequisiteIds: [kTechIdDiscoveryOfTobacco],
  );
  m[kTechIdLargeTobaccoPlantations] = TechDefinition(
    id: kTechIdLargeTobaccoPlantations,
    era: 2,
    category: 'new-world',
    cost: techCatalogCostForTier(2),
    displayName: 'Large Tobacco Plantations',
    prerequisiteIds: [kTechIdTobaccoPlanting, kTechIdSeedDrill],
  );
  m[kTechIdTobaccoIndustry] = TechDefinition(
    id: kTechIdTobaccoIndustry,
    era: 3,
    category: 'new-world',
    cost: techCatalogCostForTier(3),
    displayName: 'Tobacco Industry',
    prerequisiteIds: [kTechIdEarlySteamEngine, kTechIdLargeTobaccoPlantations],
  );
  m[kTechIdDiscoveryOfCotton] = TechDefinition(
    id: kTechIdDiscoveryOfCotton,
    era: 1,
    category: 'new-world',
    cost: techCatalogCostForTier(1),
    displayName: 'Discovery of Cotton',
    discoveryResourceIds: ['cotton'],
  );
  m[kTechIdCottonPlanting] = TechDefinition(
    id: kTechIdCottonPlanting,
    era: 1,
    category: 'new-world',
    cost: techCatalogCostForTier(1),
    displayName: 'Cotton Planting',
    prerequisiteIds: [kTechIdDiscoveryOfCotton],
  );
  m[kTechIdCottonWeaving] = TechDefinition(
    id: kTechIdCottonWeaving,
    era: 1,
    category: 'new-world',
    cost: techCatalogCostForTier(1),
    displayName: 'Cotton Weaving',
    prerequisiteIds: [kTechIdDiscoveryOfCotton],
  );
  m[kTechIdLargeCottonPlantations] = TechDefinition(
    id: kTechIdLargeCottonPlantations,
    era: 2,
    category: 'new-world',
    cost: techCatalogCostForTier(2),
    displayName: 'Large Cotton Plantations',
    prerequisiteIds: [kTechIdCottonPlanting],
  );
  m[kTechIdCottonGin] = TechDefinition(
    id: kTechIdCottonGin,
    era: 3,
    category: 'new-world',
    cost: techCatalogCostForTier(3),
    displayName: 'Cotton Gin',
    prerequisiteIds: [kTechIdLargeCottonPlantations, kTechIdTrainedJourneymen],
  );
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
