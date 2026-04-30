/// Full tech catalog (113 techs). SPEC/game/tech-tree.md and category sub-docs.
/// Imported by tech_extraction.dart. Do not export; use colonizethis_data public API.

import 'tech_definition.dart';
import 'tech_ids.dart';




part 'tech_catalog_chunks.dart';

int _cost(int era) => 80 + era * 40; // 120, 160, 200, 240 for era 1-4

/// Full catalog: 113 techs with displayName, prerequisiteIds, discoveryResourceIds (7 discovery techs), regimentUnlockIds, shipUnlockIds.

Map<String, TechDefinition> buildTechCatalog() {
  final m = <String, TechDefinition>{};

  _addTechCatalogChunk1(m);
  _addTechCatalogChunk2(m);
  _addTechCatalogChunk3(m);
  _addTechCatalogChunk4(m);
  _addTechCatalogChunk5(m);
  _addTechCatalogChunk6(m);
  _addTechCatalogChunk7(m);

  return m;
}

void _addTechCatalogChunk1(Map<String, TechDefinition> m) {

  // --- Gathering (26) ---
  m[kTechIdCropRotation] = TechDefinition(
    id: kTechIdCropRotation,
    era: 1,
    category: 'gathering',
    cost: _cost(1),
    displayName: 'Crop Rotation',
  );
  m[kTechIdSawMill] = TechDefinition(
    id: kTechIdSawMill,
    era: 1,
    category: 'gathering',
    cost: _cost(1),
    displayName: 'Saw Mill',
  );
  m[kTechIdLandEnclosure] = TechDefinition(
    id: kTechIdLandEnclosure,
    era: 1,
    category: 'gathering',
    cost: _cost(1),
    displayName: 'Land Enclosure',
  );
  m[kTechIdMineEngineering] = TechDefinition(
    id: kTechIdMineEngineering,
    era: 1,
    category: 'gathering',
    cost: _cost(1),
    displayName: 'Mine Engineering',
  );
  m[kTechIdIronMining] = TechDefinition(
    id: kTechIdIronMining,
    era: 1,
    category: 'gathering',
    cost: _cost(1),
    displayName: 'Iron Mining',
    prerequisiteIds: [kTechIdMineEngineering],
  );
  m[kTechIdCopperAndTinMining] = TechDefinition(
    id: kTechIdCopperAndTinMining,
    era: 1,
    category: 'gathering',
    cost: _cost(1),
    displayName: 'Copper and Tin Mining',
    prerequisiteIds: [kTechIdMineEngineering],
  );
  m[kTechIdCoalMining] = TechDefinition(
    id: kTechIdCoalMining,
    era: 1,
    category: 'gathering',
    cost: _cost(1),
    displayName: 'Coal Mining',
    prerequisiteIds: [kTechIdMineEngineering],
  );
  m[kTechIdWindSawMill] = TechDefinition(
    id: kTechIdWindSawMill,
    era: 2,
    category: 'gathering',
    cost: _cost(2),
    displayName: 'Wind Saw Mill',
    prerequisiteIds: [kTechIdSawMill],
  );
  m[kTechIdSeedDrill] = TechDefinition(
    id: kTechIdSeedDrill,
    era: 2,
    category: 'gathering',
    cost: _cost(2),
    displayName: 'Seed Drill',
    prerequisiteIds: [kTechIdLandEnclosure],
  );
  m[kTechIdSheepRanching] = TechDefinition(
    id: kTechIdSheepRanching,
    era: 2,
    category: 'gathering',
    cost: _cost(2),
    displayName: 'Sheep Ranching',
    prerequisiteIds: [kTechIdCropRotation],
  );
  m[kTechIdAnimalHusbandry] = TechDefinition(
    id: kTechIdAnimalHusbandry,
    era: 2,
    category: 'gathering',
    cost: _cost(2),
    displayName: 'Animal Husbandry',
    prerequisiteIds: [kTechIdCropRotation],
  );
  m[kTechIdSquareSetTimbering] = TechDefinition(
    id: kTechIdSquareSetTimbering,
    era: 2,
    category: 'gathering',
    cost: _cost(2),
    displayName: 'Square-set Timbering',
    prerequisiteIds: [kTechIdCoalMining],
  );
  m[kTechIdSteamInMining] = TechDefinition(
    id: kTechIdSteamInMining,
    era: 2,
    category: 'gathering',
    cost: _cost(2),
    displayName: 'Steam in Mining',
    prerequisiteIds: [kTechIdIronMining],
  );
  m[kTechIdLargeCoalMines] = TechDefinition(
    id: kTechIdLargeCoalMines,
    era: 2,
    category: 'gathering',
    cost: _cost(2),
    displayName: 'Large Coal Mines',
    prerequisiteIds: [kTechIdSquareSetTimbering, kTechIdSteamInMining],
  );
  m[kTechIdLargeCopperAndTinMines] = TechDefinition(
    id: kTechIdLargeCopperAndTinMines,
    era: 2,
    category: 'gathering',
    cost: _cost(2),
    displayName: 'Large Copper and Tin Mines',
    prerequisiteIds: [kTechIdCopperAndTinMining],
  );
  m[kTechIdCircularSaw] = TechDefinition(
    id: kTechIdCircularSaw,
    era: 3,
    category: 'gathering',
    cost: _cost(3),
    displayName: 'Circular Saw',
    prerequisiteIds: [kTechIdWindSawMill, kTechIdUniversity],
  );
  m[kTechIdScientificSheepBreeding] = TechDefinition(
    id: kTechIdScientificSheepBreeding,
    era: 3,
    category: 'gathering',
    cost: _cost(3),
    displayName: 'Scientific Sheep Breeding',
    prerequisiteIds: [kTechIdSheepRanching, kTechIdUniversity],
  );
  m[kTechIdScientificCattleBreeding] = TechDefinition(
    id: kTechIdScientificCattleBreeding,
    era: 3,
    category: 'gathering',
    cost: _cost(3),
    displayName: 'Scientific Cattle Breeding',
    prerequisiteIds: [kTechIdAnimalHusbandry, kTechIdUniversity],
  );
  m[kTechIdMoldboardPlow] = TechDefinition(
    id: kTechIdMoldboardPlow,
    era: 3,
    category: 'gathering',
    cost: _cost(3),
    displayName: 'Moldboard Plow',
    prerequisiteIds: [kTechIdSeedDrill],
  );
  m[kTechIdSafetyLamp] = TechDefinition(
    id: kTechIdSafetyLamp,
    era: 4,
    category: 'gathering',
    cost: _cost(4),
    displayName: 'Safety Lamp',
    prerequisiteIds: [kTechIdLargeCoalMines, kTechIdDynamite],
  );
  m[kTechIdLargePreciousStoneMines] = TechDefinition(
    id: kTechIdLargePreciousStoneMines,
    era: 3,
    category: 'gathering',
    cost: _cost(3),
    displayName: 'Large Precious Stone Mines',
    prerequisiteIds: [kTechIdPreciousStoneMining, kTechIdUniversity],
  );
}

