// Grandfather allowlist: tech_catalog cluster still mid-migration (Refs #4121).
// Shrink-only: remove entries as de-part slices land.
const List<String> dataNoPartDirectivesGrandfatheredForTests = <String>[
  'packages/colonizethis_data/lib/src/tech_catalog.dart',
  'packages/colonizethis_data/lib/src/tech_catalog_chunks.dart',
  'packages/colonizethis_data/lib/src/tech_catalog_chunks_economy.dart',
  'packages/colonizethis_data/lib/src/tech_catalog_chunks_gathering.dart',
];
