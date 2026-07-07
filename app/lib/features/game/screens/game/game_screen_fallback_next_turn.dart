part of 'game_screen.dart';

/// Flame-canvas fallback Next-turn button (used when `mapViewDataProvider == null`).
class _FallbackNextTurnButton extends ConsumerWidget {
  const _FallbackNextTurnButton({
    required this.game,
    required this.turnResolutionBlocking,
  });

  final Game game;
  final bool turnResolutionBlocking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool nextTurnEnabled = !turnResolutionBlocking &&
        GameMapAreaStateLogic.allowsFullTurnResolution(game);

    return CtNinePatchButton(
      key: kGameMapNextTurnButtonKey,
      enabled: nextTurnEnabled,
      onPressed: nextTurnEnabled
          ? () => _runFlameCanvasFallbackNextTurn(
                context: context,
                ref: ref,
                game: game,
              )
          : null,
      disabledOpacityOverride: kNextTurnDisabledOpacity,
      child: Text(
        appL10n(context).game_nextTurnButton(
          game.worldState.turnState.turnNumber,
          turnToYear(
            game.worldState.turnState.turnNumber,
            game.turnTimeMapping,
          ),
        ),
      ),
    );
  }
}
