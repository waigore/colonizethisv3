import 'package:colonizethis_app/features/game/flame/game_map_area_state_logic.dart';
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        PlayerView,
        VisibilityLevel,
        buildPlayerView,
        getValidWorkOrderTileKeysWithVisibility,
        kWorkTargetBuildImprovement,
        kWorkTargetBuildRoad,
        kWorkTargetExplore,
        kWorkTargetProspect;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show kUnitTypeBuilder, kUnitTypeExplorer, kUnitTypeMerchant;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

part 'game_map_area_state_logic_test_body_part.g.dart';

/// Expected `provinceBuildImprovementActionState(...).enabled` per **pipeline contract A**
/// ([SPEC/program/order-suggestions.md](../../SPEC/program/order-suggestions.md) § Province Tile
/// `Build improvement` shortcut enablement): same predicate as
/// [GameMapAreaStateLogic.provinceBuildImprovementActionState] — any human Builder whose allowed
/// targets include `build_improvement` has `selectedTileKey` in
/// `getValidWorkOrderTileKeysWithVisibility` for the same `(game, topology, view, orders, tileMap)`.
bool _expectedBuildImprovementEnabledFromPipeline({
  required ct_models.Game game,
  required String humanPlayerId,
  required String selectedTileKey,
  required PlayerView playerView,
  required MapTopology? topology,
  required ct_models.Orders currentOrders,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  if (topology == null) return false;
  final allUnits = <ct_models.Unit>[
    ...game.worldState.oldWorld.units,
    ...game.worldState.newWorld.units,
  ];
  final builderUnits = allUnits
      .where((unit) => unit.ownerId == humanPlayerId)
      .where(
        (unit) =>
            workOrderTargetsByUnitType[unit.type]?.contains(
              kWorkTargetBuildImprovement,
            ) ??
            false,
      )
      .toList();
  if (builderUnits.isEmpty) return false;
  return builderUnits.any((builder) {
    final valid = getValidWorkOrderTileKeysWithVisibility(
      game: game,
      topology: topology,
      view: playerView,
      unitId: builder.id,
      workTarget: kWorkTargetBuildImprovement,
      currentOrders: currentOrders,
      tileMapByRegion: tileMapByRegion,
    );
    return valid.contains(selectedTileKey);
  });
}

void _expectPortFleetMarkersMatchTownPortDrawables(RegionMapViewData region) {
  for (final m in region.fleetTileMarkers) {
    if (!m.locationScopeKey.startsWith('port:')) {
      continue;
    }
    final localProv = m.locationScopeKey.substring(5).split('|').last;
    final towns = region.townMarkers
        .where((t) => t.provinceId == localProv && t.isPort)
        .toList();
    expect(towns, isNotEmpty, reason: 'port town for $localProv');
    final town = towns.single;
    expect(m.x, town.portIconX, reason: 'fleet x vs port icon $localProv');
    expect(m.y, town.portIconY, reason: 'fleet y vs port icon $localProv');
  }
}


void main() {
  _defineTests();
}
