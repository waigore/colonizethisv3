/// Tech catalog query, extraction caps, and unlock maps.
/// SPEC/game/tech-and-extraction-cap.md.
///
/// Thin facade: catalog query, extraction-cap table, and derived unlock maps
/// live in sibling libraries. Public symbols stay importable from this library
/// and from `package:colonizethis_data/colonizethis_data.dart`.

export 'tech_catalog_query.dart';
export 'tech_extraction_caps.dart';
export 'tech_unlock_maps.dart';