void _addTechCatalogChunk2(Map<String, TechDefinition> m) {
  m[kTechIdExtractionOfPreciousMetals] = TechDefinition(
    id: kTechIdExtractionOfPreciousMetals,
    era: 3,
    category: 'gathering',
    cost: _cost(3),
    displayName: 'Extraction of Precious Metals',
    prerequisiteIds: [kTechIdPreciousMetalsMining, kTechIdUniversity],
  );
  m[kTechIdGeologicalProspecting] = TechDefinition(
    id: kTechIdGeologicalProspecting,
    era: 4,
    category: 'gathering',
    cost: _cost(4),
    displayName: 'Geological Prospecting',
    prerequisiteIds: [kTechIdLargePreciousStoneMines, kTechIdDynamite],
  );
  m[kTechIdAmalgamationProcess] = TechDefinition(
    id: kTechIdAmalgamationProcess,
    era: 4,
    category: 'gathering',
    cost: _cost(4),
    displayName: 'Amalgamation Process',
    prerequisiteIds: [kTechIdDynamite, kTechIdExtractionOfPreciousMetals],
  );
  m[kTechIdIndustrialIronMining] = TechDefinition(
    id: kTechIdIndustrialIronMining,
    era: 4,
    category: 'gathering',
    cost: _cost(4),
    displayName: 'Industrial Iron Mining',
    prerequisiteIds: [kTechIdIndustrialFundingOfResearch, kTechIdSteamInMining],
  );
  m[kTechIdEfficientExtractionOfCopperAndTin] = TechDefinition(
    id: kTechIdEfficientExtractionOfCopperAndTin,
    era: 4,
    category: 'gathering',
    cost: _cost(4),
    displayName: 'Efficient Extraction of Copper & Tin',
    prerequisiteIds: [kTechIdLargeCoalMines, kTechIdLargeCopperAndTinMines],
  );

  // --- New World (28) ---
  m[kTechIdDiscoveryOfSugar] = TechDefinition(
    id: kTechIdDiscoveryOfSugar,
    era: 1,
    category: 'new-world',
    cost: _cost(1),
    displayName: 'Discovery of Sugar',
    discoveryResourceIds: ['sugarCane'],
  );
  m[kTechIdSugarPlanting] = TechDefinition(
    id: kTechIdSugarPlanting,
    era: 1,
    category: 'new-world',
    cost: _cost(1),
    displayName: 'Sugar Planting',
    prerequisiteIds: [kTechIdDiscoveryOfSugar],
  );
  m[kTechIdSugarRefining] = TechDefinition(
    id: kTechIdSugarRefining,
    era: 1,
    category: 'new-world',
    cost: _cost(1),
    displayName: 'Sugar Refining',
    prerequisiteIds: [kTechIdDiscoveryOfSugar],
  );
  m[kTechIdLargeSugarPlantations] = TechDefinition(
    id: kTechIdLargeSugarPlantations,
    era: 2,
    category: 'new-world',
    cost: _cost(2),
    displayName: 'Large Sugar Plantations',
    prerequisiteIds: [kTechIdSugarPlanting],
  );
  m[kTechIdSugarIndustry] = TechDefinition(
    id: kTechIdSugarIndustry,
    era: 3,
    category: 'new-world',
    cost: _cost(3),
    displayName: 'Sugar Industry',
    prerequisiteIds: [kTechIdLargeSugarPlantations],
  );
  m[kTechIdDiscoveryOfTobacco] = TechDefinition(
    id: kTechIdDiscoveryOfTobacco,
    era: 1,
    category: 'new-world',
    cost: _cost(1),
    displayName: 'Discovery of Tobacco',
    discoveryResourceIds: ['tobacco'],
  );
  m[kTechIdTobaccoPlanting] = TechDefinition(
    id: kTechIdTobaccoPlanting,
    era: 1,
    category: 'new-world',
    cost: _cost(1),
    displayName: 'Tobacco Planting',
    prerequisiteIds: [kTechIdDiscoveryOfTobacco],
  );
  m[kTechIdCigarProduction] = TechDefinition(
    id: kTechIdCigarProduction,
    era: 1,
    category: 'new-world',
    cost: _cost(1),
    displayName: 'Cigar Production',
    prerequisiteIds: [kTechIdDiscoveryOfTobacco],
  );
  m[kTechIdLargeTobaccoPlantations] = TechDefinition(
    id: kTechIdLargeTobaccoPlantations,
    era: 2,
    category: 'new-world',
    cost: _cost(2),
    displayName: 'Large Tobacco Plantations',
    prerequisiteIds: [kTechIdTobaccoPlanting, kTechIdSeedDrill],
  );
  m[kTechIdTobaccoIndustry] = TechDefinition(
    id: kTechIdTobaccoIndustry,
    era: 3,
    category: 'new-world',
    cost: _cost(3),
    displayName: 'Tobacco Industry',
    prerequisiteIds: [kTechIdEarlySteamEngine, kTechIdLargeTobaccoPlantations],
  );
  m[kTechIdDiscoveryOfCotton] = TechDefinition(
    id: kTechIdDiscoveryOfCotton,
    era: 1,
    category: 'new-world',
    cost: _cost(1),
    displayName: 'Discovery of Cotton',
    discoveryResourceIds: ['cotton'],
  );
  m[kTechIdCottonPlanting] = TechDefinition(
    id: kTechIdCottonPlanting,
    era: 1,
    category: 'new-world',
    cost: _cost(1),
    displayName: 'Cotton Planting',
    prerequisiteIds: [kTechIdDiscoveryOfCotton],
  );
  m[kTechIdCottonWeaving] = TechDefinition(
    id: kTechIdCottonWeaving,
    era: 1,
    category: 'new-world',
    cost: _cost(1),
    displayName: 'Cotton Weaving',
    prerequisiteIds: [kTechIdDiscoveryOfCotton],
  );
  m[kTechIdLargeCottonPlantations] = TechDefinition(
    id: kTechIdLargeCottonPlantations,
    era: 2,
    category: 'new-world',
    cost: _cost(2),
    displayName: 'Large Cotton Plantations',
    prerequisiteIds: [kTechIdCottonPlanting],
  );
  m[kTechIdCottonGin] = TechDefinition(
    id: kTechIdCottonGin,
    era: 3,
    category: 'new-world',
    cost: _cost(3),
    displayName: 'Cotton Gin',
    prerequisiteIds: [kTechIdLargeCottonPlantations, kTechIdTrainedJourneymen],
  );
}

