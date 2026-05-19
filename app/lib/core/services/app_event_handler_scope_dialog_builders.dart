
part of 'app_event_handler_scope.dart';

extension _DialogBuilders on _AppEventHandlerScopeState {
  Map<String, DialogBuilder> _dialogBuilders() {
    return {
      newGameLeaderSelectionDialogId: _buildNewGameLeaderSelectionDialog,
      trainCiviliansDialogId: _buildTrainCiviliansDialog,
      trainMilitaryDialogId: _buildTrainMilitaryDialog,
      grantOrSubsidyDialogId: _buildGrantOrSubsidyDialog,
      combatModeChoiceDialogId: _buildCombatModeChoiceDialog,
      quickBattleResultDialogId: _buildQuickBattleResultDialog,
      turnNewsDialogId: _buildTurnNewsDialog,
    };
  }

  Widget _buildNewGameLeaderSelectionDialog(
    BuildContext ctx,
    Map<String, Object?>? _,
  ) {
    final baseConfig = kCtE2EEnabled
        ? _ctE2eNewGameLeaderTemplateConfig()
        : GameSetupConfig.defaultConfig;
    final naming = defaultNamingConfig;
    final initialSelections = <String, String>{};
    for (final gpId in baseConfig.selectedGreatPowerIds) {
      final gp = naming.gpById(gpId);
      if (gp != null && gp.leaderVariants.isNotEmpty) {
        initialSelections[gpId] = gp.defaultLeaderVariantId;
      }
    }
    return NewGameLeaderSelectionDialog(
      baseConfig: baseConfig,
      naming: naming,
      initialLeaderByGpId: initialSelections,
      onCancel: () => Navigator.of(ctx).pop(),
      onConfirmed: (orderedGreatPowerIds, leaderVariantByGpId, seed, infiniteMode) {
        final navCtx = appNavigatorKey.currentContext;
        if (navCtx == null) {
          _logShell.w(
            'appNavigatorKey has no context; skipping new game setup',
          );
          return;
        }
        final rootContainer = ProviderScope.containerOf(navCtx);
        final templateConfig = GameSetupConfig(
          selectedGreatPowerIds: orderedGreatPowerIds,
          leaderVariantByGpId: leaderVariantByGpId,
          continentCount: baseConfig.continentCount,
          minorNationCount: baseConfig.minorNationCount,
          tribeCount: baseConfig.tribeCount,
          numProvincesOldWorld: baseConfig.numProvincesOldWorld,
          numProvincesNewWorld: baseConfig.numProvincesNewWorld,
          minProvincesPerMinor: baseConfig.minProvincesPerMinor,
          seed: seed,
          infiniteMode: infiniteMode,
          startingResources: baseConfig.startingResources,
          initTownRoadWiringRegionIds: baseConfig.initTownRoadWiringRegionIds,
        );
        unawaited(
          runNewGameSetupAfterLeaderPick(
            container: rootContainer,
            templateConfig: templateConfig,
          ),
        );
      },
    );
  }

  Widget _buildTrainCiviliansDialog(BuildContext ctx, Map<String, Object?>? _) {
    final container = ProviderScope.containerOf(ctx);
    final game = container.read(currentGameProvider);
    if (game == null) {
      return const SizedBox.shrink();
    }
    return TrainCiviliansDialog(
      game: game,
      humanPlayerId: resolveShellPanelPlayerId(
        container.read(shellPlayerContextProvider),
        game,
      ),
      currentOrders: container.read(currentOrdersProvider),
      bus: container.read(appEventBusProvider),
    );
  }

  Widget _buildTrainMilitaryDialog(BuildContext ctx, Map<String, Object?>? _) {
    final container = ProviderScope.containerOf(ctx);
    final game = container.read(currentGameProvider);
    if (game == null) {
      return const SizedBox.shrink();
    }
    return TrainMilitaryDialog(
      game: game,
      humanPlayerId: resolveShellPanelPlayerId(
        container.read(shellPlayerContextProvider),
        game,
      ),
      currentOrders: container.read(currentOrdersProvider),
      bus: container.read(appEventBusProvider),
    );
  }

  Widget _buildGrantOrSubsidyDialog(
    BuildContext ctx,
    Map<String, Object?>? params,
  ) {
    final container = ProviderScope.containerOf(ctx);
    final game = container.read(currentGameProvider);
    if (game == null) {
      return const SizedBox.shrink();
    }
    return GrantOrSubsidyDialog(
      game: game,
      humanPlayerId: resolveShellPanelPlayerId(
        container.read(shellPlayerContextProvider),
        game,
      ),
      targetFactionId: params?['targetFactionId'] as String? ?? '',
      isSubsidy: params?['isSubsidy'] == true,
      bus: container.read(appEventBusProvider),
    );
  }

  Widget _buildCombatModeChoiceDialog(
    BuildContext ctx,
    Map<String, Object?>? params,
  ) {
    final container = ProviderScope.containerOf(ctx);
    return CombatModeChoiceDialog(
      bus: container.read(appEventBusProvider),
      provinceName: params?['provinceName'] as String? ?? '',
      isCapitalSiege: params?['isCapitalSiege'] == true,
    );
  }

  Widget _buildQuickBattleResultDialog(
    BuildContext _,
    Map<String, Object?>? params,
  ) {
    final result = params?['result'] as QuickBattleResult?;
    if (result == null) {
      return const SizedBox.shrink();
    }
    return QuickBattleResultDialog(
      result: result,
      attackerName: params?['attackerName'] as String? ?? 'Attacker',
      defenderName: params?['defenderName'] as String? ?? 'Defender',
    );
  }

  Widget _buildTurnNewsDialog(BuildContext ctx, Map<String, Object?>? params) {
    final container = ProviderScope.containerOf(ctx);
    final game = container.read(currentGameProvider);
    final digest = params?['digest'] as TurnNewsDigest?;
    final newTurnNumber = params?['newTurnNumber'] as int?;
    if (game == null || digest == null || newTurnNumber == null) {
      return const SizedBox.shrink();
    }
    return TurnNewsDialog(
      game: game,
      digest: digest,
      newTurnNumber: newTurnNumber,
    );
  }
}
