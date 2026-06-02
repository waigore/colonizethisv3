// Full-screen Production screen. SPEC/ui/production-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_constants.dart';
import '../../../config/ct_e2e.dart';
import '../../../config/ct_e2e_last_panel_snapshot.dart';
import '../../../config/editorial_monocle_palette.dart';
import '../../../config/ui_screen_ids.dart';
import '../../../providers/game_service_provider.dart';
import '../../../providers/games_provider.dart';
import '../../../providers/production_allocation_provider.dart';
import '../shell_player_context.dart';
import '../widgets/observe_mode_not_defined_panel.dart';
import '../../../widgets/ct_game_feature_screen_shell.dart';
import '../../../widgets/ct_top_bar.dart';
import '../../../widgets/strict_asset_icon.dart';
import '../widgets/production_commodity_breakdown_dialog.dart';
import '../widgets/production_labour_helpers.dart';
import '../widgets/production_panel.dart';

class ProductionScreen extends ConsumerWidget {
  const ProductionScreen({
    super.key,
    required this.game,
    required this.player,
    this.attachGameToUiListener = true,
    this.panelTopologyOverride,
    this.panelTileMapByRegionOverride,
  });

  /// SPEC/ui/production-panel.md — [UiScreenIds.productionScreen].
  static const screenId = UiScreenIds.productionScreen;

  final Game game;
  final Player player;

  /// When true (default), [GameToUIBusListener] subscribes to turn-complete events.
  /// Set false in isolated widget tests where the listener tree affects layout.
  final bool attachGameToUiListener;

  /// When set, the production panel uses this topology instead of
  /// [GameService.getMapData] (avoids Hive in tests).
  final MapTopology? panelTopologyOverride;

  /// Optional tile maps when [panelTopologyOverride] is set.
  final Map<String, TileMapResult>? panelTileMapByRegionOverride;

  /// Localized back-button label rendered immediately after the chevron
  /// on the dark-theme `CtTopBar`. SPEC/ui/production-panel.md § Top bar
  /// requires the literal `"Map"` so the affordance reads `"← Map"`.
  /// Exposed so widget tests (notably the 320 dp viewport pin) can
  /// assert against the SPEC string without coupling to the localization
  /// indirection or duplicating the literal — mirrors the pattern used
  /// by `TradeScreen`, `DiplomacyScreen`, and `TechnologyScreen`.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String topBarBackLabel = 'Map';

  /// Title text shown in the dark-theme `CtTopBar`. SPEC mandates the
  /// literal `"Production"` (Cinzel display font is configured at the
  /// theme level). Exposed so widget tests can match against the SPEC
  /// string — see [topBarBackLabel] for the same rationale.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String topBarTitle = 'Production';

  /// Pixel-art icon asset rendered between the back affordance and the
  /// title (SPEC § Top bar — 18 px production icon).
  static const String _topBarIconAsset =
      '${kAppIconAssetPrefix}ui_icon_production.png';

