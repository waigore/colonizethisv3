/// Shared constants and helpers for the colonizethis_logic package.

import 'package:colonizethis_models/colonizethis_models.dart';

const String kRegionOldWorld = 'oldWorld';
const String kRegionNewWorld = 'newWorld';

/// Shared set of mineral resource ids used across extraction, work orders,
/// and order application helpers. SPEC/game/resources-and-economy.md.
const Set<String> kMineralResourceIds = {
  'iron',
  'copper',
  'tin',
  'coal',
  'silver',
  'gold',
  'gems',
  'diamonds',
};

/// Safe player lookup by id. Returns null if not found.
extension GamePlayerLookup on Game {
  Player? playerById(String id) {
    for (final p in players) {
      if (p.id == id) return p;
    }
    return null;
  }
}
