import 'tech_catalog_cost.dart';
import 'tech_definition.dart';
import 'tech_ids.dart';

void addTechCatalogMilitaryArtillery(Map<String, TechDefinition> m) {
  // --- Military artillery (11) ---
  m[kTechIdHorseArtillery] = TechDefinition(
    id: kTechIdHorseArtillery,
    era: 1,
    category: 'military',
    cost: techCatalogCostForTier(1),
    displayName: 'Horse Artillery',
    prerequisiteIds: [kTechIdAnimalHusbandry, kTechIdCopperAndTinMining],
    regimentUnlockIds: [kTechIdHorseArtillery],
  );
  m[kTechIdSiegeEngineering] = TechDefinition(
    id: kTechIdSiegeEngineering,
    era: 2,
    category: 'military',
    cost: techCatalogCostForTier(2),
    displayName: 'Siege Engineering',
    prerequisiteIds: [kTechIdPrintingPress, kTechIdCopperAndTinMining],
    regimentUnlockIds: ['royal_artillery'],
  );
  m[kTechIdLightArtilleryTactics] = TechDefinition(
    id: kTechIdLightArtilleryTactics,
    era: 3,
    category: 'military',
    cost: techCatalogCostForTier(3),
    displayName: 'Light Artillery Tactics',
    prerequisiteIds: [kTechIdCrucibleProcess, kTechIdUniversity],
    regimentUnlockIds: ['light_artillery'],
  );
  m[kTechIdModernForts] = TechDefinition(
    id: kTechIdModernForts,
    era: 3,
    category: 'military',
    cost: techCatalogCostForTier(3),
    displayName: 'Modern Forts',
    prerequisiteIds: [kTechIdSiegeEngineering, kTechIdUniversity],
  );
  m[kTechIdHeavyArtillery] = TechDefinition(
    id: kTechIdHeavyArtillery,
    era: 3,
    category: 'military',
    cost: techCatalogCostForTier(3),
    displayName: 'Heavy Artillery',
    prerequisiteIds: [kTechIdModernForts, kTechIdCrucibleProcess],
    regimentUnlockIds: [kTechIdHeavyArtillery],
  );
  m[kTechIdHeavyEmplacedArtillery] = TechDefinition(
    id: kTechIdHeavyEmplacedArtillery,
    era: 3,
    category: 'military',
    cost: techCatalogCostForTier(3),
    displayName: 'Heavy Emplaced Artillery',
    prerequisiteIds: [
      kTechIdRoadConstruction,
      kTechIdNationalBureaucracy,
      kTechIdSiegeEngineering,
    ],
  );
  m[kTechIdFieldArtilleryTactics] = TechDefinition(
    id: kTechIdFieldArtilleryTactics,
    era: 4,
    category: 'military',
    cost: techCatalogCostForTier(4),
    displayName: 'Field Artillery Tactics',
    prerequisiteIds: [
      kTechIdLightArtilleryTactics,
      kTechIdModernMilitaryFunding,
    ],
    regimentUnlockIds: ['field_artillery'],
  );
  m[kTechIdHighGradeSteel] = TechDefinition(
    id: kTechIdHighGradeSteel,
    era: 4,
    category: 'military',
    cost: techCatalogCostForTier(4),
    displayName: 'High Grade Steel',
    prerequisiteIds: [
      kTechIdHeavyArtillery,
      kTechIdIndustrialFundingOfResearch,
      kTechIdModernMilitaryFunding,
    ],
    regimentUnlockIds: ['siege_guns'],
  );
  m[kTechIdEmplacedSiegeGuns] = TechDefinition(
    id: kTechIdEmplacedSiegeGuns,
    era: 4,
    category: 'military',
    cost: techCatalogCostForTier(4),
    displayName: 'Emplaced Siege Guns',
    prerequisiteIds: [kTechIdHeavyArtillery, kTechIdHeavyEmplacedArtillery],
  );
  m[kTechIdModernMilitaryFunding] = TechDefinition(
    id: kTechIdModernMilitaryFunding,
    era: 3,
    category: 'military',
    cost: techCatalogCostForTier(3),
    displayName: 'Modern Military Funding',
    prerequisiteIds: [
      kTechIdBanking,
      kTechIdLargePreciousStoneMines,
      kTechIdModernForts,
    ],
  );
  m[kTechIdIndustrialFundingOfResearch] = TechDefinition(
    id: kTechIdIndustrialFundingOfResearch,
    era: 3,
    category: 'military',
    cost: techCatalogCostForTier(3),
    displayName: 'Industrial Funding of Research',
    prerequisiteIds: [kTechIdIndustrialMachinery, kTechIdCrucibleProcess],
  );
}