void _addTechCatalogChunk3(Map<String, TechDefinition> m) {
  m[kTechIdDiscoveryOfFurs] = TechDefinition(
    id: kTechIdDiscoveryOfFurs,
    era: 1,
    category: 'new-world',
    cost: _cost(1),
    displayName: 'Discovery of Furs',
    discoveryResourceIds: ['furs'],
  );
  m[kTechIdImprovedTrappingTechniques] = TechDefinition(
    id: kTechIdImprovedTrappingTechniques,
    era: 1,
    category: 'new-world',
    cost: _cost(1),
    displayName: 'Improved Trapping Techniques',
    prerequisiteIds: [kTechIdDiscoveryOfFurs],
  );
  m[kTechIdHatProduction] = TechDefinition(
    id: kTechIdHatProduction,
    era: 1,
    category: 'new-world',
    cost: _cost(1),
    displayName: 'Hat Production',
    prerequisiteIds: [kTechIdDiscoveryOfFurs],
  );
  m[kTechIdRiverboats] = TechDefinition(
    id: kTechIdRiverboats,
    era: 3,
    category: 'new-world',
    cost: _cost(3),
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
    cost: _cost(4),
    displayName: 'Excessive Fur Harvesting',
    prerequisiteIds: [kTechIdLaterSteamEngine, kTechIdRiverboats],
  );
  m[kTechIdDiscoveryOfSpices] = TechDefinition(
    id: kTechIdDiscoveryOfSpices,
    era: 1,
    category: 'new-world',
    cost: _cost(1),
    displayName: 'Discovery of Spices',
    discoveryResourceIds: ['spices'],
  );
  m[kTechIdImprovedSeaRoutes] = TechDefinition(
    id: kTechIdImprovedSeaRoutes,
    era: 1,
    category: 'new-world',
    cost: _cost(1),
    displayName: 'Improved Sea Routes',
    prerequisiteIds: [kTechIdDiscoveryOfSpices],
  );
  m[kTechIdLargeSpicePlantations] = TechDefinition(
    id: kTechIdLargeSpicePlantations,
    era: 2,
    category: 'new-world',
    cost: _cost(2),
    displayName: 'Large Spice Plantations',
    prerequisiteIds: [kTechIdSeedDrill, kTechIdImprovedSeaRoutes],
  );
  m[kTechIdImprovedFoodPreservation] = TechDefinition(
    id: kTechIdImprovedFoodPreservation,
    era: 3,
    category: 'new-world',
    cost: _cost(3),
    displayName: 'Improved Food Preservation',
    prerequisiteIds: [kTechIdLargeSpicePlantations],
  );
  m[kTechIdDiscoveryOfGoldOrSilver] = TechDefinition(
    id: kTechIdDiscoveryOfGoldOrSilver,
    era: 1,
    category: 'new-world',
    cost: _cost(1),
    displayName: 'Discovery of Gold or Silver',
    discoveryResourceIds: ['gold', 'silver'],
  );
  m[kTechIdPreciousMetalsMining] = TechDefinition(
    id: kTechIdPreciousMetalsMining,
    era: 1,
    category: 'new-world',
    cost: _cost(1),
    displayName: 'Precious Metals Mining',
    prerequisiteIds: [kTechIdDiscoveryOfGoldOrSilver, kTechIdMineEngineering],
  );
  m[kTechIdDiscoveryOfGemsOrDiamonds] = TechDefinition(
    id: kTechIdDiscoveryOfGemsOrDiamonds,
    era: 1,
    category: 'new-world',
    cost: _cost(1),
    displayName: 'Discovery of Gems or Diamonds',
    discoveryResourceIds: ['gems', 'diamonds'],
  );
  m[kTechIdPreciousStoneMining] = TechDefinition(
    id: kTechIdPreciousStoneMining,
    era: 1,
    category: 'new-world',
    cost: _cost(1),
    displayName: 'Precious Stone Mining',
    prerequisiteIds: [kTechIdDiscoveryOfGemsOrDiamonds],
  );

  // --- Transport (4) ---
  m[kTechIdRoadConstruction] = TechDefinition(
    id: kTechIdRoadConstruction,
    era: 1,
    category: 'transport',
    cost: _cost(1),
    displayName: 'Road Construction',
    prerequisiteIds: [kTechIdSawMill, kTechIdLandEnclosure, kTechIdIronMining],
  );
  m[kTechIdEarlySteamEngine] = TechDefinition(
    id: kTechIdEarlySteamEngine,
    era: 2,
    category: 'transport',
    cost: _cost(2),
    displayName: 'Early Steam Engine',
    prerequisiteIds: [
      kTechIdRoadConstruction,
      kTechIdSquareSetTimbering,
      kTechIdSteamInMining,
    ],
  );
  m[kTechIdLaterSteamEngine] = TechDefinition(
    id: kTechIdLaterSteamEngine,
    era: 3,
    category: 'transport',
    cost: _cost(3),
    displayName: 'Later Steam Engine',
    prerequisiteIds: [kTechIdEarlySteamEngine, kTechIdCrucibleProcess],
  );
  m[kTechIdDynamite] = TechDefinition(
    id: kTechIdDynamite,
    era: 4,
    category: 'transport',
    cost: _cost(4),
    displayName: 'Dynamite',
    prerequisiteIds: [
      kTechIdLaterSteamEngine,
      kTechIdBanking,
      kTechIdExplosives,
    ],
  );

  // --- Labour (8) ---
  m[kTechIdPrintingPress] = TechDefinition(
    id: kTechIdPrintingPress,
    era: 1,
    category: 'labour',
    cost: _cost(1),
    displayName: 'Printing Press',
    prerequisiteIds: [kTechIdSawMill],
  );
  m[kTechIdApprenticeWorkers] = TechDefinition(
    id: kTechIdApprenticeWorkers,
    era: 2,
    category: 'labour',
    cost: _cost(2),
    displayName: 'Apprentice Workers',
    prerequisiteIds: [kTechIdLandEnclosure, kTechIdSugarRefining],
  );
}

