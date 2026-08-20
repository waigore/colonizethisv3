import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import '../../../../core/services/game_service/game_service.dart'
    show GameMapData;
import 'game_map_area_state_logic.dart';
import '../caches/per_player_work_target_selection_cache.dart';
import 'game_map_area_province_action_states_assignable.dart'
    show GameMapAreaProvinceActionStatesAssignable, ProvinceInlineActionState;
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;

export 'game_map_area_province_action_states_assignable.dart'
    show ProvinceInlineActionState;

/// Canonical hidden defaults for all eight civilian inline-action slots.
const ProvinceActionStates kHiddenProvinceActionStates = (
  explore: GameMapAreaProvinceActionStatesAssignable.kHidden,
  prospect: GameMapAreaProvinceActionStatesAssignable.kHidden,
  buildImprovement: GameMapAreaProvinceActionStatesAssignable.kHidden,
  buildRoad: GameMapAreaProvinceActionStatesAssignable.kHidden,
  buildFort: GameMapAreaProvinceActionStatesAssignable.kHidden,
  buildPort: GameMapAreaProvinceActionStatesAssignable.kHidden,
  buildRail: GameMapAreaProvinceActionStatesAssignable.kHidden,
  purchaseLand: GameMapAreaProvinceActionStatesAssignable.kHidden,
);

/// The eight province-overlay civilian inline action states computed together.
typedef ProvinceActionStates = ({
  ProvinceInlineActionState explore,
  ProvinceInlineActionState prospect,
  ProvinceInlineActionState buildImprovement,
  ProvinceInlineActionState buildRoad,
  ProvinceInlineActionState buildFort,
  ProvinceInlineActionState buildPort,
  ProvinceInlineActionState buildRail,
  ProvinceInlineActionState purchaseLand,
});

/// Gated copy for UI overlay: [showIcon]/[enabled] respect [canMutateViaUi];
/// [hasMatchingUnits] stays ungated (tooltip/disabled-icon affordance parity).
ProvinceActionStates gateProvinceInlineActionsForUi({
  required ProvinceActionStates states,
  required bool canMutateViaUi,
}) {
  ProvinceInlineActionState gate(ProvinceInlineActionState state) => (
    showIcon: canMutateViaUi && state.showIcon,
    enabled: canMutateViaUi && state.enabled,
    hasMatchingUnits: state.hasMatchingUnits,
  );
  return (
    explore: gate(states.explore),
    prospect: gate(states.prospect),
    buildImprovement: gate(states.buildImprovement),
    buildRoad: gate(states.buildRoad),
    buildFort: gate(states.buildFort),
    buildPort: gate(states.buildPort),
    buildRail: gate(states.buildRail),
    purchaseLand: gate(states.purchaseLand),
  );
}

/// Computes the explore / prospect / build-improvement inline action states
/// for the province detail overlay.
///
/// Both the narrow bottom-sheet host
/// ([`GameMapNarrowDetailOverlay`](game_map_narrow_detail_overlay.dart))
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
        ? GameMapAreaProvinceActionStatesAssignable.kHidden
        : GameMapAreaStateLogicProvinceActions.provinceExploreActionState(
            game: game,
            humanPlayerId: humanPlayerId,
            selectedTileKey: selectedTileKey,
            selectedRegion: region,
            workTargetSelectionCache: workTargetSelectionCache,
          );
    final prospect = selectedTileKey == null
        ? GameMapAreaProvinceActionStatesAssignable.kHidden
        : GameMapAreaStateLogicProvinceActions.provinceProspectActionState(
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
        ? GameMapAreaProvinceActionStatesAssignable.kHidden
        : GameMapAreaStateLogicProvinceActions.provinceBuildImprovementActionState(
            game: game,
            humanPlayerId: humanPlayerId,
            selectedTileKey: selectedTileKey,
            playerView: playerView,
            workTargetSelectionCache: workTargetSelectionCache,
          );
    final buildRoad = selectedTileKey == null
        ? GameMapAreaProvinceActionStatesAssignable.kHidden
        : GameMapAreaStateLogicProvinceActions.provinceBuildRoadActionState(
            game: game,
            humanPlayerId: humanPlayerId,
            selectedTileKey: selectedTileKey,
            playerView: playerView,
            workTargetSelectionCache: workTargetSelectionCache,
          );
    final buildFort = selectedTileKey == null
        ? GameMapAreaProvinceActionStatesAssignable.kHidden
        : GameMapAreaStateLogicProvinceActions.provinceBuildFortActionState(
            game: game,
            humanPlayerId: humanPlayerId,
            selectedTileKey: selectedTileKey,
            playerView: playerView,
            workTargetSelectionCache: workTargetSelectionCache,
          );
    final buildPort = selectedTileKey == null
        ? GameMapAreaProvinceActionStatesAssignable.kHidden
        : GameMapAreaStateLogicProvinceActions.provinceBuildPortActionState(
            game: game,
            humanPlayerId: humanPlayerId,
            selectedTileKey: selectedTileKey,
            playerView: playerView,
            workTargetSelectionCache: workTargetSelectionCache,
            topology: topology,
            currentOrders: currentOrders,
            tileMapByRegion: mapData?.tileMapByRegion,
          );
    final buildRail = selectedTileKey == null
        ? GameMapAreaProvinceActionStatesAssignable.kHidden
        : GameMapAreaStateLogicProvinceActions.provinceBuildRailActionState(
            game: game,
            humanPlayerId: humanPlayerId,
            selectedTileKey: selectedTileKey,
            playerView: playerView,
            workTargetSelectionCache: workTargetSelectionCache,
            topology: topology,
            currentOrders: currentOrders,
            tileMapByRegion: mapData?.tileMapByRegion,
          );
    final purchaseLand = selectedTileKey == null
        ? GameMapAreaProvinceActionStatesAssignable.kHidden
        : GameMapAreaStateLogicProvinceActions.provincePurchaseLandActionState(
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
      buildRoad: buildRoad,
      buildFort: buildFort,
      buildPort: buildPort,
      buildRail: buildRail,
      purchaseLand: purchaseLand,
    );
  }
}
