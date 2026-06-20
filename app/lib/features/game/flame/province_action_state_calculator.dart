import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import '../../../core/services/game_service.dart' show GameMapData;
import 'game_map_area_state_logic.dart';
import 'per_player_work_target_selection_cache.dart';

/// Explore / prospect inline action state shape (shared by both overlay slots).
typedef ProvinceExplorerActionState = ({
  bool showIcon,
  bool enabled,
  bool hasExplorerUnits,
});

/// Build-improvement inline action state shape.
typedef ProvinceBuilderActionState = ({
  bool showIcon,
  bool enabled,
  bool hasBuilderUnits,
});

/// The three province-overlay inline action states computed together.
typedef ProvinceActionStates = ({
  ProvinceExplorerActionState explore,
  ProvinceExplorerActionState prospect,
  ProvinceBuilderActionState buildImprovement,
});

/// Computes the explore / prospect / build-improvement inline action states
/// for the province detail overlay.
///
/// Both the narrow bottom-sheet host
/// ([`GameMapNarrowDetailOverlaySlot`](game_map_narrow_detail_overlay.dart))
/// and the wide side panel
/// ([`GameMapProvinceDetailSidePanel`](game_map_province_detail_side_panel.dart))
/// previously duplicated this identical computation (issue #3279 work item 4).
/// The only differences between the two hosts are the slide axis and wrapper
/// sizing, not the action-state logic, so the shared computation lives here.
///
/// Behavior is unchanged: each state forwards to the matching
/// [GameMapAreaStateLogic] entry point, and a `null` [selectedTileKey] yields
/// the canonical hidden defaults.
class ProvinceActionStateCalculator {
  const ProvinceActionStateCalculator._();

  /// Returns the explore, prospect, and build-improvement states.
  ///
  /// When [selectedTileKey] is `null` the hidden default states are returned
  /// without invoking the order-engine validation pipeline.
  static ProvinceActionStates compute({
    required ct_models.Game game,
    required String humanPlayerId,
    required String? selectedTileKey,
    required RegionMapViewData region,
    required PlayerView playerView,
    required ct_models.Orders currentOrders,
    required PerPlayerWorkTargetSelectionCache workTargetSelectionCache,
    required GameMapData? mapData,
  }) {
    final topology = mapData?.combinedTopology;
    final explore = selectedTileKey == null
        ? GameMapAreaStateLogic.kHiddenExplorerInlineActionState
        : GameMapAreaStateLogic.provinceExploreActionState(
            game: game,
            humanPlayerId: humanPlayerId,
            selectedTileKey: selectedTileKey,
            selectedRegion: region,
            workTargetSelectionCache: workTargetSelectionCache,
          );
    final prospect = selectedTileKey == null
        ? GameMapAreaStateLogic.kHiddenExplorerInlineActionState
        : GameMapAreaStateLogic.provinceProspectActionState(
            game: game,
            humanPlayerId: humanPlayerId,
            selectedTileKey: selectedTileKey,
            playerView: playerView,
            topology: topology,
            currentOrders: currentOrders,
            tileMapByRegion: mapData?.tileMapByRegion,
          );
    // Behavior parity: both overlay hosts call `provinceBuildImprovementActionState`
    // with only the unit/selection inputs, leaving `topology`/`currentOrders`/
    // `tileMapByRegion` at their defaults. Do not widen this call.
    final buildImprovement = selectedTileKey == null
        ? GameMapAreaStateLogic.kHiddenBuilderInlineActionState
        : GameMapAreaStateLogic.provinceBuildImprovementActionState(
            game: game,
            humanPlayerId: humanPlayerId,
            selectedTileKey: selectedTileKey,
            playerView: playerView,
            workTargetSelectionCache: workTargetSelectionCache,
          );
    return (
      explore: explore,
      prospect: prospect,
      buildImprovement: buildImprovement,
    );
  }
}
