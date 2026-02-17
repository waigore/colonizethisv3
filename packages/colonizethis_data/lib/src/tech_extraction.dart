/// Tech ids and extraction cap. SPEC/game/tech-and-extraction-cap.md.
///
/// Phase 2: static list and constant cap; full tech tree later.

/// All tech ids (same for every player). Used for tech table keys.
const List<String> techIds = [
  'road_construction',   // improved roads (transport level 2)
  'early_steam_engine',  // railroad (transport level 4)
  'gathering_1',        // extraction cap 2
  'gathering_2',        // extraction cap 3
  'gathering_3',        // extraction cap 4
];

/// Default max effective extraction level when player has no tech or no extraction-cap tech.
/// Imperialism II: production level 0-4; tech caps effective level.
const int defaultExtractionCap = 4;
