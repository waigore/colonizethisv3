part of 'game_screen.dart';

/// Flame-canvas fallback Next-turn button (used when `mapViewDataProvider == null`).
class _FallbackNextTurnButton extends ConsumerStatefulWidget {
  const _FallbackNextTurnButton({
    required this.game,
    required this.turnResolutionBlocking,
  });

  final Game game;
  final bool turnResolutionBlocking;

  @override
  ConsumerState<_FallbackNextTurnButton> createState() =>
      _FallbackNextTurnButtonState();
}

class _FallbackNextTurnButtonState extends ConsumerState<_FallbackNextTurnButton>
    with _FallbackNextTurnRunner {
  @override
  Widget build(BuildContext context) {
    final bool nextTurnEnabled = !widget.turnResolutionBlocking &&
        GameMapAreaStateLogic.allowsFullTurnResolution(widget.game);

    return CtNinePatchButton(
      key: kGameMapNextTurnButtonKey,
      enabled: nextTurnEnabled,
      onPressed: nextTurnEnabled ? runFlameCanvasFallbackNextTurn : null,
      disabledOpacityOverride: kNextTurnDisabledOpacity,
      child: Text(
        appL10n(context).game_nextTurnButton(
          widget.game.worldState.turnState.turnNumber,
          turnToYear(
            widget.game.worldState.turnState.turnNumber,
            widget.game.turnTimeMapping,
          ),
        ),
      ),
    );
  }
}
