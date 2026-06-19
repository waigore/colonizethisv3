part of 'app_event_handler_scope.dart';

extension _DialogBuilders on _AppEventHandlerScopeState {
  Map<String, DialogBuilder> _dialogBuilders() {
    return {
      trainCiviliansDialogId: _buildTrainCiviliansDialog,
      trainMilitaryDialogId: _buildTrainMilitaryDialog,
      grantOrSubsidyDialogId: _buildGrantOrSubsidyDialog,
      combatModeChoiceDialogId: _buildCombatModeChoiceDialog,
      quickBattleResultDialogId: _buildQuickBattleResultDialog,
      turnNewsDialogId: _buildTurnNewsDialog,
      // Feature-layer builders (e.g. the shell new-game leader dialog) are
      // injected by the composition root and merged last so a feature owns its
      // dialog construction without `core/services/` importing `features/`.
      // Each factory is resolved here with [appNavigatorKey] — the documented
      // choke point — so feature files thread the key explicitly rather than
      // reading the global (Refs #3546). SPEC/program/app-ui-wiring.md.
      for (final entry in widget.extraDialogBuilders.entries)
        entry.key: entry.value(appNavigatorKey),
    };
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
