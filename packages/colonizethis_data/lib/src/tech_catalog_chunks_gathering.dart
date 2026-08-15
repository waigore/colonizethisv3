import 'tech_catalog_cost.dart';
import 'tech_definition.dart';
import 'tech_ids.dart';

void addTechCatalogGathering(Map<String, TechDefinition> m) {
  // --- Gathering (26) ---
  m[kTechIdCropRotation] = TechDefinition(
    id: kTechIdCropRotation,
    era: 1,
    category: 'gathering',
    cost: techCatalogCostForTier(1),
    displayName: 'Crop Rotation',
  );
  m[kTechIdSawMill] = TechDefinition(
    id: kTechIdSawMill,
    era: 1,
    category: 'gathering',
    cost: techCatalogCostForTier(1),
    displayName: 'Saw Mill',
  );
  m[kTechIdLandEnclosure] = TechDefinition(
    id: kTechIdLandEnclosure,
    era: 1,
    category: 'gathering',
    cost: techCatalogCostForTier(1),
    displayName: 'Land Enclosure',
  );
  m[kTechIdMineEngineering] = TechDefinition(
    id: kTechIdMineEngineering,
    era: 1,
    category: 'gathering',
    cost: techCatalogCostForTier(1),
    displayName: 'Mine Engineering',
  );
  m[kTechIdIronMining] = TechDefinition(
    id: kTechIdIronMining,
    era: 1,
    category: 'gathering',
    cost: techCatalogCostForTier(1),
    displayName: 'Iron Mining',
    prerequisiteIds: [kTechIdMineEngineering],
  );
  m[kTechIdCopperAndTinMining] = TechDefinition(
    id: kTechIdCopperAndTinMining,
    era: 1,
    category: 'gathering',
    cost: techCatalogCostForTier(1),
    displayName: 'Copper and Tin Mining',
    prerequisiteIds: [kTechIdMineEngineering],
  );
  m[kTechIdCoalMining] = TechDefinition(
    id: kTechIdCoalMining,
    era: 1,
    category: 'gathering',
    cost: techCatalogCostForTier(1),
    displayName: 'Coal Mining',
    prerequisiteIds: [kTechIdMineEngineering],
  );
  m[kTechIdWindSawMill] = TechDefinition(
    id: kTechIdWindSawMill,
    era: 2,
    category: 'gathering',
    cost: techCatalogCostForTier(2),
    displayName: 'Wind Saw Mill',
    prerequisiteIds: [kTechIdSawMill],
  );
  m[kTechIdSeedDrill] = TechDefinition(
    id: kTechIdSeedDrill,
    era: 2,
    category: 'gathering',
    cost: techCatalogCostForTier(2),
    displayName: 'Seed Drill',
    prerequisiteIds: [kTechIdLandEnclosure],
  );
  m[kTechIdSheepRanching] = TechDefinition(
    id: kTechIdSheepRanching,
    era: 2,
    category: 'gathering',
    cost: techCatalogCostForTier(2),
    displayName: 'Sheep Ranching',
    prerequisiteIds: [kTechIdCropRotation],
  );
  m[kTechIdAnimalHusbandry] = TechDefinition(
    id: kTechIdAnimalHusbandry,
    era: 2,
    category: 'gathering',
    cost: techCatalogCostForTier(2),
    displayName: 'Animal Husbandry',
    prerequisiteIds: [kTechIdCropRotation],
  );
  m[kTechIdSquareSetTimbering] = TechDefinition(
    id: kTechIdSquareSetTimbering,
    era: 2,
    category: 'gathering',
    cost: techCatalogCostForTier(2),
    displayName: 'Square-set Timbering',
    prerequisiteIds: [kTechIdCoalMining],
  );
  m[kTechIdSteamInMining] = TechDefinition(
    id: kTechIdSteamInMining,
    era: 2,
    category: 'gathering',
    cost: techCatalogCostForTier(2),
    displayName: 'Steam in Mining',
    prerequisiteIds: [kTechIdIronMining],
  );
  m[kTechIdLargeCoalMines] = TechDefinition(
    id: kTechIdLargeCoalMines,
    era: 2,
    category: 'gathering',
    cost: techCatalogCostForTier(2),
    displayName: 'Large Coal Mines',
    prerequisiteIds: [kTechIdSquareSetTimbering, kTechIdSteamInMining],
  );
  m[kTechIdLargeCopperAndTinMines] = TechDefinition(
    id: kTechIdLargeCopperAndTinMines,
    era: 2,
    category: 'gathering',
    cost: techCatalogCostForTier(2),
    displayName: 'Large Copper and Tin Mines',
    prerequisiteIds: [kTechIdCopperAndTinMining],
  );
  m[kTechIdCircularSaw] = TechDefinition(
    id: kTechIdCircularSaw,
    era: 3,
    category: 'gathering',
    cost: techCatalogCostForTier(3),
    displayName: 'Circular Saw',
    prerequisiteIds: [kTechIdWindSawMill, kTechIdUniversity],
  );
  m[kTechIdScientificSheepBreeding] = TechDefinition(
    id: kTechIdScientificSheepBreeding,
    era: 3,
    category: 'gathering',
    cost: techCatalogCostForTier(3),
    displayName: 'Scientific Sheep Breeding',
    prerequisiteIds: [kTechIdSheepRanching, kTechIdUniversity],
  );
  m[kTechIdScientificCattleBreeding] = TechDefinition(
    id: kTechIdScientificCattleBreeding,
    era: 3,
    category: 'gathering',
    cost: techCatalogCostForTier(3),
    displayName: 'Scientific Cattle Breeding',
    prerequisiteIds: [kTechIdAnimalHusbandry, kTechIdUniversity],
  );
  m[kTechIdMoldboardPlow] = TechDefinition(
    id: kTechIdMoldboardPlow,
    era: 3,
    category: 'gathering',
    cost: techCatalogCostForTier(3),
    displayName: 'Moldboard Plow',
    prerequisiteIds: [kTechIdSeedDrill],
  );
  m[kTechIdSafetyLamp] = TechDefinition(
    id: kTechIdSafetyLamp,
    era: 4,
    category: 'gathering',
    cost: techCatalogCostForTier(4),
    displayName: 'Safety Lamp',
    prerequisiteIds: [kTechIdLargeCoalMines, kTechIdDynamite],
  );
  m[kTechIdLargePreciousStoneMines] = TechDefinition(
    id: kTechIdLargePreciousStoneMines,
    era: 3,
    category: 'gathering',
    cost: techCatalogCostForTier(3),
    displayName: 'Large Precious Stone Mines',
    prerequisiteIds: [kTechIdPreciousStoneMining, kTechIdUniversity],
  );
  m[kTechIdExtractionOfPreciousMetals] = TechDefinition(
    id: kTechIdExtractionOfPreciousMetals,
    era: 3,
    category: 'gathering',
    cost: techCatalogCostForTier(3),
    displayName: 'Extraction of Precious Metals',
    prerequisiteIds: [kTechIdPreciousMetalsMining, kTechIdUniversity],
  );
  m[kTechIdGeologicalProspecting] = TechDefinition(
    id: kTechIdGeologicalProspecting,
    era: 4,
    category: 'gathering',
    cost: techCatalogCostForTier(4),
    displayName: 'Geological Prospecting',
    prerequisiteIds: [kTechIdLargePreciousStoneMines, kTechIdDynamite],
  );
  m[kTechIdAmalgamationProcess] = TechDefinition(
    id: kTechIdAmalgamationProcess,
    era: 4,
    category: 'gathering',
    cost: techCatalogCostForTier(4),
    displayName: 'Amalgamation Process',
    prerequisiteIds: [kTechIdDynamite, kTechIdExtractionOfPreciousMetals],
  );
  m[kTechIdIndustrialIronMining] = TechDefinition(
    id: kTechIdIndustrialIronMining,
    era: 4,
    category: 'gathering',
    cost: techCatalogCostForTier(4),
    displayName: 'Industrial Iron Mining',
    prerequisiteIds: [kTechIdIndustrialFundingOfResearch, kTechIdSteamInMining],
  );
  m[kTechIdEfficientExtractionOfCopperAndTin] = TechDefinition(
    id: kTechIdEfficientExtractionOfCopperAndTin,
    era: 4,
    category: 'gathering',
    cost: techCatalogCostForTier(4),
    displayName: 'Efficient Extraction of Copper & Tin',
    prerequisiteIds: [kTechIdLargeCoalMines, kTechIdLargeCopperAndTinMines],
  );
}
