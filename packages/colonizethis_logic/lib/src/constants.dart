/// Shared constants and helpers for the colonizethis_logic package.

import 'package:colonizethis_models/colonizethis_models.dart';

const String kRegionOldWorld = 'oldWorld';
const String kRegionNewWorld = 'newWorld';

/// Resource ids that count as minerals for work/purchase rules.
/// Shared across extraction, work orders, and order application helpers.
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
