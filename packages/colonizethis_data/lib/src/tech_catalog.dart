/// Full tech catalog (113 techs). SPEC/game/tech-tree.md and category sub-docs.
/// Imported by tech_catalog_query.dart. Do not export; use colonizethis_data public API.
library;

import 'tech_definition.dart';

import 'tech_catalog_chunks_diplomacy_civilian.dart';
import 'tech_catalog_chunks_gathering.dart';
import 'tech_catalog_chunks_labour.dart';
import 'tech_catalog_chunks_military_artillery.dart';
import 'tech_catalog_chunks_military_cavalry.dart';
import 'tech_catalog_chunks_military_infantry.dart';
import 'tech_catalog_chunks_naval.dart';
import 'tech_catalog_chunks_new_world.dart';
import 'tech_catalog_chunks_transport.dart';

/// Full catalog: 113 techs with displayName, prerequisiteIds, discoveryResourceIds (7 discovery techs), regimentUnlockIds, shipUnlockIds.
/// Chunk files follow GDD category families (SPEC/game/tech-tree.md).
Map<String, TechDefinition> buildTechCatalog() {
  final m = <String, TechDefinition>{};

  addTechCatalogGathering(m);
  addTechCatalogNewWorld(m);
  addTechCatalogTransport(m);
  addTechCatalogLabour(m);
  addTechCatalogDiplomacyCivilian(m);
  addTechCatalogNaval(m);
  addTechCatalogMilitaryInfantry(m);
  addTechCatalogMilitaryCavalry(m);
  addTechCatalogMilitaryArtillery(m);

  return m;
}
