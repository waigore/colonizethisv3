/// Shared per-faction / per-tile traversal helpers for the non-Great-Power
/// extraction flow. Both `computeNonGreatPowerExtraction`
/// (`non_gp_extraction.dart`) and `computeNonGreatPowerAutoOffers`
/// (`non_gp_auto_offers.dart`) compose these helpers so the faction and tile
/// loops are defined once. These symbols are library-internal (`src/`) and are
/// intentionally not re-exported from the package barrel.
library;

export 'non_gp_faction_walk.dart';
export 'non_gp_tile_contribution.dart';
export 'non_gp_tile_walk.dart';
