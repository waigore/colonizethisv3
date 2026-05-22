// Pure helpers for civilian-units-panel ordering. Extracted so that sort
// behavior can be unit-tested without instantiating the full panel widget.
//
// SPEC/ui/civilian-units-panel.md.
// Refs #2575 (Phase 2 Schwartzian transform + Phase 4 testability).

import 'package:colonizethis_data/colonizethis_data.dart'
    show UnitRole, unitRoleForType;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show projectedCivilianTileKey;
import 'package:colonizethis_models/colonizethis_models.dart';

/// Builds prefixed province id (`regionId|provinceId`) → display name from
/// [game]. Falls back to the province id when display name is null. Used by
/// civilian-units-panel rendering and by sort key resolution.
Map<String, String> provinceNamesByPrefixedId(Game game) {
  final out = <String, String>{};
  for (final p in game.worldState.oldWorld.provinces) {
    out['${p.regionId}|${p.id}'] = p.displayName ?? p.id;
  }
  for (final p in game.worldState.newWorld.provinces) {
    out['${p.regionId}|${p.id}'] = p.displayName ?? p.id;
  }
  return out;
}

/// Returns true if [unit] is a civilian (not military, not naval).
/// SPEC/game/civilian-units.md.
bool isCivilianUnit(Unit unit) {
  final role = unitRoleForType(unit.type);
  if (role == null) return false;
  return role != UnitRole.military && role != UnitRole.naval;
}

/// Province sort key for civilian [unit] — uses the **projected** tile key so
/// that a pending civilian work order is reflected in the displayed ordering.
/// Falls back to `regionId|provinceId` when no display name is available.
String civilianSortProvinceName(
  Unit unit, {
  required String humanPlayerId,
  required Orders currentOrders,
  required Map<String, String> provinceNames,
}) {
  final tileKey = projectedCivilianTileKey(
    unit: unit,
    playerId: humanPlayerId,
    orders: currentOrders,
  );
  final prov = Unit.provinceIdFromTileKey(tileKey);
  final region = Unit.regionIdFromTileKey(tileKey) ?? '';
  final prefixed = '$region|$prov';
  return provinceNames[prefixed] ?? prefixed;
}

/// Civilian units owned by one of [ownerIds] in the supplied region list,
/// sorted by **province name → type → id**.
List<Unit> civilianUnitsInRegionForOwners(
  List<Unit> units,
  Set<String> ownerIds,
  Map<String, String> provinceNames,
  Orders currentOrders,
) {
  final keyed =
      <({Unit unit, String provinceName, String type, String id})>[];
  for (final u in units) {
    if (!ownerIds.contains(u.ownerId)) continue;
    if (u.tileKey == null) continue;
    if (!isCivilianUnit(u)) continue;
    keyed.add((
      unit: u,
      provinceName: civilianSortProvinceName(
        u,
        humanPlayerId: u.ownerId,
        currentOrders: currentOrders,
        provinceNames: provinceNames,
      ),
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

/// Civilian units owned by [humanPlayerId] in the supplied region list,
/// sorted by **province name → type → id**. Pre-computes the sort keys once
/// per unit (Schwartzian transform) to avoid O(n log n × k) work in the
/// comparator. SPEC/ui/civilian-units-panel.md; Refs #2575 AC #4 / #6.
List<Unit> civilianUnitsInRegion(
  List<Unit> units,
  String humanPlayerId,
  Map<String, String> provinceNames,
  Orders currentOrders,
) =>
    civilianUnitsInRegionForOwners(
      units,
      {humanPlayerId},
      provinceNames,
      currentOrders,
    );
