import 'package:colonizethis_app/core/utils/human_units_for_work_target.dart';
import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import 'game_map_area_province_action_states_assignable.dart'
    show GameMapAreaProvinceActionStatesAssignable, ProvinceInlineActionState;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';

/// Prospect inline-action visibility/enablement for province overlay.
abstract final class GameMapAreaProvinceActionStatesProspect {
  /// Returns province-overlay prospect action visibility + enablement.
  ///
  /// The panel must read stable world/player tile state only so map scrolling
  /// and rebuild churn do not trigger expensive order-engine validation.
  static ProvinceInlineActionState compute({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required PlayerView playerView,
    required MapTopology? topology,
    required ct_models.Orders currentOrders,
    required Map<String, TileMapResult>? tileMapByRegion,
  }) {
    final parsed = tryParseTileKey(selectedTileKey);
    if (parsed == null) {
      return GameMapAreaProvinceActionStatesAssignable.kHidden;
    }
    final tileVisibility = playerView.visibilityForTile(selectedTileKey);
    if (tileVisibility == VisibilityLevel.unknown) {
      return GameMapAreaProvinceActionStatesAssignable.kHidden;
    }
    final prefixedProvinceId = parsed.prefixedProvinceId;
    final isProvinceTile =
        game.worldState.tryGetProvince(prefixedProvinceId) != null;
    if (!isProvinceTile) {
      return GameMapAreaProvinceActionStatesAssignable.kHidden;
    }

    final isMineralEligible = isMineralEligibleTile(
      game,
      tileMapByRegion,
      selectedTileKey,
    );
    if (!isMineralEligible) {
      return GameMapAreaProvinceActionStatesAssignable.kHidden;
    }

    final playerProspectedTiles =
        game.worldState.playerProspectedTiles[humanPlayerId] ??
        const <String>{};
    if (playerProspectedTiles.contains(selectedTileKey)) {
      return GameMapAreaProvinceActionStatesAssignable.kHidden;
    }

    final explorerUnits = humanUnitsMatchingWorkTarget(
      game: game,
      playerId: humanPlayerId,
      workTarget: kWorkTargetProspect,
    );
    if (explorerUnits.isEmpty) {
      return (showIcon: true, enabled: false, hasMatchingUnits: false);
    }
    // Refs #3753 R4/R4b: prospect inside a Minor/Tribe province requires a
    // Consulate (or higher). The prospect enablement does not flow through the
    // work-order validator, so apply the shared Consulate gate here to keep the
    // inline action disabled (rather than enabled-then-rejected) — the overlay
    // surfaces the rejection tooltip.
    final prospectOwnerId = game.worldState
        .tryGetProvince(prefixedProvinceId)
        ?.ownerId;
    if (explorerConsulateGateBlocksMinorTribeProvince(
      game: game,
      playerId: humanPlayerId,
      provinceOwnerId: prospectOwnerId,
    )) {
      return (showIcon: true, enabled: false, hasMatchingUnits: true);
    }
    return (showIcon: true, enabled: true, hasMatchingUnits: true);
  }
}