  /// Stable widget key for the production top bar — lets widget tests
  /// pin the dark-theme chrome without coupling to localized strings.
  static const Key topBarKey = ValueKey<String>('productionScreenTopBar');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CtGameFeatureScreenShell(
      game: game,
      attachGameToUiListener: attachGameToUiListener,
      topBar: CtTopBar(
        key: topBarKey,
        title: topBarTitle,
        backButtonLabel: topBarBackLabel,
        icon: const StrictAssetIcon(
          assetPath: _topBarIconAsset,
          width: 18,
          height: 18,
        ),
      ),
      bodyBuilder: (context, shellRef, displayGame) {
        if (shellPanelsNotDefined(shellRef)) {
          return const ObserveModeNotDefinedPanel(title: 'Production');
        }
        final desiredOutputByRecipe = shellRef.watch(
          productionDesiredOutputProvider,
        );
        final currentOrders = shellRef.watch(currentOrdersProvider);
        var topology = MapTopology();
        Map<String, TileMapResult> tileMapByRegion = const {};
        try {
          final gameService = shellRef.watch(gameServiceProvider);
          final loaded = gameService.getMapData(displayGame.id);
          if (loaded != null) {
            topology = loaded.combinedTopology;
            tileMapByRegion = loaded.tileMapByRegion;
          }
        } on Object {
          // Widget tests may not initialize Hive-backed game service providers.
        }
        final displayPlayer = displayGame.playerById(player.id)!;
        final MapTopology panelTopology;
        final Map<String, TileMapResult>? panelTileMaps;
        if (panelTopologyOverride != null) {
          panelTopology = panelTopologyOverride!;
          panelTileMaps = panelTileMapByRegionOverride;
        } else {
          panelTopology = topology;
          panelTileMaps = tileMapByRegion;
        }
        final netDeltasByCommodity =
            previewStockpileNetDeltaByCommodityForPlayer(
              game: displayGame,
              topology: panelTopology,
              playerId: displayPlayer.id,
              tileMapByRegion: panelTileMaps,
              currentOrders: currentOrders,
              defaultAssignmentsByPlayerId: {
                displayPlayer.id: assignedRecipesFromDesiredOutput(
                  desiredOutputByRecipe,
                ),
              },
            );
        final canEdit = shellRef
            .read(shellPlayerContextProvider)
            .canMutateViaUi;
        final labourCallbacks = ProductionLabourCallbacks(
          onAppendRecruitOrder: (tier) {
            if (!canEdit) return;
            final next = ordersWithAppendedRecruitWorkerOrder(
              currentOrders: shellRef.read(currentOrdersProvider),
              playerId: displayPlayer.id,
              tier: tier,
            );
            shellRef.read(currentOrdersProvider.notifier).replaceAll(next);
          },
          onPopLastRecruitOrder: (tier) {
            if (!canEdit) return;
            final next = ordersWithLastRecruitWorkerOrderRemoved(
              currentOrders: shellRef.read(currentOrdersProvider),
              playerId: displayPlayer.id,
              tier: tier,
            );
            shellRef.read(currentOrdersProvider.notifier).replaceAll(next);
          },
          onDisband: (tier) {
            if (!canEdit) return;
            final nextGame = gameWithImmediateDisband(
              game: shellRef.read(currentGameProvider) ?? displayGame,
              playerId: displayPlayer.id,
              tier: tier,
            );
            if (nextGame == null) return;
            shellRef.read(currentGameProvider.notifier).setGame(nextGame);
          },
        );
        final productionPanel = ProductionPanel(
          game: displayGame,
          player: displayPlayer,
          desiredOutputByRecipe: desiredOutputByRecipe,
          netDeltasByCommodity: netDeltasByCommodity,
          currentOrders: currentOrders,
          labourCallbacks: labourCallbacks,
          canEditLabour: canEdit,
          onOpenCommodityBreakdown: canEdit
              ? () {
                  showDialog<void>(
                    context: context,
                    barrierColor: EditorialMonoclePalette.dialogScrim,
                    builder: (_) => ProductionCommodityBreakdownDialog(
                      game: displayGame,
                      player: displayPlayer,
                      topology: panelTopology,
                      tileMapByRegion: panelTileMaps,
                      currentOrders: currentOrders,
                    ),
                  );
                }
              : null,
          onDesiredOutputChanged: (next) {
            if (!canEdit) return;
            shellRef
                .read(productionDesiredOutputProvider.notifier)
                .replaceAll(next);
          },
        );
        final panel = canEdit
            ? productionPanel
            : IgnorePointer(child: productionPanel);
        if (kCtE2EEnabled) {
          updateCtE2eProductionPanelSnapshotIfEnabled(
            CtE2eProductionPanelSnapshot(
              game: displayGame,
              player: displayPlayer,
              desiredOutputByRecipe: desiredOutputByRecipe,
              netDeltasByCommodity: netDeltasByCommodity,
              topology: panelTopology,
              tileMapByRegion: panelTileMaps,
            ),
          );
          return KeyedSubtree(key: kCtE2EProductionPanelRootKey, child: panel);
        }
        return panel;
      },
    );
  }
}
