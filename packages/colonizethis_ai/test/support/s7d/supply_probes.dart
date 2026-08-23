// S7-D feedstock supply / labour probe helpers (Refs #2847 / #3941).
// Split from `seed42_s7d_feedstock_helpers.dart` for the 1000-line support gate.

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

export 'supply_probes_afford.dart';

/// True iff [playerId] owns at least one province tile that hosts a fabric
/// feedstock resource (a member of [feedstockIds]) whose improvement level
/// satisfies [improvementMatches]. Shared owned-province tile scan backing the
/// three `ownsFeedstock*` probes so the loop lives in one place; an empty
/// [feedstockIds] never matches. Read-only over `(game, playerId)`; no
/// game-state mutation.
bool scanOwnedFeedstockTiles(
  Game game,
  String playerId,
  Set<String> feedstockIds,
  bool Function(int improvementLevel) improvementMatches,
) {
  if (feedstockIds.isEmpty) return false;
  final ws = game.worldState;
  for (final byProvince in ws.tileKeysByRegionAndProvince.values) {
    for (final entry in byProvince.entries) {
      final province = ws.tryGetProvince(entry.key);
      if (province == null || province.ownerId != playerId) continue;
      for (final tileKey in entry.value) {
        final resourceId = ws.resourceByTileKey[tileKey];
        if (resourceId == null || !feedstockIds.contains(resourceId)) {
          continue;
        }
        if (improvementMatches(ws.tileState.improvementLevel(tileKey))) {
          return true;
        }
      }
    }
  }
  return false;
}

/// True iff [playerId] owns at least one province tile that hosts a fabric
/// feedstock resource (a member of [feedstockIds]) and is still unimproved
/// (improvement level < 1) — i.e. a Builder target a lock-recovery seller could
/// extract to feed the `fabricFrom*` recipes. Read-only scan over owned
/// provinces; Refs #2847 H8-supply feedstock-stage diagnostic.
bool ownsUnimprovedFeedstockResourceTile(
  Game game,
  String playerId,
  Set<String> feedstockIds,
) => scanOwnedFeedstockTiles(
  game,
  playerId,
  feedstockIds,
  (improvementLevel) => improvementLevel < 1,
);

/// True iff [playerId] owns at least one province tile that hosts a fabric
/// feedstock resource (a member of [feedstockIds]) that is already improved
/// (improvement level >= 1) — i.e. a Builder has finished extracting the tile.
///
/// Companion to [ownsUnimprovedFeedstockResourceTile] for the H8-extraction
/// execution-gap disambiguation (Refs #2847). When the feedstock-extraction
/// gate is active and an unimproved feedstock tile is owned all run, a near-zero
/// improved-tile count localizes the break to the routing / Builder-availability
/// stage (the Builder never finishes the improvement), whereas a high
/// improved-tile count alongside a near-zero `gpFeedstockInStockpileTurns`
/// localizes it to the extraction / transport-connectivity stage (the improved
/// tile yields no commodity into the stockpile because it is not extraction-
/// connected). Read-only scan over owned provinces.
bool ownsImprovedFeedstockResourceTile(
  Game game,
  String playerId,
  Set<String> feedstockIds,
) => scanOwnedFeedstockTiles(
  game,
  playerId,
  feedstockIds,
  (improvementLevel) => improvementLevel >= 1,
);

/// True iff [playerId] owns at least one Builder unit that currently has no
/// work assigned (`currentWork == null`) — i.e. a Builder the Full-AI civilian
/// work selection could route onto a feedstock tile this turn.
///
/// Used by the H8-extraction execution-gap disambiguation (Refs #2847): a
/// near-zero count on feedstock-gate-active turns localizes the break to
/// Builder availability (no free Builder to route), distinguishing it from the
/// "Builder present but improvement never completes / extracts" cases. Read-only
/// scan over all world units.
bool hasIdleBuilderUnit(Game game, String playerId) {
  for (final unit in allUnitsFromWorld(game.worldState)) {
    if (unit.ownerId != playerId) continue;
    if (unit.type != kUnitTypeBuilder) continue;
    if (unit.currentWork == null) return true;
  }
  return false;
}

/// True iff [playerId] owns at least one non-home (field) army — an army the
/// stalled-expansion conquest army-move planner could march onto a conquest
/// target this turn.
///
/// Used by the H8-extraction acquisition-thread localization (Refs #2847):
/// when a flagged below-quota zero-NW lock-recovery seller has a non-null
/// `expandSellerFeedstockTileAcquisitionTarget` (the post-#3273 declare-war and
/// post-#3274 army-move bias have a feedstock province to pursue) yet never
/// completes the acquisition, a near-zero field-army count localizes the
/// residual to "no field army available to execute the march" (peer-war
/// regiment attrition), distinguishing it from "army present but the
/// march/capture never completes" downstream of the army-move bias. Mirrors
/// the field-army filter `runConquestArmyMovePlanner` applies
/// (`army.ownerId == playerId && !army.isHomeArmy`). Read-only scan over world
/// armies.
bool hasFieldArmy(Game game, String playerId) {
  for (final army in game.worldState.armies) {
    if (army.ownerId != playerId) continue;
    if (army.isHomeArmy) continue;
    return true;
  }
  return false;
}
