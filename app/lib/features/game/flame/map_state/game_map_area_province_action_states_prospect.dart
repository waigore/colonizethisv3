import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import 'game_map_area_province_action_states.dart';
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

/// Prospect inline-action visibility/enablement for province overlay.
abstract final class GameMapAreaProvinceActionStatesProspect {
  /// Returns province-overlay prospect action visibility + enablement.
  ///
  /// The panel must read stable world/player tile state only so map scrolling
  /// and rebuild churn do not trigger expensive order-engine validation.
  static ({bool showIcon, bool enabled, bool hasExplorerUnits}) compute({
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
      return (showIcon: false, enabled: false, hasExplorerUnits: false);
    }
    final tileVisibility = playerView.visibilityForTile(selectedTileKey);
    if (tileVisibility == VisibilityLevel.unknown) {
      return (showIcon: false, enabled: false, hasExplorerUnits: false);
    }
    final prefixedProvinceId = parsed.prefixedProvinceId;
    final isProvinceTile =
        game.worldState.tryGetProvince(prefixedProvinceId) != null;
    if (!isProvinceTile) {
      return (showIcon: false, enabled: false, hasExplorerUnits: false);
    }

    final isMineralEligible = isMineralEligibleTile(
      game,
      tileMapByRegion,
      selectedTileKey,
    );
    if (!isMineralEligible) {
      return (showIcon: false, enabled: false, hasExplorerUnits: false);
    }

    final playerProspectedTiles =
        game.worldState.playerProspectedTiles[humanPlayerId] ??
        const <String>{};
    if (playerProspectedTiles.contains(selectedTileKey)) {
      return (showIcon: false, enabled: false, hasExplorerUnits: false);
    }

    final allUnits = <ct_models.Unit>[
      ...game.worldState.oldWorld.units,
      ...game.worldState.newWorld.units,
    ];
    final explorerUnits = allUnits
        .where((unit) => unit.ownerId == humanPlayerId)
        .where(
          (unit) =>
              workOrderTargetsByUnitType[unit.type]?.contains(
                kWorkTargetProspect,
              ) ??
              false,
        )
        .toList();
    if (explorerUnits.isEmpty) {
      return (showIcon: true, enabled: false, hasExplorerUnits: false);
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
      return (showIcon: true, enabled: false, hasExplorerUnits: true);
    }
    return (showIcon: true, enabled: true, hasExplorerUnits: true);
  }
}
