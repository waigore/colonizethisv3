import 'combat_config.dart';
import 'combat_regiment_catalog_era1.dart';
import 'combat_regiment_catalog_era2.dart';
import 'combat_regiment_catalog_era3.dart';
import 'combat_regiment_catalog_era4.dart';

/// Full regiment table: 29 types across 8 categories and 4 eras.
/// SPEC/game/military-units.md. Era rows live in `combat_regiment_catalog_era*.dart`.
const List<RegimentStats> regimentCatalog = [
  ...regimentCatalogEra1,
  ...regimentCatalogEra2,
  ...regimentCatalogEra3,
  ...regimentCatalogEra4,
];
