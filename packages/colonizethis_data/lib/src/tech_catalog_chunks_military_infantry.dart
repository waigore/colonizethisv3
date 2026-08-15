import 'tech_catalog_cost.dart';
import 'tech_definition.dart';
import 'tech_ids.dart';

void addTechCatalogMilitaryInfantry(Map<String, TechDefinition> m) {
  // --- Military infantry (12) ---
  m[kTechIdOrganisedRegiments] = TechDefinition(
    id: kTechIdOrganisedRegiments,
    era: 1,
    category: 'military',
    cost: techCatalogCostForTier(1),
    displayName: 'Organised Regiments',
    prerequisiteIds: [kTechIdLandEnclosure],
    regimentUnlockIds: ['lancers'],
  );
  m[kTechIdImprovedIronWeapons] = TechDefinition(
    id: kTechIdImprovedIronWeapons,
    era: 1,
    category: 'military',
    cost: techCatalogCostForTier(1),
    displayName: 'Improved Iron Weapons',
    prerequisiteIds: [kTechIdOrganisedRegiments, kTechIdIronMining],
    regimentUnlockIds: ['halberdiers'],
  );
  m[kTechIdImprovedInfantryTactics] = TechDefinition(
    id: kTechIdImprovedInfantryTactics,
    era: 2,
    category: 'military',
    cost: techCatalogCostForTier(2),
    displayName: 'Improved Infantry Tactics',
    prerequisiteIds: [kTechIdOrganisedRegiments, kTechIdPrintingPress],
    regimentUnlockIds: ['calivermen'],
  );
  m[kTechIdCrucibleProcess] = TechDefinition(
    id: kTechIdCrucibleProcess,
    era: 2,
    category: 'military',
    cost: techCatalogCostForTier(2),
    displayName: 'Crucible Process',
    prerequisiteIds: [kTechIdSquareSetTimbering, kTechIdSteamInMining],
  );
  m[kTechIdBayonet] = TechDefinition(
    id: kTechIdBayonet,
    era: 2,
    category: 'military',
    cost: techCatalogCostForTier(2),
    displayName: 'Bayonet',
    prerequisiteIds: [kTechIdImprovedIronWeapons, kTechIdCrucibleProcess],
    regimentUnlockIds: ['regulars'],
  );
  m[kTechIdWeaponCraftsmanship] = TechDefinition(
    id: kTechIdWeaponCraftsmanship,
    era: 2,
    category: 'military',
    cost: techCatalogCostForTier(2),
    displayName: 'Weapon Craftsmanship',
    prerequisiteIds: [kTechIdOrganisedRegiments, kTechIdCopperAndTinMining],
    regimentUnlockIds: ['musketeers'],
  );
  m[kTechIdIndustrialMachinery] = TechDefinition(
    id: kTechIdIndustrialMachinery,
    era: 3,
    category: 'military',
    cost: techCatalogCostForTier(3),
    displayName: 'Industrial Machinery',
    prerequisiteIds: [
      kTechIdTrainedJourneymen,
      kTechIdSteamInMining,
      kTechIdUniversity,
    ],
  );
  m[kTechIdExplosives] = TechDefinition(
    id: kTechIdExplosives,
    era: 3,
    category: 'military',
    cost: techCatalogCostForTier(3),
    displayName: 'Explosives',
    prerequisiteIds: [kTechIdWeaponCraftsmanship, kTechIdIndustrialMachinery],
    regimentUnlockIds: ['grenadiers'],
  );
  m[kTechIdEarlyRifles] = TechDefinition(
    id: kTechIdEarlyRifles,
    era: 3,
    category: 'military',
    cost: techCatalogCostForTier(3),
    displayName: 'Early Rifles',
    prerequisiteIds: [kTechIdImprovedInfantryTactics, kTechIdCrucibleProcess],
    regimentUnlockIds: ['skirmishers'],
  );
  m[kTechIdLongRangeRifles] = TechDefinition(
    id: kTechIdLongRangeRifles,
    era: 3,
    category: 'military',
    cost: techCatalogCostForTier(3),
    displayName: 'Long Range Rifles',
    prerequisiteIds: [kTechIdEarlyRifles, kTechIdCrucibleProcess],
    regimentUnlockIds: ['sharpshooters'],
  );
  m[kTechIdNeedleGuns] = TechDefinition(
    id: kTechIdNeedleGuns,
    era: 4,
    category: 'military',
    cost: techCatalogCostForTier(4),
    displayName: 'Needle Guns',
    prerequisiteIds: [
      kTechIdIndustrialFundingOfResearch,
      kTechIdBayonet,
      kTechIdEarlyRifles,
    ],
    regimentUnlockIds: ['rifle_infantry'],
  );
  m[kTechIdEliteMilitaryTraining] = TechDefinition(
    id: kTechIdEliteMilitaryTraining,
    era: 4,
    category: 'military',
    cost: techCatalogCostForTier(4),
    displayName: 'Elite Military Training',
    prerequisiteIds: [
      kTechIdModernMilitaryFunding,
      kTechIdNeedleGuns,
      kTechIdExplosives,
    ],
    regimentUnlockIds: ['guards'],
  );
}
