import 'tech_catalog_cost.dart';
import 'tech_definition.dart';
import 'tech_ids.dart';

void addTechCatalogNaval(Map<String, TechDefinition> m) {
  // --- Naval merchant (8) ---
  m[kTechIdSuperiorHullDesign] = TechDefinition(
    id: kTechIdSuperiorHullDesign,
    era: 1,
    category: 'naval',
    cost: techCatalogCostForTier(1),
    displayName: 'Superior Hull Design',
    shipUnlockIds: ['fluyte'],
  );
  m[kTechIdImprovedSailDesign] = TechDefinition(
    id: kTechIdImprovedSailDesign,
    era: 2,
    category: 'naval',
    cost: techCatalogCostForTier(2),
    displayName: 'Improved Sail Design',
    prerequisiteIds: [kTechIdWindSawMill, kTechIdSuperiorHullDesign],
    shipUnlockIds: ['trader'],
  );
  m[kTechIdConvoying] = TechDefinition(
    id: kTechIdConvoying,
    era: 2,
    category: 'naval',
    cost: techCatalogCostForTier(2),
    displayName: 'Convoying',
    prerequisiteIds: [kTechIdMerchantCompanies],
    shipUnlockIds: ['galleon'],
  );
  m[kTechIdNavigation] = TechDefinition(
    id: kTechIdNavigation,
    era: 1,
    category: 'naval',
    cost: techCatalogCostForTier(1),
    displayName: 'Navigation',
    prerequisiteIds: [kTechIdSuperiorHullDesign],
    shipUnlockIds: ['sloop'],
  );
  m[kTechIdLargeHulls] = TechDefinition(
    id: kTechIdLargeHulls,
    era: 2,
    category: 'naval',
    cost: techCatalogCostForTier(2),
    displayName: 'Large Hulls',
    prerequisiteIds: [kTechIdWindSawMill, kTechIdNavigation, kTechIdConvoying],
    shipUnlockIds: ['indiaman'],
  );
  m[kTechIdClipperShips] = TechDefinition(
    id: kTechIdClipperShips,
    era: 4,
    category: 'naval',
    cost: techCatalogCostForTier(4),
    displayName: 'Clipper Ships',
    prerequisiteIds: [kTechIdCircularSaw, kTechIdAdvancedHullDesign],
    shipUnlockIds: ['clipper'],
  );
  m[kTechIdPaddlewheels] = TechDefinition(
    id: kTechIdPaddlewheels,
    era: 3,
    category: 'naval',
    cost: techCatalogCostForTier(3),
    displayName: 'Paddlewheels',
    prerequisiteIds: [kTechIdAdvancedHullDesign, kTechIdEarlySteamEngine],
    shipUnlockIds: ['raider'],
  );
  m[kTechIdMerchantSteamships] = TechDefinition(
    id: kTechIdMerchantSteamships,
    era: 4,
    category: 'naval',
    cost: techCatalogCostForTier(4),
    displayName: 'Merchant Steamships',
    prerequisiteIds: [kTechIdPaddlewheels, kTechIdRiverboats],
    shipUnlockIds: ['merchant_steamship'],
  );
  // --- Naval warships (4) ---
  m[kTechIdAdvancedHullDesign] = TechDefinition(
    id: kTechIdAdvancedHullDesign,
    era: 3,
    category: 'naval',
    cost: techCatalogCostForTier(3),
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
    cost: techCatalogCostForTier(3),
    displayName: 'Ship of the Line',
    prerequisiteIds: [kTechIdLargeHulls, kTechIdLargeCopperAndTinMines],
    shipUnlockIds: [kTechIdShipOfTheLine],
  );
  m[kTechIdPrivateeringCompanies] = TechDefinition(
    id: kTechIdPrivateeringCompanies,
    era: 2,
    category: 'naval',
    cost: techCatalogCostForTier(2),
    displayName: 'Privateering Companies',
    prerequisiteIds: [kTechIdNavigation, kTechIdDiplomaticExpertise],
  );
  m[kTechIdAdvancedIronWorking] = TechDefinition(
    id: kTechIdAdvancedIronWorking,
    era: 4,
    category: 'naval',
    cost: techCatalogCostForTier(4),
    displayName: 'Advanced Iron Working',
    prerequisiteIds: [
      kTechIdShipOfTheLine,
      kTechIdIndustrialFundingOfResearch,
      kTechIdPaddlewheels,
    ],
    shipUnlockIds: ['ironclad'],
  );
}
