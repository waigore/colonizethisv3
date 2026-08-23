import 'package:colonizethis_app_ui_chrome/colonizethis_app_ui_chrome.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show techById, techDisplayName;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../widgets/diplomacy/diplomacy_order_helpers.dart';
import '../../widgets/units/civilian/civilian_units_panel_support_resolution.dart';
import 'game_map_area.dart';
import 'game_map_area_state_base.dart';

/// Display-label helpers for [GameMapArea] turn-event feed
/// entries (Refs #3878 Phase 3 map_state modularization).
mixin GameMapAreaTurnFeedLabels
    on ConsumerState<GameMapArea>, GameMapAreaStateBase {
  String factionLabel(String id) =>
      widget.game.factionDisplayNameById(id) ?? id;

  String provinceLabel(String fullProvinceId) =>
      widget.game.worldState.tryGetProvince(fullProvinceId)?.displayName ??
      fullProvinceId;

  String seaZoneLabel(String seaZoneId) {
    return widget.game.worldState.seaZoneDisplayNameById[seaZoneId] ??
        seaZoneId;
  }

  String diplomacyOutcomeLine({
    required String actorId,
    required String targetId,
    required String changeType,
  }) {
    final actor = factionLabel(actorId);
    final target = factionLabel(targetId);
    final normalized = changeType.toLowerCase();
    return switch (normalized) {
      'declare_war' => '$actor declared war on $target!',
      'peace' => '$actor and $target signed peace!',
      'alliance' => '$actor and $target formed an alliance!',
      'break_alliance' => '$actor and $target broke their alliance!',
      _ => '$actor and $target diplomacy changed! ${changeType.toUpperCase()}!',
    };
  }

  bool isCatalogTech(String techId) => techById(techId) != null;

  String researchCompleteLine(String techId) {
    if (!isCatalogTech(techId)) {
      return 'Research complete — technology unlocked!';
    }
    return 'Research complete: ${techDisplayName(techId)} unlocked';
  }

  void navigateToTechnologyScreen() {
    final orders = ref.read(currentOrdersProvider);
    ref
        .read(appEventBusProvider)
        .emit(
          ct_models.NavigateToRouteEvent(Routes.technology, {
            'game': widget.game,
            'humanPlayerId': mapPlayerId,
            'currentOrders': orders,
          }),
        );
  }

  String workTargetLabel(String workTarget) =>
      civilianUnitsPanelWorkTargetLabels[workTarget] ?? workTarget;

  String overtureStageLabel(String stage) {
    for (final value in ct_models.OvertureStage.values) {
      if (value.name == stage) {
        return diplomacyOvertureStageShortLabel(value);
      }
    }
    return stage.replaceAll('_', ' ');
  }

  String orderRejectedReasonLabel(String reasonCode) =>
      CtEventFeedText.orderRejectedReasonLabel(reasonCode);

  String orderRejectedLine(String reasonCode) =>
      CtEventFeedText.orderRejectedLine(reasonCode);
}
