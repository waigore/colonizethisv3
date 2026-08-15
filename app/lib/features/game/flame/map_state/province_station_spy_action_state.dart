import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// MAP20001 Civilian **Station spy** visibility/enablement (Refs #4439).
///
/// Cheap occupancy + idle-Spy predicates only — no order-suggestion engine.
enum ProvinceStationSpyDisabledReason { noIdleSpy, tileNotOccupiable }

class ProvinceStationSpyActionState {
  const ProvinceStationSpyActionState({
    required this.showControl,
    required this.enabled,
    this.disabledReason,
  });

  final bool showControl;
  final bool enabled;
  final ProvinceStationSpyDisabledReason? disabledReason;

  static const hidden = ProvinceStationSpyActionState(
    showControl: false,
    enabled: false,
  );
}

/// Hide > disabled > enabled. Destination is the exact [selectedTileKey].
ProvinceStationSpyActionState computeProvinceStationSpyActionState({
  required Game game,
  required Orders orders,
  required String humanPlayerId,
  required String? selectedTileKey,
  required bool canMutateViaUi,
  required bool isSeaZone,
  required bool tileObfuscated,
  required bool civilianSectionObfuscated,
}) {
  final tileKey = selectedTileKey;
  if (!canMutateViaUi ||
      isSeaZone ||
      civilianSectionObfuscated ||
      tileObfuscated ||
      tileKey == null ||
      tileKey.isEmpty) {
    return ProvinceStationSpyActionState.hidden;
  }

  final occupiable = civilianMayOccupyLandTileKey(
    game: game,
    playerId: humanPlayerId,
    unitType: kUnitTypeSpy,
    destinationTileKey: tileKey,
  );
  final eligible = _eligibleRelocators(
    game: game,
    orders: orders,
    humanPlayerId: humanPlayerId,
    selectedTileKey: tileKey,
    occupiable: occupiable,
  );
  final ownSpyOnTile = _ownSpyCurrentlyOnTile(
    game: game,
    humanPlayerId: humanPlayerId,
    selectedTileKey: tileKey,
  );
  if (ownSpyOnTile && eligible.isEmpty) {
    return ProvinceStationSpyActionState.hidden;
  }
  if (eligible.isNotEmpty) {
    return const ProvinceStationSpyActionState(
      showControl: true,
      enabled: true,
    );
  }
  return ProvinceStationSpyActionState(
    showControl: true,
    enabled: false,
    disabledReason: occupiable
        ? ProvinceStationSpyDisabledReason.noIdleSpy
        : ProvinceStationSpyDisabledReason.tileNotOccupiable,
  );
}

bool stationSpyUnitIsEligibleRelocator({
  required Game game,
  required Orders orders,
  required String humanPlayerId,
  required Unit unit,
  required String selectedTileKey,
}) {
  if (!isSpyUnit(unit.type) || unit.ownerId != humanPlayerId) return false;
  if (unit.status != UnitStatus.idle || unit.currentWork != null) return false;
  if (pendingWorkOrderForUnit(
        playerId: humanPlayerId,
        unitId: unit.id,
        orders: orders,
      ) !=
      null) {
    return false;
  }
  if (pendingMoveOrderForUnit(
        playerId: humanPlayerId,
        unitId: unit.id,
        orders: orders,
      ) !=
      null) {
    return false;
  }
  final projected = projectedCivilianTileKey(
    unit: unit,
    playerId: humanPlayerId,
    orders: orders,
  );
  if (projected == selectedTileKey) return false;
  return civilianMayOccupyLandTileKey(
    game: game,
    playerId: humanPlayerId,
    unitType: unit.type,
    destinationTileKey: selectedTileKey,
  );
}

List<Unit> _eligibleRelocators({
  required Game game,
  required Orders orders,
  required String humanPlayerId,
  required String selectedTileKey,
  required bool occupiable,
}) {
  if (!occupiable) return const [];
  return [
    for (final unit in _humanSpies(game, humanPlayerId))
      if (stationSpyUnitIsEligibleRelocator(
        game: game,
        orders: orders,
        humanPlayerId: humanPlayerId,
        unit: unit,
        selectedTileKey: selectedTileKey,
      ))
        unit,
  ];
}

bool _ownSpyCurrentlyOnTile({
  required Game game,
  required String humanPlayerId,
  required String selectedTileKey,
}) {
  for (final unit in _humanSpies(game, humanPlayerId)) {
    if (unit.tileKey == selectedTileKey) return true;
  }
  return false;
}

List<Unit> _humanSpies(Game game, String humanPlayerId) {
  return [
    for (final unit in game.worldState.oldWorld.units)
      if (unit.ownerId == humanPlayerId && isSpyUnit(unit.type)) unit,
    for (final unit in game.worldState.newWorld.units)
      if (unit.ownerId == humanPlayerId && isSpyUnit(unit.type)) unit,
  ];
}
