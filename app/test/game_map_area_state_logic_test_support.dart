// Shared helpers for the `game_map_area_state_logic_part*_test.dart` family.
// Lives outside `app/test/support/` so state-logic expectation helpers do not
// count toward `repo.app_test_support_loc`. Re-exported from
// `app/test/support/game_map_area_state_logic_test_support.dart` (Refs #4013).
// Scenario fixtures: game_map_area_state_logic_test_scenarios.dart (Refs #4183).

export 'game_map_area_state_logic_test_scenarios.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        PlayerView,
        getValidWorkOrderTileKeysWithVisibility,
        kWorkTargetBuildImprovement;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Expected `provinceBuildImprovementActionState(...).enabled` per **pipeline
/// contract A** (`SPEC/program/order-suggestions.md` Province Tile
/// `Build improvement` shortcut enablement): same predicate as
/// `GameMapAreaStateLogic.provinceBuildImprovementActionState` — any human
/// Builder whose allowed targets include `build_improvement` has
/// `selectedTileKey` in `getValidWorkOrderTileKeysWithVisibility` for the same
/// `(game, topology, view, orders, tileMap)`.
bool expectedBuildImprovementEnabledFromPipeline({
  required Game game,
  required String humanPlayerId,
  required String selectedTileKey,
  required PlayerView playerView,
  required MapTopology? topology,
  required Orders currentOrders,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  if (topology == null) return false;
  final allUnits = <Unit>[
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

/// Asserts every in-port fleet tile marker is co-located with the matching
/// town port drawable ([TownMarkerView.portIconX] / [TownMarkerView.portIconY]).
void expectPortFleetMarkersMatchTownPortDrawables(RegionMapViewData region) {
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
