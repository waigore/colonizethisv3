import 'tech_catalog_cost.dart';
import 'tech_definition.dart';
import 'tech_ids.dart';

void addTechCatalogLabour(Map<String, TechDefinition> m) {
  // --- Labour (8) ---
  m[kTechIdPrintingPress] = TechDefinition(
    id: kTechIdPrintingPress,
    era: 1,
    category: 'labour',
    cost: techCatalogCostForTier(1),
    displayName: 'Printing Press',
    prerequisiteIds: [kTechIdSawMill],
  );
  m[kTechIdApprenticeWorkers] = TechDefinition(
    id: kTechIdApprenticeWorkers,
    era: 2,
    category: 'labour',
    cost: techCatalogCostForTier(2),
    displayName: 'Apprentice Workers',
    prerequisiteIds: [kTechIdLandEnclosure, kTechIdSugarRefining],
  );
  m[kTechIdTrainedJourneymen] = TechDefinition(
    id: kTechIdTrainedJourneymen,
    era: 2,
    category: 'labour',
    cost: techCatalogCostForTier(2),
    displayName: 'Trained Journeymen',
    prerequisiteIds: [kTechIdCigarProduction, kTechIdPrintingPress],
  );
  m[kTechIdMasterArtisans] = TechDefinition(
    id: kTechIdMasterArtisans,
    era: 3,
    category: 'labour',
    cost: techCatalogCostForTier(3),
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
    cost: techCatalogCostForTier(1),
    displayName: 'Money Lending',
    prerequisiteIds: [kTechIdLandEnclosure],
  );
  m[kTechIdBanking] = TechDefinition(
    id: kTechIdBanking,
    era: 3,
    category: 'labour',
    cost: techCatalogCostForTier(3),
    displayName: 'Banking',
    prerequisiteIds: [kTechIdMasterArtisans, kTechIdTradeFairs],
  );
  m[kTechIdTradeFairs] = TechDefinition(
    id: kTechIdTradeFairs,
    era: 2,
    category: 'labour',
    cost: techCatalogCostForTier(2),
    displayName: 'Trade Fairs',
    prerequisiteIds: [kTechIdMerchantCompanies, kTechIdSugarRefining],
  );
  m[kTechIdUniversity] = TechDefinition(
    id: kTechIdUniversity,
    era: 3,
    category: 'labour',
    cost: techCatalogCostForTier(3),
    displayName: 'University',
    prerequisiteIds: [
      kTechIdMoneyLending,
      kTechIdApprenticeWorkers,
      kTechIdPrintingPress,
    ],
  );
}
