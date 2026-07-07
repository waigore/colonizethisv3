// Pure data for Military Units panel tree. SPEC/ui/military-units-panel.md.

import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show resolveToFullProvinceId, WorldStateProvinceLookup, WorldStateUnitLookup;
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../../flame/map_state/map_location_resolver.dart';
import '../../province_overlay/sea_zone_name_resolver.dart';
import 'fleet_mission_label.dart';

part 'military_tree_builder_assembly.dart';

String armyStationedProvinceDisplayLabel(Game game, Army army) {
  final pid = army.stationedProvinceId;
  final full = ProvinceId.isPrefixed(pid)
      ? pid
      : ProvinceId.full(army.regionId, pid);
  final p = game.worldState.tryGetProvince(full);
  if (p != null) {
    return p.displayName ?? p.id;
  }
  return full;
}

/// Pending army move line for Military Units (naval draft move parity).
String? armyDraftMoveLineForArmy({
  required Game game,
  required String humanPlayerId,
  required String armyId,
  required Orders draftOrders,
}) {
  final moves = draftOrders.armyMoveOrdersByPlayerId[humanPlayerId] ?? const [];
  for (final o in moves) {
    if (o.armyId != armyId) continue;
    final full = resolveToFullProvinceId(
      game.worldState,
      o.destinationProvinceId,
    );
    final p = game.worldState.tryGetProvince(full);
    final name = p?.displayName ?? p?.id ?? ProvinceId.localIdFrom(full);
    return 'Moving to: $name';
  }
  return null;
}

/// One regiment-type row under an army: type, count, medals, status.
class RegimentTypeRow {
  RegimentTypeRow({
    required this.typeId,
    required this.count,
    required this.medalsSummary,
    required this.statusLabel,
    required this.tileKey,
    required this.regionId,
  });

  final String typeId;
  final int count;
  final String medalsSummary;
  final String statusLabel;
  final String? tileKey;
  final String regionId;
}

/// Ship-type counts at sea within the military panel (aggregated by sea zone).
class MilitarySeaShipRow {
  MilitarySeaShipRow({
    required this.typeId,
    required this.count,
    required this.statusLabel,
    required this.tileKey,
    required this.regionId,
  });

  final String typeId;
  final int count;
  final String statusLabel;
  final String? tileKey;
  final String regionId;
}

/// Province with one or more armies (land).
class ProvinceArmiesNode {
  ProvinceArmiesNode({required this.province, required this.armies});

  final Province province;
  final List<ArmyBlock> armies;

  String get displayLabel => province.displayName ?? province.id;

  String get regionId => province.regionId;
}

class ArmyBlock {
  ArmyBlock({required this.army, required this.rows, required this.regionKey});

  final Army army;
  final List<RegimentTypeRow> rows;

  /// Panel region key: `oldWorld` / `newWorld` (matches [TileMapResult] regions).
  final String regionKey;
}

class MilitarySeaZoneNode {
  MilitarySeaZoneNode({
    required this.seaZoneLabel,
    required this.regionId,
    required this.rows,
  });

  final String seaZoneLabel;
  final String regionId;
  final List<MilitarySeaShipRow> rows;

  String get displayLabel => seaZoneLabel;
}

class RegionMilitaryGroup {
  RegionMilitaryGroup({
    required this.regionKey,
    required this.provinces,
    required this.seaLocations,
  });

  final String regionKey;
  final List<ProvinceArmiesNode> provinces;
  final List<MilitarySeaZoneNode> seaLocations;
}
