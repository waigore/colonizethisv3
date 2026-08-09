/// Full tech catalog (113 techs). SPEC/game/tech-tree.md and category sub-docs.
/// Imported by tech_extraction.dart. Do not export; use colonizethis_data public API.
library;

import 'tech_definition.dart';

import 'tech_catalog_chunks.dart';
import 'tech_catalog_chunks_economy.dart';
import 'tech_catalog_chunks_gathering.dart';

/// Full catalog: 113 techs with displayName, prerequisiteIds, discoveryResourceIds (7 discovery techs), regimentUnlockIds, shipUnlockIds.
Map<String, TechDefinition> buildTechCatalog() {
  final m = <String, TechDefinition>{};

  addTechCatalogChunk1(m);
  addTechCatalogChunk2(m);
  addTechCatalogChunk3(m);
  addTechCatalogChunk4(m);
  addTechCatalogChunk5(m);
  addTechCatalogChunk6(m);
  addTechCatalogChunk7(m);

  return m;
}
