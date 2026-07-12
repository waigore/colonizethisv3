part of 'game_screen.dart';

/// Composes the Flame canvas / map shell, pause + fallback next-turn chrome,
/// victory overlay, and dialogue overlays (intro, tribe herald, diplomacy).
class _GameScreenOverlayStack extends ConsumerWidget {
  const _GameScreenOverlayStack({
    required this.game,
    required this.mapViewData,
    required this.victory,
    required this.showOverlayButtons,
    required this.showIntro,
    required this.pendingHerald,
    required this.pendingDiplomacy,
    required this.turnResolutionBlocking,
  });

  final Game? game;
  final InitGameMapViewData? mapViewData;
  final VictoryState? victory;
  final bool showOverlayButtons;
  final bool showIntro;
  final TribeFirstContactHeraldPayload? pendingHerald;
  final PendingDiplomacyState? pendingDiplomacy;
  final bool turnResolutionBlocking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget content = Stack(
      children: [
        if (mapViewData != null && game != null)
          GameMapArea(game: game!, mapViewData: mapViewData!)
        else
          GameWidget(game: ColonizeThisGame()),
        if (showOverlayButtons) ...[
          Positioned(
            left: 16,
            top: 16,
            child: CtIconAction(
              icon: Icons.menu,
              iconSize: 24,
              onPressed: turnResolutionBlocking
                  ? null
                  : () => _showPauseMenu(ref.read(appEventBusProvider)),
              enabled: !turnResolutionBlocking,
              tooltip: appL10n(context).game_pauseMenu_tooltip,
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: _FallbackNextTurnButton(
              game: game!,
              turnResolutionBlocking: turnResolutionBlocking,
            ),
          ),
        ],
        if (game != null && victory != null)
          VictoryOverlay(
            game: game!,
            victory: victory!,
            bus: ref.read(appEventBusProvider),
          ),
      ],
    );

    if (game != null) {
      content = TribeFirstContactSyncListener(
        child: GameToUIBusListener(gameId: game!.id, child: content),
      );
    }

    if (showIntro) {
      content = GameStartIntroOverlay(
        onDismissed: () {
          ref.read(gameIdsWithIntroShownProvider.notifier).markShown(game!.id);
        },
        child: content,
      );
    }

    if (!showIntro && game != null && pendingHerald != null) {
      content = TribeFirstContactOverlay(
        tribeName: pendingHerald!.tribeName,
        capitalName: pendingHerald!.capitalName,
        onDismissed: () {
          ref
              .read(tribeFirstContactHeraldsShownProvider.notifier)
              .markShown(game!.id, pendingHerald!.tribeId);
          ref.read(tribeFirstContactHeraldQueueProvider.notifier).dequeueHead();
        },
        child: content,
      );
    }

    if (game != null && pendingDiplomacy != null) {
      switch (pendingDiplomacy!) {
        case PendingDiplomacyOvertures(:final offers) when offers.isNotEmpty:
          content = OvertureDialogueOverlay(
            game: game!,
            pendingOvertures: offers,
            onDecisions: (decisions) {
              final service = ref.read(gameServiceProvider);
              final orders = ref.read(currentOrdersProvider);
              final result = service.resumeOvertureDecisions(
                game!,
                offers,
                decisions,
                orders,
              );
              ref.read(turnResolutionResultApplierProvider).apply(result);
            },
            child: content,
          );
        case PendingDiplomacyIntervention(:final prompts)
            when prompts.isNotEmpty:
          content = InterventionDialogueOverlay(
            game: game!,
            prompts: prompts,
            onDecisions: (decisions) {
              final service = ref.read(gameServiceProvider);
              final orders = ref.read(currentOrdersProvider);
              final result = service.resumeInterventionDecisions(
                game!,
                decisions,
                orders,
              );
              ref.read(turnResolutionResultApplierProvider).apply(result);
            },
            child: content,
          );
        case PendingDiplomacyCallToArms(:final pending) when pending.isNotEmpty:
          content = CallToArmsDialogueOverlay(
            game: game!,
            pending: pending,
            onDecisions: (decisions) {
              final service = ref.read(gameServiceProvider);
              final orders = ref.read(currentOrdersProvider);
              final result = service.resumeCallToArmsDecisions(
                game!,
                decisions,
                orders,
              );
              ref.read(turnResolutionResultApplierProvider).apply(result);
            },
            child: content,
          );
        case _:
          break;
      }
    }

    return content;
  }
}
