import 'package:colonizethis_data/colonizethis_data.dart'
    show UnitRole, unitRoleForType;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/civilian_projected_tile.dart'
    show projectedCivilianTileKey;
import 'package:colonizethis_world/colonizethis_world.dart'
    show WorldStateProvinceLookup;

import '../constants.dart' show kRegionNewWorld, kRegionOldWorld;

/// One human-owned civilian listed in the end-turn idle-work warning.
class CivilianMissingWorkOrderEntry {
  const CivilianMissingWorkOrderEntry({
    required this.unitId,
    required this.type,
    required this.tileKey,
    required this.regionId,
    required this.locationLabel,
  });

  final String unitId;
  final String type;
  final String tileKey;
  final String regionId;
  final String locationLabel;
}

bool isCivilianIdleWithNoPendingWork(
  Unit unit,
  Orders orders,
  String humanPlayerId,
) {
  if (unit.ownerId != humanPlayerId) return false;
  if (unit.tileKey == null || unit.tileKey!.isEmpty) return false;
  if (!_isCivilianUnit(unit)) return false;
  if (unit.status != UnitStatus.idle || unit.currentWork != null) {
    return false;
  }
  final pending = orders.workOrdersByPlayerId[humanPlayerId] ?? const [];
  for (final order in pending) {
    if (order.unitId == unit.id) return false;
  }
  return true;
}

String civilianLocationLabel({
  required String? tileKey,
  required Map<String, String> provinceNames,
}) {
  final regionId = Unit.regionIdFromTileKey(tileKey);
  final provinceId = Unit.provinceIdFromTileKey(tileKey);
  if (regionId == null || provinceId == null) return '—';
  final prefixed = '$regionId|$provinceId';
  final name = provinceNames[prefixed] ?? prefixed;
  return '${_regionDisplayLabel(regionId)} — $name';
}

/// Returns human-owned civilians that are idle with no in-progress work and no
/// draft [WorkOrder], sorted like the civilian-units panel
/// (`province name → type → id`).
List<CivilianMissingWorkOrderEntry> findCiviliansMissingWorkOrders({
  required Game game,
  required Orders orders,
  required String humanPlayerId,
}) {
  final provinceNames = _provinceNamesByPrefixedId(game);
  final units = [
    ...game.worldState.oldWorld.units,
    ...game.worldState.newWorld.units,
  ];
  final sorted = _civilianUnitsInRegion(
    units,
    humanPlayerId,
    provinceNames,
    orders,
  );
  final entries = <CivilianMissingWorkOrderEntry>[];
  for (final unit in sorted) {
    if (!isCivilianIdleWithNoPendingWork(unit, orders, humanPlayerId)) {
      continue;
    }
    final tileKey = projectedCivilianTileKey(
      unit: unit,
      playerId: humanPlayerId,
      orders: orders,
    );
    final regionId = Unit.regionIdFromTileKey(tileKey);
    if (tileKey == null || regionId == null) continue;
    entries.add(
      CivilianMissingWorkOrderEntry(
        unitId: unit.id,
        type: unit.type,
        tileKey: tileKey,
        regionId: regionId,
        locationLabel: civilianLocationLabel(
          tileKey: tileKey,
          provinceNames: provinceNames,
        ),
      ),
    );
  }
  return entries;
}

bool _isCivilianUnit(Unit unit) {
  final role = unitRoleForType(unit.type);
  if (role == null) return false;
  return role != UnitRole.military && role != UnitRole.naval;
}

Map<String, String> _provinceNamesByPrefixedId(Game game) {
  final out = <String, String>{};
  for (final p in game.worldState.allProvinces()) {
    out['${p.regionId}|${p.id}'] = p.displayName ?? p.id;
  }
  return out;
}

String _regionDisplayLabel(String regionId) {
  switch (regionId) {
    case kRegionOldWorld:
      return 'Old World';
    case kRegionNewWorld:
      return 'New World';
    default:
      return regionId;
  }
}

List<Unit> _civilianUnitsInRegion(
  List<Unit> units,
  String humanPlayerId,
  Map<String, String> provinceNames,
  Orders currentOrders,
) {
  final keyed =
      <({Unit unit, String provinceName, String type, String id})>[];
  for (final u in units) {
    if (u.ownerId != humanPlayerId) continue;
    if (u.tileKey == null) continue;
    if (!_isCivilianUnit(u)) continue;
    final tileKey = projectedCivilianTileKey(
      unit: u,
      playerId: humanPlayerId,
      orders: currentOrders,
    );
    final prov = Unit.provinceIdFromTileKey(tileKey);
    final region = Unit.regionIdFromTileKey(tileKey) ?? '';
    final prefixed = '$region|$prov';
    keyed.add((
      unit: u,
      provinceName: provinceNames[prefixed] ?? prefixed,
      type: u.type,
      id: u.id,
    ));
  }
  keyed.sort((a, b) {
    final nameCmp = a.provinceName.compareTo(b.provinceName);
    if (nameCmp != 0) return nameCmp;
    final typeCmp = a.type.compareTo(b.type);
    if (typeCmp != 0) return typeCmp;
    return a.id.compareTo(b.id);
  });
  return [for (final e in keyed) e.unit];
}
