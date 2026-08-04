import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../province_overlay/sea_zone_name_resolver.dart';
import 'naval_tree_builder_models.dart';
import 'naval_tree_builder_support_rows.dart';
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

({String regionId, FleetRow? homeFleet, List<NavalTreeLocationNode> locations})?
navalTreeGroupForRegion({
  required Game game,
  required String humanPlayerId,
  required MapTopology topology,
  required Orders draftOrders,
  required AppLocalizations l10n,
  required Map<String, TileMapResult>? tileMapByRegion,
  required Map<String, MapTopology>? topologyByRegion,
  required String? locationScopeKeyFilter,
  required String regionId,
  required String? capitalRegionId,
  required String? capitalProvinceLocalId,
  required Map<String, Map<String, Province>> provinceByRegionAndId,
  required Map<String, NavalMoveOrder> draftMoveByFleetId,
}) {
  final fleetsInRegion = game.worldState.fleets
      .where(
        (f) =>
            f.ownerId == humanPlayerId &&
            (f.shipTypeIds.isNotEmpty || f.id == homeFleetIdFor(humanPlayerId)),
      )
      .where((fleet) {
        if (locationScopeKeyFilter == null) {
          return fleet.regionId == regionId;
        }
        final projectedScope = navalTreeProjectedLocationScopeForFleet(
          game: game,
          topology: topology,
          fleet: fleet,
          draftMoveByFleetId: draftMoveByFleetId,
        );
        if (projectedScope != locationScopeKeyFilter) {
          return false;
        }
        final scopeRegionId = navalTreeRegionIdFromScopeKey(projectedScope);
        return scopeRegionId == regionId;
      })
      .toList();
  if (fleetsInRegion.isEmpty && capitalRegionId != regionId) {
    return null;
  }

  final homeFleetSlot = <FleetRow?>[null];
  final ports = <String, List<FleetRow>>{};
  final seas = <String, List<FleetRow>>{};

  for (final fleet in fleetsInRegion) {
    final isAtSea = fleet.isAtSea && fleet.seaZoneId != null;
    final inPortId = fleet.inPortAtProvinceId;
    final projectedScope = navalTreeProjectedLocationScopeForFleet(
      game: game,
      topology: topology,
      fleet: fleet,
      draftMoveByFleetId: draftMoveByFleetId,
    );
    if (locationScopeKeyFilter != null &&
        projectedScope != locationScopeKeyFilter) {
      continue;
    }
    final projectedScopeRegionId = navalTreeRegionIdFromScopeKey(projectedScope);
    final rowRegionId = locationScopeKeyFilter != null
        ? (projectedScopeRegionId ?? regionId)
        : regionId;
    final rowTileMap = tileMapByRegion?[rowRegionId];
    final rowTopology = topologyByRegion?[rowRegionId];

    final agg = navalTreeFleetShipAggregates(fleet);

    final atPlayerCapitalPort =
        capitalRegionId != null &&
        capitalProvinceLocalId != null &&
        !isAtSea &&
        rowRegionId == capitalRegionId &&
        inPortId != null &&
        (inPortId == capitalProvinceLocalId ||
            inPortId == '$capitalRegionId|$capitalProvinceLocalId');
    final isHomeFleet =
        fleet.id == homeFleetIdFor(humanPlayerId) && atPlayerCapitalPort;

    if (isAtSea) {
      navalTreeAppendAtSeaFleetRow(
        game: game,
        topology: topology,
        l10n: l10n,
        humanPlayerId: humanPlayerId,
        draftOrders: draftOrders,
        fleet: fleet,
        rowRegionId: rowRegionId,
        projectedScope: projectedScope,
        locationScopeKeyFilter: locationScopeKeyFilter,
        rowTileMap: rowTileMap,
        rowTopology: rowTopology,
        isHomeFleet: isHomeFleet,
        agg: agg,
        seas: seas,
      );
    } else if (inPortId != null) {
      final provinceMap = provinceByRegionAndId[rowRegionId] ?? const {};
      navalTreeAppendInPortFleetRow(
        game: game,
        topology: topology,
        l10n: l10n,
        humanPlayerId: humanPlayerId,
        draftOrders: draftOrders,
        fleet: fleet,
        inPortId: inPortId,
        rowRegionId: rowRegionId,
        projectedScope: projectedScope,
        locationScopeKeyFilter: locationScopeKeyFilter,
        provinceMap: provinceMap,
        isHomeFleet: isHomeFleet,
        agg: agg,
        ports: ports,
        homeFleetSlot: homeFleetSlot,
      );
    }
  }

  final locations = <NavalTreeLocationNode>[];

  final provinceIds = ports.keys.toList()..sort();
  for (final fullProvinceId in provinceIds) {
    final provinceMap = provinceByRegionAndId[regionId] ?? const {};
    final province = provinceMap[fullProvinceId];
    if (province == null) continue;
    final fleets = ports[fullProvinceId]!
      ..sort((a, b) => a.label.compareTo(b.label));
    locations.add(NavalTreePortNode(province: province, fleets: fleets));
  }

  final seaZoneKeys = seas.keys.toList()..sort();
  for (final zoneKey in seaZoneKeys) {
    final zoneLabel = seaZoneDisplayName(
      game: game,
      regionId: regionId,
      seaZoneId: zoneKey,
    );
    final fleets = seas[zoneKey]!..sort((a, b) => a.label.compareTo(b.label));
    locations.add(
      NavalTreeSeaZoneNode(
        seaZoneLabel: zoneLabel,
        regionId: regionId,
        fleets: fleets,
      ),
    );
  }

  final homeFleetRow = homeFleetSlot[0];
  if (homeFleetRow == null && locations.isEmpty) {
    return null;
  }
  return (regionId: regionId, homeFleet: homeFleetRow, locations: locations);
}
