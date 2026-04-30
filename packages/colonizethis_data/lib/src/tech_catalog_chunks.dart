
part of 'tech_catalog.dart';

void _addTechCatalogChunk5(Map<String, TechDefinition> m) {
  m[kTechIdPaddlewheels] = TechDefinition(
    id: kTechIdPaddlewheels,
    era: 3,
    category: 'naval',
    cost: _cost(3),
    displayName: 'Paddlewheels',
    prerequisiteIds: [kTechIdAdvancedHullDesign, kTechIdEarlySteamEngine],
    shipUnlockIds: ['raider'],
  );
  m[kTechIdMerchantSteamships] = TechDefinition(
    id: kTechIdMerchantSteamships,
    era: 4,
    category: 'naval',
    cost: _cost(4),
    displayName: 'Merchant Steamships',
    prerequisiteIds: [kTechIdPaddlewheels, kTechIdRiverboats],
    shipUnlockIds: ['merchant_steamship'],
  );

  // --- Naval warships (4) ---
  m[kTechIdAdvancedHullDesign] = TechDefinition(
    id: kTechIdAdvancedHullDesign,
    era: 3,
    category: 'naval',
    cost: _cost(3),
    displayName: 'Advanced Hull Design',
    prerequisiteIds: [
      kTechIdUniversity,
      kTechIdImprovedSailDesign,
      kTechIdPrivateeringCompanies,
    ],
    shipUnlockIds: ['frigate'],
  );
  m[kTechIdShipOfTheLine] = TechDefinition(
    id: kTechIdShipOfTheLine,
    era: 3,
    category: 'naval',
    cost: _cost(3),
    displayName: 'Ship of the Line',
    prerequisiteIds: [kTechIdLargeHulls, kTechIdLargeCopperAndTinMines],
    shipUnlockIds: [kTechIdShipOfTheLine],
  );
  m[kTechIdPrivateeringCompanies] = TechDefinition(
    id: kTechIdPrivateeringCompanies,
    era: 2,
    category: 'naval',
    cost: _cost(2),
    displayName: 'Privateering Companies',
    prerequisiteIds: [kTechIdNavigation, kTechIdDiplomaticExpertise],
  );
  m[kTechIdAdvancedIronWorking] = TechDefinition(
    id: kTechIdAdvancedIronWorking,
    era: 4,
    category: 'naval',
    cost: _cost(4),
    displayName: 'Advanced Iron Working',
    prerequisiteIds: [
      kTechIdShipOfTheLine,
      kTechIdIndustrialFundingOfResearch,
      kTechIdPaddlewheels,
    ],
    shipUnlockIds: ['ironclad'],
  );

  // --- Military infantry (12) ---
  m[kTechIdOrganisedRegiments] = TechDefinition(
    id: kTechIdOrganisedRegiments,
    era: 1,
    category: 'military',
    cost: _cost(1),
    displayName: 'Organised Regiments',
    prerequisiteIds: [kTechIdLandEnclosure],
    regimentUnlockIds: ['lancers'],
  );
  m[kTechIdImprovedIronWeapons] = TechDefinition(
    id: kTechIdImprovedIronWeapons,
    era: 1,
    category: 'military',
    cost: _cost(1),
    displayName: 'Improved Iron Weapons',
    prerequisiteIds: [kTechIdOrganisedRegiments, kTechIdIronMining],
    regimentUnlockIds: ['halberdiers'],
  );
  m[kTechIdImprovedInfantryTactics] = TechDefinition(
    id: kTechIdImprovedInfantryTactics,
    era: 2,
    category: 'military',
    cost: _cost(2),
    displayName: 'Improved Infantry Tactics',
    prerequisiteIds: [kTechIdOrganisedRegiments, kTechIdPrintingPress],
    regimentUnlockIds: ['calivermen'],
  );
  m[kTechIdCrucibleProcess] = TechDefinition(
    id: kTechIdCrucibleProcess,
    era: 2,
    category: 'military',
    cost: _cost(2),
    displayName: 'Crucible Process',
    prerequisiteIds: [kTechIdSquareSetTimbering, kTechIdSteamInMining],
  );
  m[kTechIdBayonet] = TechDefinition(
    id: kTechIdBayonet,
    era: 2,
    category: 'military',
    cost: _cost(2),
    displayName: 'Bayonet',
    prerequisiteIds: [kTechIdImprovedIronWeapons, kTechIdCrucibleProcess],
    regimentUnlockIds: ['regulars'],
  );
  m[kTechIdWeaponCraftsmanship] = TechDefinition(
    id: kTechIdWeaponCraftsmanship,
    era: 2,
    category: 'military',
    cost: _cost(2),
    displayName: 'Weapon Craftsmanship',
    prerequisiteIds: [kTechIdOrganisedRegiments, kTechIdCopperAndTinMining],
    regimentUnlockIds: ['musketeers'],
  );
  m[kTechIdIndustrialMachinery] = TechDefinition(
    id: kTechIdIndustrialMachinery,
    era: 3,
    category: 'military',
    cost: _cost(3),
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
    cost: _cost(3),
    displayName: 'Explosives',
    prerequisiteIds: [kTechIdWeaponCraftsmanship, kTechIdIndustrialMachinery],
    regimentUnlockIds: ['grenadiers'],
  );
  m[kTechIdEarlyRifles] = TechDefinition(
    id: kTechIdEarlyRifles,
    era: 3,
    category: 'military',
    cost: _cost(3),
    displayName: 'Early Rifles',
    prerequisiteIds: [kTechIdImprovedInfantryTactics, kTechIdCrucibleProcess],
    regimentUnlockIds: ['skirmishers'],
  );
  m[kTechIdLongRangeRifles] = TechDefinition(
    id: kTechIdLongRangeRifles,
    era: 3,
    category: 'military',
    cost: _cost(3),
    displayName: 'Long Range Rifles',
    prerequisiteIds: [kTechIdEarlyRifles, kTechIdCrucibleProcess],
    regimentUnlockIds: ['sharpshooters'],
  );
  m[kTechIdNeedleGuns] = TechDefinition(
    id: kTechIdNeedleGuns,
    era: 4,
    category: 'military',
    cost: _cost(4),
    displayName: 'Needle Guns',
    prerequisiteIds: [
      kTechIdIndustrialFundingOfResearch,
      kTechIdBayonet,
      kTechIdEarlyRifles,
    ],
    regimentUnlockIds: ['rifle_infantry'],
  );
}