void _addTechCatalogChunk4(Map<String, TechDefinition> m) {
  m[kTechIdTrainedJourneymen] = TechDefinition(
    id: kTechIdTrainedJourneymen,
    era: 2,
    category: 'labour',
    cost: _cost(2),
    displayName: 'Trained Journeymen',
    prerequisiteIds: [kTechIdCigarProduction, kTechIdPrintingPress],
  );
  m[kTechIdMasterArtisans] = TechDefinition(
    id: kTechIdMasterArtisans,
    era: 3,
    category: 'labour',
    cost: _cost(3),
    displayName: 'Master Artisans',
    prerequisiteIds: [
      kTechIdApprenticeWorkers,
      kTechIdUniversity,
      kTechIdHatProduction,
    ],
  );
  m[kTechIdMoneyLending] = TechDefinition(
    id: kTechIdMoneyLending,
    era: 1,
    category: 'labour',
    cost: _cost(1),
    displayName: 'Money Lending',
    prerequisiteIds: [kTechIdLandEnclosure],
  );
  m[kTechIdBanking] = TechDefinition(
    id: kTechIdBanking,
    era: 3,
    category: 'labour',
    cost: _cost(3),
    displayName: 'Banking',
    prerequisiteIds: [kTechIdMasterArtisans, kTechIdTradeFairs],
  );
  m[kTechIdTradeFairs] = TechDefinition(
    id: kTechIdTradeFairs,
    era: 2,
    category: 'labour',
    cost: _cost(2),
    displayName: 'Trade Fairs',
    prerequisiteIds: [kTechIdMerchantCompanies, kTechIdSugarRefining],
  );
  m[kTechIdUniversity] = TechDefinition(
    id: kTechIdUniversity,
    era: 3,
    category: 'labour',
    cost: _cost(3),
    displayName: 'University',
    prerequisiteIds: [
      kTechIdMoneyLending,
      kTechIdApprenticeWorkers,
      kTechIdPrintingPress,
    ],
  );

  // --- Diplomacy / Civilian (6) ---
  m[kTechIdDiplomaticExpertise] = TechDefinition(
    id: kTechIdDiplomaticExpertise,
    era: 1,
    category: 'diplomacy',
    cost: _cost(1),
    displayName: 'Diplomatic Expertise',
  );
  m[kTechIdMerchantCompanies] = TechDefinition(
    id: kTechIdMerchantCompanies,
    era: 1,
    category: 'civilian',
    cost: _cost(1),
    displayName: 'Merchant Companies',
  );
  m[kTechIdNationalBureaucracy] = TechDefinition(
    id: kTechIdNationalBureaucracy,
    era: 2,
    category: 'civilian',
    cost: _cost(2),
    displayName: 'National Bureaucracy',
    prerequisiteIds: [
      kTechIdPrintingPress,
      kTechIdMoneyLending,
      kTechIdDiplomaticExpertise,
    ],
  );
  m[kTechIdPropaganda] = TechDefinition(
    id: kTechIdPropaganda,
    era: 3,
    category: 'diplomacy',
    cost: _cost(3),
    displayName: 'Propaganda',
    prerequisiteIds: [kTechIdNationalBureaucracy, kTechIdUniversity],
  );
  m[kTechIdNationalism] = TechDefinition(
    id: kTechIdNationalism,
    era: 3,
    category: 'diplomacy',
    cost: _cost(3),
    displayName: 'Nationalism',
    prerequisiteIds: [
      kTechIdPropaganda,
      kTechIdMasterArtisans,
      kTechIdModernForts,
    ],
  );
  m[kTechIdEmpireBuilding] = TechDefinition(
    id: kTechIdEmpireBuilding,
    era: 4,
    category: 'diplomacy',
    cost: _cost(4),
    displayName: 'Empire Building',
    prerequisiteIds: [kTechIdNationalism, kTechIdBanking],
  );

  // --- Naval merchant (8) ---
  m[kTechIdSuperiorHullDesign] = TechDefinition(
    id: kTechIdSuperiorHullDesign,
    era: 1,
    category: 'naval',
    cost: _cost(1),
    displayName: 'Superior Hull Design',
    shipUnlockIds: ['fluyte'],
  );
  m[kTechIdImprovedSailDesign] = TechDefinition(
    id: kTechIdImprovedSailDesign,
    era: 2,
    category: 'naval',
    cost: _cost(2),
    displayName: 'Improved Sail Design',
    prerequisiteIds: [kTechIdWindSawMill, kTechIdSuperiorHullDesign],
    shipUnlockIds: ['trader'],
  );
  m[kTechIdConvoying] = TechDefinition(
    id: kTechIdConvoying,
    era: 2,
    category: 'naval',
    cost: _cost(2),
    displayName: 'Convoying',
    prerequisiteIds: [kTechIdMerchantCompanies],
    shipUnlockIds: ['galleon'],
  );
  m[kTechIdNavigation] = TechDefinition(
    id: kTechIdNavigation,
    era: 1,
    category: 'naval',
    cost: _cost(1),
    displayName: 'Navigation',
    prerequisiteIds: [kTechIdSuperiorHullDesign],
    shipUnlockIds: ['sloop'],
  );
  m[kTechIdLargeHulls] = TechDefinition(
    id: kTechIdLargeHulls,
    era: 2,
    category: 'naval',
    cost: _cost(2),
    displayName: 'Large Hulls',
    prerequisiteIds: [kTechIdWindSawMill, kTechIdNavigation, kTechIdConvoying],
    shipUnlockIds: ['indiaman'],
  );
  m[kTechIdClipperShips] = TechDefinition(
    id: kTechIdClipperShips,
    era: 4,
    category: 'naval',
    cost: _cost(4),
    displayName: 'Clipper Ships',
    prerequisiteIds: [kTechIdCircularSaw, kTechIdAdvancedHullDesign],
    shipUnlockIds: ['clipper'],
  );
}
