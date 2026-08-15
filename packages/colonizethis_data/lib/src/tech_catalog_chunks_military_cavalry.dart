import 'tech_catalog_cost.dart';
import 'tech_definition.dart';
import 'tech_ids.dart';

void addTechCatalogMilitaryCavalry(Map<String, TechDefinition> m) {
  // --- Military cavalry (6) ---
  m[kTechIdRecruitSteppeHorsemen] = TechDefinition(
    id: kTechIdRecruitSteppeHorsemen,
    era: 1,
    category: 'military',
    cost: techCatalogCostForTier(1),
    displayName: 'Recruit Steppe Horsemen',
    prerequisiteIds: [kTechIdCropRotation],
    regimentUnlockIds: ['cossacks'],
  );
  m[kTechIdImprovedCavalryTactics] = TechDefinition(
    id: kTechIdImprovedCavalryTactics,
    era: 2,
    category: 'military',
    cost: techCatalogCostForTier(2),
    displayName: 'Improved Cavalry Tactics',
    prerequisiteIds: [kTechIdPrintingPress, kTechIdAnimalHusbandry],
    regimentUnlockIds: ['harquebusiers'],
  );
  m[kTechIdHussars] = TechDefinition(
    id: kTechIdHussars,
    era: 2,
    category: 'military',
    cost: techCatalogCostForTier(2),
    displayName: 'Hussars',
    prerequisiteIds: [
      kTechIdImprovedCavalryTactics,
      kTechIdRecruitSteppeHorsemen,
    ],
    regimentUnlockIds: [kTechIdHussars],
  );
  m[kTechIdImprovedCavalryWeapons] = TechDefinition(
    id: kTechIdImprovedCavalryWeapons,
    era: 3,
    category: 'military',
    cost: techCatalogCostForTier(3),
    displayName: 'Improved Cavalry Weapons',
    prerequisiteIds: [
      kTechIdIndustrialMachinery,
      kTechIdCrucibleProcess,
      kTechIdImprovedCavalryTactics,
    ],
    regimentUnlockIds: ['cuirassiers'],
  );
  m[kTechIdScouting] = TechDefinition(
    id: kTechIdScouting,
    era: 3,
    category: 'military',
    cost: techCatalogCostForTier(3),
    displayName: 'Scouting',
    prerequisiteIds: [kTechIdHussars, kTechIdEarlyRifles],
    regimentUnlockIds: ['scouts'],
  );
  m[kTechIdRepeatingCavalryCarbine] = TechDefinition(
    id: kTechIdRepeatingCavalryCarbine,
    era: 4,
    category: 'military',
    cost: techCatalogCostForTier(4),
    displayName: 'Repeating Cavalry Carbine',
    prerequisiteIds: [
      kTechIdIndustrialFundingOfResearch,
      kTechIdImprovedCavalryWeapons,
    ],
    regimentUnlockIds: ['carbine_cavalry'],
  );
}
