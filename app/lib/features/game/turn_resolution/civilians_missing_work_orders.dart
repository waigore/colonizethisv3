import 'package:colonizethis_logic/colonizethis_logic.dart'
    show projectedCivilianTileKey;
import 'package:colonizethis_models/colonizethis_models.dart';

import '../widgets/units/civilian/civilian_units_sort.dart';
import '../widgets/units/shared/region_labels.dart';

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
  if (!isCivilianUnit(unit)) return false;
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
  return '${regionDisplayLabel(regionId)} — $name';
}

/// Returns human-owned civilians that are idle with no in-progress work and no
/// draft [WorkOrder], sorted like [civilianUnitsInRegion].
List<CivilianMissingWorkOrderEntry> findCiviliansMissingWorkOrders({
  required Game game,
  required Orders orders,
  required String humanPlayerId,
}) {
  final provinceNames = provinceNamesByPrefixedId(game);
  final units = [
    ...game.worldState.oldWorld.units,
    ...game.worldState.newWorld.units,
  ];
  final sorted = civilianUnitsInRegion(
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
