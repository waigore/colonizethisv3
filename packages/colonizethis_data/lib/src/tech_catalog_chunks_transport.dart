import 'tech_catalog_cost.dart';
import 'tech_definition.dart';
import 'tech_ids.dart';

void addTechCatalogTransport(Map<String, TechDefinition> m) {
  // --- Transport (4) ---
  m[kTechIdRoadConstruction] = TechDefinition(
    id: kTechIdRoadConstruction,
    era: 1,
    category: 'transport',
    cost: techCatalogCostForTier(1),
    displayName: 'Road Construction',
    prerequisiteIds: [kTechIdSawMill, kTechIdLandEnclosure, kTechIdIronMining],
  );
  m[kTechIdEarlySteamEngine] = TechDefinition(
    id: kTechIdEarlySteamEngine,
    era: 2,
    category: 'transport',
    cost: techCatalogCostForTier(2),
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
    cost: techCatalogCostForTier(3),
    displayName: 'Later Steam Engine',
    prerequisiteIds: [kTechIdEarlySteamEngine, kTechIdCrucibleProcess],
  );
  m[kTechIdDynamite] = TechDefinition(
    id: kTechIdDynamite,
    era: 4,
    category: 'transport',
    cost: techCatalogCostForTier(4),
    displayName: 'Dynamite',
    prerequisiteIds: [
      kTechIdLaterSteamEngine,
      kTechIdBanking,
      kTechIdExplosives,
    ],
  );
}
