
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../widgets/ct_nine_patch_button.dart';
import '../../flame/map_state/map_state.dart';
import 'game_screen_fallback_next_turn_runner.dart';
import 'game_screen_shared.dart'
    show kGameMapNextTurnButtonKey, kNextTurnDisabledOpacity;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart';
import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart';
import 'package:colonizethis_logic/debug_console_api.dart';
import 'package:colonizethis_orders/src/orders/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_orders/src/orders/civilian_projected_tile.dart';
import 'package:colonizethis_logic/src/turn_to_year.dart';
import 'package:colonizethis_logic/src/civilians/spy_relocate_intel.dart';
import 'package:colonizethis_logic/src/civilians/civilians_missing_work_orders.dart';

/// Flame-canvas fallback Next-turn button (used when `mapViewDataProvider == null`).
class GameScreenFallbackNextTurnButton extends ConsumerStatefulWidget {
  const GameScreenFallbackNextTurnButton({
    super.key,
    required this.game,
    required this.turnResolutionBlocking,
  });

  final Game game;
  final bool turnResolutionBlocking;

  @override
  ConsumerState<GameScreenFallbackNextTurnButton> createState() =>
      _GameScreenFallbackNextTurnButtonState();
}

class _GameScreenFallbackNextTurnButtonState
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
