import 'tech_definition.dart';
import 'tech_catalog_chunks_new_world_harvest_ore.dart';
import 'tech_catalog_chunks_new_world_plantations.dart';

void addTechCatalogNewWorld(Map<String, TechDefinition> m) {
  addTechCatalogNewWorldPlantations(m);
  addTechCatalogNewWorldHarvestAndOre(m);
}
