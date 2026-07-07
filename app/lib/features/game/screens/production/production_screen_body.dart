part of 'production_screen.dart';

Widget buildProductionScreenBody({
  required BuildContext context,
  required WidgetRef shellRef,
  required Game displayGame,
  required ProductionScreen screen,
}) {
  final shell = shellRef.read(shellPlayerContextProvider);
  final sentinel = observeNotDefinedSentinel(shell, 'Production');
  if (sentinel != null) return sentinel;
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
  final displayPlayer = displayGame.playerById(screen.player.id)!;
  final MapTopology panelTopology;
  final Map<String, TileMapResult>? panelTileMaps;
  if (screen.panelTopologyOverride != null) {
    panelTopology = screen.panelTopologyOverride!;
    panelTileMaps = screen.panelTileMapByRegionOverride;
  } else {
    panelTopology = topology;
    panelTileMaps = tileMapByRegion;
  }
  final netDeltasByCommodity = previewStockpileNetDeltaByCommodityForPlayer(
    game: displayGame,
    topology: panelTopology,
    playerId: displayPlayer.id,
    inputs: economyPreviewInputs(
      tileMapByRegion: panelTileMaps,
      currentOrders: currentOrders,
      defaultAssignmentsByPlayerId: {
        displayPlayer.id: assignedRecipesFromDesiredOutput(
          desiredOutputByRecipe,
        ),
      },
    ),
  );
  final canEdit = shell.canMutateViaUi;
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
      shellRef.read(productionDesiredOutputProvider.notifier).replaceAll(next);
    },
  );
  final panel =
      canEdit ? productionPanel : IgnorePointer(child: productionPanel);
  if (kCtE2EEnabled) {
    updateCtE2eProductionPanelSnapshotIfEnabled(
      CtE2eProductionPanelSnapshot(
        game: displayGame,
        player: displayPlayer,
        desiredOutputByRecipe: desiredOutputByRecipe,
        netDeltasByCommodity: netDeltasByCommodity,
        topology: panelTopology,
        currentOrders: currentOrders,
        canEditLabour: canEdit,
        tileMapByRegion: panelTileMaps,
      ),
    );
    return KeyedSubtree(key: kCtE2EProductionPanelRootKey, child: panel);
  }
  return panel;
}
