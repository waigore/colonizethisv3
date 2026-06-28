import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';

import 'commodity_totals.dart';

/// Sea transport: allocate overseas extraction to stockpile by priority. SPEC/program/auto-transport.
///
/// Phase 2: cargo holds derived from home fleet (with stub fallback). Fill by priority until cap; rest left behind.
///
/// Trade/transport interception lives in `trade_interception.dart`.

/// Default cargo holds per player when no ships or no cargoHold data.
/// Sensible default per SPEC/program/extraction-pipeline.md § Cargo holds (GDD convention-over-configuration).
const int defaultCargoHoldsStub = 24;

/// Priority order for filling cargo: food, raw materials, riches, then manufactured/advanced.
/// Note: CommodityCategory.luxury exists but no commodity currently has that category assigned,
/// so it's excluded from priority until luxury is defined in the commodity catalog.
final List<CommodityCategory> _seaPriorityOrder = [
  CommodityCategory.food,
  CommodityCategory.rawMaterial,
  CommodityCategory.riches,
  CommodityCategory.manufactured,
  CommodityCategory.advanced,
];

/// Allocates [overseasTotals] to delivered amounts, filling up to [cargoHolds] units total
/// by [priorityOrder] (default: food, raw, riches, manufactured, advanced).
/// Returns the map of commodity id → quantity to add to stockpile.
Map<CommodityId, int> allocateOverseasToStockpile(
  Map<CommodityId, int> overseasTotals, {
  int cargoHolds = defaultCargoHoldsStub,
  List<CommodityCategory>? priorityOrder,
}) {
  final order = priorityOrder ?? _seaPriorityOrder;
  final remaining = Map<CommodityId, int>.from(overseasTotals);
  var spaceLeft = cargoHolds;
  final delivered = <CommodityId, int>{};

  for (final category in order) {
    if (spaceLeft <= 0) break;
    for (final c in CommodityCatalog.all) {
      if (c.category != category) continue;
      final id = c.id;
      final available = remaining[id] ?? 0;
      if (available <= 0) continue;
      final take = available < spaceLeft ? available : spaceLeft;
      if (take <= 0) continue;
      addUnits(delivered, id, take);
      remaining[id] = available - take;
      spaceLeft -= take;
    }
  }

  return delivered;
}

/// Debug logging for overseas cargo-cap allocation during extraction auto-transport.
/// SPEC/program/auto-transport.md; grep token `extraction auto_transport overseas`.
void logExtractionAutoTransportOverseasAllocation({
  required String playerId,
  required int cargoHolds,
  required Map<CommodityId, int> overseasTotals,
  required Map<CommodityId, int> allocatedToStockpile,
}) {
  if (overseasTotals.isEmpty) return;
  if (economyDebugLogSuppressed) return;
  final overseasTotalUnits = sumValues(overseasTotals.values);
  final allocatedUnits = sumValues(allocatedToStockpile.values);
  final detail = allocatedToStockpile.entries
      .map((e) => '${e.key}=${e.value}')
      .join(',');
  economyLog.d(
    'extraction auto_transport overseas cargo_cap playerId=$playerId '
    'cargoHolds=$cargoHolds overseasTotalUnits=$overseasTotalUnits '
    'allocatedUnits=$allocatedUnits allocatedDetail=$detail',
  );
}

/// Single-pass index of [WorldState.fleets] by fleet id for O(1) lookups (Refs #2394).
///
/// Callers that iterate all players should build once per stable [WorldState] snapshot
/// instead of rescanning [WorldState.fleets] per player.
Map<String, Fleet> fleetsByIdForWorld(WorldState world) {
  return {for (final f in world.fleets) f.id: f};
}

/// Total cargo holds for [playerId] based on ships in the home fleet at the capital port.
///
/// Home fleet convention: fleet id = `fleet_<playerId>`. Each ship's cargoHold is read from
/// NavalStatsCatalog; if no such fleet exists or the sum of cargoHold values is zero, this
/// falls back to [defaultCargoHoldsStub] per SPEC/program/extraction-pipeline.md § Cargo holds.
///
/// When [fleetsById] is supplied (typically from [fleetsByIdForWorld] built once per pass),
/// home-fleet resolution is O(1) instead of scanning [WorldState.fleets] per call.
int cargoHoldsForHomeFleet(
  Game game,
  String playerId, {
  Map<String, Fleet>? fleetsById,
}) {
  final homeFleetId = homeFleetIdFor(playerId);
  final Fleet? homeFleet;
  if (fleetsById != null) {
    final f = fleetsById[homeFleetId];
    homeFleet = (f != null && f.ownerId == playerId) ? f : null;
  } else {
    Fleet? found;
    for (final f in game.worldState.fleets) {
      if (f.id == homeFleetId && f.ownerId == playerId) {
        found = f;
        break;
      }
    }
    homeFleet = found;
  }
  if (homeFleet == null) {
    return defaultCargoHoldsStub;
  }
  var total = 0;
  for (final typeId in homeFleet.shipTypeIds) {
    total += NavalStatsCatalog.get(typeId).cargoHold;
  }
  // When a home fleet exists but has no cargo-capable ships, capacity is 0.
  return total;
}
