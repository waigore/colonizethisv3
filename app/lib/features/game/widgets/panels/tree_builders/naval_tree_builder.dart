// Pure data for Naval Units panel tree. SPEC/ui/naval-units-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        GamePlayerLookup,
        homeFleetIdFor,
        kRegionNewWorld,
        kRegionOldWorld,
        regionIdForSeaZone,
        WorldStateProvinceLookup;
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../../flame/map_state/map_location_resolver.dart';
import '../../province_overlay/sea_zone_name_resolver.dart';
import '../../units/shared/region_labels.dart';
import 'fleet_mission_label.dart';
import 'draft_move_destination_line.dart';

part 'naval_tree_builder_models.dart';
part 'naval_tree_builder_support_scope.dart';
part 'naval_tree_builder_support_rows.dart';
part 'naval_tree_builder_support_group.dart';

List<
  ({
    String regionId,
    FleetRow? homeFleet,
    List<NavalTreeLocationNode> locations,
  })
>
buildNavalTree(
  Game game,
  String humanPlayerId,
  MapTopology topology,
  Orders draftOrders,
  AppLocalizations l10n, {
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, MapTopology>? topologyByRegion,
  String? locationScopeKeyFilter,
}) {
  final player = game.playerById(humanPlayerId) ?? game.players.first;
  final capParts = _capitalTileRegionParts(player.capitalTile);
  final capitalRegionId = capParts.regionId;
  final capitalProvinceLocalId = capParts.localId;

  final result =
      <
        ({
          String regionId,
          FleetRow? homeFleet,
          List<NavalTreeLocationNode> locations,
        })
      >[];

  final provinceByRegionAndId = <String, Map<String, Province>>{
    kRegionOldWorld: {
      for (final p in game.worldState.oldWorld.provinces)
        '${p.regionId}|${p.id}': p,
      for (final p in game.worldState.oldWorld.provinces) p.id: p,
    },
    kRegionNewWorld: {
      for (final p in game.worldState.newWorld.provinces)
        '${p.regionId}|${p.id}': p,
      for (final p in game.worldState.newWorld.provinces) p.id: p,
    },
  };

  final draftMoveByFleetId = <String, NavalMoveOrder>{
    for (final order
        in draftOrders.navalMoveOrdersByPlayerId[humanPlayerId] ?? const [])
      order.fleetId: order,
  };

  game.worldState.forEachRegion((regionId, _) {
    final group = _navalTreeGroupForRegion(
      game: game,
      humanPlayerId: humanPlayerId,
      topology: topology,
      draftOrders: draftOrders,
      l10n: l10n,
      tileMapByRegion: tileMapByRegion,
      topologyByRegion: topologyByRegion,
      locationScopeKeyFilter: locationScopeKeyFilter,
      regionId: regionId,
      capitalRegionId: capitalRegionId,
      capitalProvinceLocalId: capitalProvinceLocalId,
      provinceByRegionAndId: provinceByRegionAndId,
      draftMoveByFleetId: draftMoveByFleetId,
    );
    if (group != null) {
      result.add(group);
    }
  });

  return result;
}
