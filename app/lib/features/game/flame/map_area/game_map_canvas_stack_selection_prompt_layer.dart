import 'package:colonizethis_app/core/services/game_service/try_get_game_map_data.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/build_fort_payoff_copy.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/build_improvement_next_yield_copy.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/explore_payoff_copy.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/purchase_land_payoff_copy.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/transport_step_yield_copy.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/map_province_panel_provider.dart';
import 'game_map_canvas_stack_selection_prompt.dart';

/// Watches overlay/order providers and paints the work-target selection banner.
class GameMapCanvasStackSelectionPromptLayer extends ConsumerWidget {
  const GameMapCanvasStackSelectionPromptLayer({
    required this.isNarrow,
    required this.game,
    required this.humanPlayerId,
    required this.onWorkTargetSelectionCancelled,
    required this.selectionPromptUsesRelocateCopy,
    required this.workTargetForSelection,
    required this.hoveredWorkTargetTileKey,
    required this.lastValidHoveredWorkTargetTileKey,
    required this.canMutateViaUi,
    super.key,
  });

  final bool isNarrow;
  final ct_models.Game game;
  final String humanPlayerId;
  final VoidCallback? onWorkTargetSelectionCancelled;
  final bool selectionPromptUsesRelocateCopy;
  final String? workTargetForSelection;
  final String? hoveredWorkTargetTileKey;
  final String? lastValidHoveredWorkTargetTileKey;
  final bool canMutateViaUi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlayOpen = ref.watch(
      mapProvincePanelProvider.select((s) => s.overlayOpen),
    );
    final orders = ref.watch(currentOrdersProvider);
    final previewTileKey =
        hoveredWorkTargetTileKey ?? lastValidHoveredWorkTargetTileKey;
    final workTarget = workTargetForSelection;
    final affordPreview =
        workTarget != null &&
            previewTileKey != null &&
            !selectionPromptUsesRelocateCopy
        ? previewWorkOrderAffordAtTile(
            game: game,
            playerId: humanPlayerId,
            currentOrders: orders,
            workTarget: workTarget,
            targetTileKey: previewTileKey,
          )
        : null;
    final nextYieldGist =
        workTarget == kWorkTargetBuildImprovement &&
            previewTileKey != null &&
            !selectionPromptUsesRelocateCopy
        ? buildImprovementNextYieldGistForTile(
            l10n: appL10n(context),
            game: game,
            humanPlayerId: humanPlayerId,
            tileKey: previewTileKey,
            enabled: true,
            mapData: tryGetGameMapData(
              () => ref.read(gameServiceProvider).getMapData(game.id),
            ),
            canMutateViaUi: canMutateViaUi,
          )
        : null;
    final payoffGist =
        workTarget == kWorkTargetPurchaseLand &&
            previewTileKey != null &&
            !selectionPromptUsesRelocateCopy
        ? purchaseLandPayoffCopyForTile(
            l10n: appL10n(context),
            game: game,
            tileKey: previewTileKey,
            enabled: true,
          )?.gist
        : null;
    final mapData = tryGetGameMapData(
      () => ref.read(gameServiceProvider).getMapData(game.id),
    );
    final transportGist =
        previewTileKey != null &&
            !selectionPromptUsesRelocateCopy &&
            (workTarget == kWorkTargetBuildRoad ||
                workTarget == kWorkTargetBuildPort ||
                workTarget == kWorkTargetBuildRail)
        ? transportStepYieldGistForTile(
            l10n: appL10n(context),
            game: game,
            humanPlayerId: humanPlayerId,
            tileKey: previewTileKey,
            workTarget: workTarget!,
            enabled: true,
            mapData: mapData,
            canMutateViaUi: canMutateViaUi,
          )
        : null;
    final buildFortGist =
        workTarget == kWorkTargetBuildFort &&
            previewTileKey != null &&
            !selectionPromptUsesRelocateCopy
        ? buildFortPayoffGistForTile(
            l10n: appL10n(context),
            game: game,
            humanPlayerId: humanPlayerId,
            tileKey: previewTileKey,
            enabled: true,
            canMutateViaUi: canMutateViaUi,
          )
        : null;
    final exploreGist =
        workTarget == kWorkTargetExplore &&
            previewTileKey != null &&
            !selectionPromptUsesRelocateCopy
        ? explorePayoffGistForTile(
            l10n: appL10n(context),
            game: game,
            tileKey: previewTileKey,
            enabled: true,
            canMutateViaUi: canMutateViaUi,
          )
        : null;
    return GameMapCanvasStackSelectionPrompt(
      isNarrow: isNarrow,
      overlayOpen: overlayOpen,
      onCancel: onWorkTargetSelectionCancelled,
      usesRelocateCopy: selectionPromptUsesRelocateCopy,
      affordPreview: affordPreview,
      nextYieldGist: nextYieldGist,
      payoffGist: payoffGist,
      transportGist: transportGist,
      buildFortGist: buildFortGist,
      exploreGist: exploreGist,
    );
  }
}
