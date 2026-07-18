/// Full tech catalog (113 techs). SPEC/game/tech-tree.md and category sub-docs.
/// Imported by tech_extraction.dart. Do not export; use colonizethis_data public API.

import 'tech_definition.dart';
import 'tech_ids.dart';

part 'tech_catalog_chunks_gathering.dart';
part 'tech_catalog_chunks_economy.dart';
part 'tech_catalog_chunks.dart';

// Cost tier == era bucket (1..4). Rebalanced so a slot at Medium funding
// (300 RP/turn) completes a tier-1 tech in 6 turns and a tier-4 tech in 12.
// SPEC/game/tech-tree.md § Research Model (Research point costs).
int _cost(int tier) => 1800 + (tier - 1) * 600; // 1800, 2400, 3000, 3600

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
