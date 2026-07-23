import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../widgets/ct_nine_patch_button.dart';
import '../../flame/map_state/map_state.dart';
import 'game_screen_fallback_next_turn_runner.dart';
import 'game_screen_shared.dart'
    show kGameMapNextTurnButtonKey, kNextTurnDisabledOpacity;

/// Flame-canvas fallback Next-turn button (used when `mapViewDataProvider == null`).
class GameScreenFallbackNextTurnButton extends ConsumerStatefulWidget {
  const GameScreenFallbackNextTurnButton({
    required this.game,
    required this.turnResolutionBlocking,
    super.key,
  });

  final Game game;
  final bool turnResolutionBlocking;

  @override
  ConsumerState<GameScreenFallbackNextTurnButton> createState() =>
      GameScreenFallbackNextTurnButtonState();
}

class GameScreenFallbackNextTurnButtonState
    extends ConsumerState<GameScreenFallbackNextTurnButton>
    with GameScreenFallbackNextTurnRunner {
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
