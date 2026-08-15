import 'tech_catalog_cost.dart';
import 'tech_definition.dart';
import 'tech_ids.dart';

void addTechCatalogDiplomacyCivilian(Map<String, TechDefinition> m) {
  // --- Diplomacy / Civilian (6) ---
  m[kTechIdDiplomaticExpertise] = TechDefinition(
    id: kTechIdDiplomaticExpertise,
    era: 1,
    category: 'diplomacy',
    cost: techCatalogCostForTier(1),
    displayName: 'Diplomatic Expertise',
  );
  m[kTechIdMerchantCompanies] = TechDefinition(
    id: kTechIdMerchantCompanies,
    era: 1,
    category: 'civilian',
    cost: techCatalogCostForTier(1),
    displayName: 'Merchant Companies',
  );
  m[kTechIdNationalBureaucracy] = TechDefinition(
    id: kTechIdNationalBureaucracy,
    era: 2,
    category: 'civilian',
    cost: techCatalogCostForTier(2),
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
    cost: techCatalogCostForTier(3),
    displayName: 'Propaganda',
    prerequisiteIds: [kTechIdNationalBureaucracy, kTechIdUniversity],
  );
  m[kTechIdNationalism] = TechDefinition(
    id: kTechIdNationalism,
    era: 3,
    category: 'diplomacy',
    cost: techCatalogCostForTier(3),
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
    cost: techCatalogCostForTier(4),
    displayName: 'Empire Building',
    prerequisiteIds: [kTechIdNationalism, kTechIdBanking],
  );
}
