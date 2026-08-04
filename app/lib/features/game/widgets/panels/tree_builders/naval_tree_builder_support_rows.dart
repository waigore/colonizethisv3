import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_models/colonizethis_models.dart';

import '../../../flame/map_state/map_location_resolver.dart';
import '../../province_overlay/sea_zone_name_resolver.dart';
import '../../units/shared/region_labels.dart';
import 'fleet_mission_label.dart';
import 'naval_draft_mission_line.dart';
import 'naval_tree_builder_models.dart';
import 'naval_tree_builder_support_scope.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart';
import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart';
import 'package:colonizethis_logic/debug_console_api.dart';
import 'package:colonizethis_orders/src/orders/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_orders/src/orders/civilian_projected_tile.dart';
import 'package:colonizethis_logic/src/turn_to_year.dart';
import 'package:colonizethis_logic/src/civilians/spy_relocate_intel.dart';
import 'package:colonizethis_logic/src/civilians/civilians_missing_work_orders.dart';

void navalTreeAppendAtSeaFleetRow({
  required Game game,
  required MapTopology topology,
  required AppLocalizations l10n,
  required String humanPlayerId,
  required Orders draftOrders,
  required Fleet fleet,
  required String rowRegionId,
  required String? projectedScope,
  required String? locationScopeKeyFilter,
  required TileMapResult? rowTileMap,
  required MapTopology? rowTopology,
  required bool isHomeFleet,
  required ({
    int totalShips,
    int warships,
    int merchants,
    double strength,
    Map<String, int> shipCounts,
    int cargoCapacity,
  })
  agg,
  required Map<String, List<FleetRow>> seas,
}) {
  final seaZoneId =
      locationScopeKeyFilter != null &&
          projectedScope != null &&
          projectedScope.startsWith('sea:')
      ? projectedScope.substring(4)
      : fleet.seaZoneId!;
  final zoneKey = prefixedIdHasDelimiter(seaZoneId)
      ? seaZoneId
      : '$rowRegionId|$seaZoneId';
  final locationKey = 'sea:$zoneKey';
  final zoneLabel = seaZoneDisplayName(
    game: game,
    regionId: rowRegionId,
    seaZoneId: zoneKey,
  );
  final locationLabel =
      '${regionDisplayLabel(rowRegionId)} — $zoneLabel ${l10n.naval_units_locAtSea}';
  final tileKey = tileKeyForNavalFleetAtSea(
    game: game,
    regionId: rowRegionId,
    seaZoneId: zoneKey,
    tileMap: rowTileMap,
    regionTopology: rowTopology,
  );
  final row = FleetRow(
    fleetId: fleet.id,
    label: l10n.naval_fleetLabel(fleet.id),
    locationLabel: locationLabel,
    regionId: rowRegionId,
    missionLabel: fleetMissionDisplayLabel(fleet.mission),
    totalShips: agg.totalShips,
    warshipCount: agg.warships,
    merchantCount: agg.merchants,
    strength: agg.strength,
    tileKey: tileKey,
    isHomeFleet: isHomeFleet,
    shipCountsByType: agg.shipCounts,
    cargoCapacity: agg.cargoCapacity,
    isAtSea: true,
    locationKey: locationKey,
    seaZoneId: zoneKey,
    draftNavalMoveLine: navalDraftMoveLineForFleet(
      game: game,
      topology: topology,
      humanPlayerId: humanPlayerId,
      fleetRegionId: rowRegionId,
      fleetId: fleet.id,
      draftOrders: draftOrders,
    ),
    draftNavalMissionLine: navalDraftMissionLineForFleet(
      game: game,
      humanPlayerId: humanPlayerId,
      fleetId: fleet.id,
      draftOrders: draftOrders,
      l10n: l10n,
    ),
  );
  seas.putIfAbsent(zoneKey, () => []).add(row);
}

void navalTreeAppendInPortFleetRow({
  required Game game,
  required MapTopology topology,
  required AppLocalizations l10n,
  required String humanPlayerId,
  required Orders draftOrders,
  required Fleet fleet,
  required String inPortId,
  required String rowRegionId,
  required String? projectedScope,
  required String? locationScopeKeyFilter,
  required Map<String, Province> provinceMap,
  required bool isHomeFleet,
  required ({
    int totalShips,
    int warships,
    int merchants,
    double strength,
    Map<String, int> shipCounts,
    int cargoCapacity,
  })
  agg,
  required Map<String, List<FleetRow>> ports,
  required List<FleetRow?> homeFleetSlot,
}) {
  final scopePortId =
      locationScopeKeyFilter != null &&
          projectedScope != null &&
          projectedScope.startsWith('port:')
      ? projectedScope.substring(5)
      : null;
  final effectivePortId = scopePortId ?? inPortId;
  final province =
      provinceMap['$rowRegionId|$effectivePortId'] ??
      provinceMap[effectivePortId];
  if (province == null) return;

  final locationKey = navalTreeNormalizedPortScopeForProvince(province);
  final tileKey = tileKeyForProvinceLocation(game, province);
  final locationLabel =
      '${regionDisplayLabel(rowRegionId)} — ${province.displayName ?? province.id} ${l10n.naval_units_locInPort}';
  final row = FleetRow(
    fleetId: fleet.id,
    label: isHomeFleet
        ? l10n.naval_homeFleetLabel
        : l10n.naval_fleetLabel(fleet.id),
    locationLabel: locationLabel,
    regionId: rowRegionId,
    missionLabel: fleetMissionDisplayLabel(fleet.mission),
    totalShips: agg.totalShips,
    warshipCount: agg.warships,
    merchantCount: agg.merchants,
    strength: agg.strength,
    tileKey: tileKey,
    isHomeFleet: isHomeFleet,
    shipCountsByType: agg.shipCounts,
    cargoCapacity: agg.cargoCapacity,
    isAtSea: false,
    locationKey: locationKey,
    inPortAtProvinceId: effectivePortId,
    draftNavalMoveLine: isHomeFleet
        ? null
        : navalDraftMoveLineForFleet(
            game: game,
            topology: topology,
            humanPlayerId: humanPlayerId,
            fleetRegionId: rowRegionId,
            fleetId: fleet.id,
            draftOrders: draftOrders,
          ),
    draftNavalMissionLine: navalDraftMissionLineForFleet(
      game: game,
      humanPlayerId: humanPlayerId,
      fleetId: fleet.id,
      draftOrders: draftOrders,
      l10n: l10n,
    ),
  );
  if (isHomeFleet) {
    homeFleetSlot[0] = row;
    return;
  }
  final fullProvinceId = '${province.regionId}|${province.id}';
  ports.putIfAbsent(fullProvinceId, () => []).add(row);
}
