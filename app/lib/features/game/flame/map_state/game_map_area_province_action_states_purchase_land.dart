import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import 'game_map_area_province_action_states_assignable.dart'
    show GameMapAreaProvinceActionStatesAssignable, ProvinceInlineActionState;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_logic/ai_api.dart';

/// Purchase-land inline-action visibility/enablement for province overlay.
abstract final class GameMapAreaProvinceActionStatesPurchaseLand {
  static ProvinceInlineActionState compute({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required PlayerView playerView,
    PerPlayerWorkTargetSelectionCache? workTargetSelectionCache,
    MapTopology? topology,
    ct_models.Orders currentOrders = const ct_models.Orders(),
    Map<String, TileMapResult>? tileMapByRegion,
  }) {
    final parsed = tryParseTileKey(selectedTileKey);
    if (parsed == null) {
      return GameMapAreaProvinceActionStatesAssignable.kHidden;
    }
    if (playerView.visibilityForTile(selectedTileKey) ==
        VisibilityLevel.unknown) {
      return GameMapAreaProvinceActionStatesAssignable.kHidden;
    }
    final province = game.worldState.tryGetProvince(parsed.prefixedProvinceId);
    if (province == null) {
      return GameMapAreaProvinceActionStatesAssignable.kHidden;
    }
    final ownerId = province.ownerId;
    if (ownerId == null ||
        ownerId.isEmpty ||
        ownerId == humanPlayerId ||
        !isMinorOrTribe(game, ownerId)) {
      return GameMapAreaProvinceActionStatesAssignable.kHidden;
    }
    final resourceId = game.worldState.resourceByTileKey[selectedTileKey];
    if (resourceId == null || resourceId.isEmpty) {
      return GameMapAreaProvinceActionStatesAssignable.kHidden;
    }
    final resourceVisible = resourceIdVisibleInPlayerView(
      playerView,
      selectedTileKey,
      resourceId,
    );
    if (resourceVisible == null) {
      return GameMapAreaProvinceActionStatesAssignable.kHidden;
    }

    final state = GameMapAreaProvinceActionStatesAssignable.compute(
      game: game,
      humanPlayerId: humanPlayerId,
      selectedTileKey: selectedTileKey,
      playerView: playerView,
      workTarget: kWorkTargetPurchaseLand,
      workTargetSelectionCache: workTargetSelectionCache,
      topology: topology,
      currentOrders: currentOrders,
      tileMapByRegion: tileMapByRegion,
      passesTileGate: () => true,
    );
    if (!state.showIcon && !state.enabled && !state.hasMatchingUnits) {
      return GameMapAreaProvinceActionStatesAssignable.kHidden;
    }
    return state;
  }
}
