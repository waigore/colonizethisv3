part of 'tech_catalog.dart';

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