void _addTechCatalogChunk6(Map<String, TechDefinition> m) {
  m[kTechIdEliteMilitaryTraining] = TechDefinition(
    id: kTechIdEliteMilitaryTraining,
    era: 4,
    category: 'military',
    cost: _cost(4),
    displayName: 'Elite Military Training',
    prerequisiteIds: [
      kTechIdModernMilitaryFunding,
      kTechIdNeedleGuns,
      kTechIdExplosives,
    ],
    regimentUnlockIds: ['guards'],
  );

  // --- Military cavalry (6) ---
  m[kTechIdRecruitSteppeHorsemen] = TechDefinition(
    id: kTechIdRecruitSteppeHorsemen,
    era: 1,
    category: 'military',
    cost: _cost(1),
    displayName: 'Recruit Steppe Horsemen',
    prerequisiteIds: [kTechIdCropRotation],
    regimentUnlockIds: ['cossacks'],
  );
  m[kTechIdImprovedCavalryTactics] = TechDefinition(
    id: kTechIdImprovedCavalryTactics,
    era: 2,
    category: 'military',
    cost: _cost(2),
    displayName: 'Improved Cavalry Tactics',
    prerequisiteIds: [kTechIdPrintingPress, kTechIdAnimalHusbandry],
    regimentUnlockIds: ['harquebusiers'],
  );
  m[kTechIdHussars] = TechDefinition(
    id: kTechIdHussars,
    era: 2,
    category: 'military',
    cost: _cost(2),
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
    cost: _cost(3),
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
    cost: _cost(3),
    displayName: 'Scouting',
    prerequisiteIds: [kTechIdHussars, kTechIdEarlyRifles],
    regimentUnlockIds: ['scouts'],
  );
  m[kTechIdRepeatingCavalryCarbine] = TechDefinition(
    id: kTechIdRepeatingCavalryCarbine,
    era: 4,
    category: 'military',
    cost: _cost(4),
    displayName: 'Repeating Cavalry Carbine',
    prerequisiteIds: [
      kTechIdIndustrialFundingOfResearch,
      kTechIdImprovedCavalryWeapons,
    ],
    regimentUnlockIds: ['carbine_cavalry'],
  );

  // --- Military artillery (11) ---
  m[kTechIdHorseArtillery] = TechDefinition(
    id: kTechIdHorseArtillery,
    era: 1,
    category: 'military',
    cost: _cost(1),
    displayName: 'Horse Artillery',
    prerequisiteIds: [kTechIdAnimalHusbandry, kTechIdCopperAndTinMining],
    regimentUnlockIds: [kTechIdHorseArtillery],
  );
  m[kTechIdSiegeEngineering] = TechDefinition(
    id: kTechIdSiegeEngineering,
    era: 2,
    category: 'military',
    cost: _cost(2),
    displayName: 'Siege Engineering',
    prerequisiteIds: [kTechIdPrintingPress, kTechIdCopperAndTinMining],
    regimentUnlockIds: ['royal_artillery'],
  );
  m[kTechIdLightArtilleryTactics] = TechDefinition(
    id: kTechIdLightArtilleryTactics,
    era: 3,
    category: 'military',
    cost: _cost(3),
    displayName: 'Light Artillery Tactics',
    prerequisiteIds: [kTechIdCrucibleProcess, kTechIdUniversity],
    regimentUnlockIds: ['light_artillery'],
  );
  m[kTechIdModernForts] = TechDefinition(
    id: kTechIdModernForts,
    era: 3,
    category: 'military',
    cost: _cost(3),
    displayName: 'Modern Forts',
    prerequisiteIds: [kTechIdSiegeEngineering, kTechIdUniversity],
  );
  m[kTechIdHeavyArtillery] = TechDefinition(
    id: kTechIdHeavyArtillery,
    era: 3,
    category: 'military',
    cost: _cost(3),
    displayName: 'Heavy Artillery',
    prerequisiteIds: [kTechIdModernForts, kTechIdCrucibleProcess],
    regimentUnlockIds: [kTechIdHeavyArtillery],
  );
  m[kTechIdHeavyEmplacedArtillery] = TechDefinition(
    id: kTechIdHeavyEmplacedArtillery,
    era: 3,
    category: 'military',
    cost: _cost(3),
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
    cost: _cost(4),
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
    cost: _cost(4),
    displayName: 'High Grade Steel',
    prerequisiteIds: [
      kTechIdHeavyArtillery,
      kTechIdIndustrialFundingOfResearch,
      kTechIdModernMilitaryFunding,
    ],
    regimentUnlockIds: ['siege_guns'],
  );
}

void _addTechCatalogChunk7(Map<String, TechDefinition> m) {
  m[kTechIdEmplacedSiegeGuns] = TechDefinition(
    id: kTechIdEmplacedSiegeGuns,
    era: 4,
    category: 'military',
    cost: _cost(4),
    displayName: 'Emplaced Siege Guns',
    prerequisiteIds: [kTechIdHeavyArtillery, kTechIdHeavyEmplacedArtillery],
  );
  m[kTechIdModernMilitaryFunding] = TechDefinition(
    id: kTechIdModernMilitaryFunding,
    era: 3,
    category: 'military',
    cost: _cost(3),
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
    cost: _cost(3),
    displayName: 'Industrial Funding of Research',
    prerequisiteIds: [kTechIdIndustrialMachinery, kTechIdCrucibleProcess],
  );

}
