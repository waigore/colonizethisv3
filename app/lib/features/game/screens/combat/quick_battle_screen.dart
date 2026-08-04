
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../config/ui_screen_ids.dart';
import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../widgets/combat/quick_battle_action_selector.dart';
import '../../widgets/combat/quick_battle_deployment_view.dart';
import 'quick_battle_screen_result.dart';
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

/// Quick Battle flow: deployment → rounds → result. SPEC/game/quick-battle.md.
/// Uses default actions (Volley Fire) when run in headless/AI mode.
class QuickBattleScreen extends StatefulWidget {
  const QuickBattleScreen({
    super.key,
    required this.input,
    required this.onComplete,
    this.interactive = false,
  });

  /// SPEC/ui/quick-battle-screen.md — [UiScreenIds.quickBattleScreen].
  static const screenId = UiScreenIds.quickBattleScreen;

  /// Letter-spacing applied to the round-counter title text.
  ///
  /// Matches the `0.05em` setter on `.round-counter` in
  /// `SPEC/ui/mockups/CMPT20001-quick-battle-screen.html`. Documented in
  /// `SPEC/ui/quick-battle-screen.md` § Layout / wireframe and pinned by
  /// the round-counter palette AC.
  static const double roundCounterLetterSpacing = 0.05;

  final QuickBattleInput input;
  final ValueChanged<QuickBattleResult> onComplete;
  final bool interactive;

  @override
  State<QuickBattleScreen> createState() => _QuickBattleScreenState();
}

class _QuickBattleScreenState extends State<QuickBattleScreen> {
  final int _round = 1;
  QuickBattleResult? _result;

  @override
  void initState() {
    super.initState();
    if (!widget.interactive) {
      _runWithDefaults();
    }
  }

  void _runWithDefaults() {
    final result = resolveQuickBattle(widget.input);
    setState(() => _result = result);
  }

  void _onActionSelected(QuickBattleAction action) {
    // For interactive mode, collect actions per round and run at end.
    // Simplified: run with single Volley Fire when user clicks.
    final result = resolveQuickBattle(
      widget.input,
      roundActions: [
        QuickBattleRoundActions(actions: [action]),
        QuickBattleRoundActions(actions: [QuickBattleAction.volleyFire]),
        QuickBattleRoundActions(actions: [QuickBattleAction.volleyFire]),
      ],
    );
    setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    if (_result != null) {
      return QuickBattleResultView(
        result: _result!,
        onDismiss: () {
          widget.onComplete(_result!);
        },
      );
    }
    final ThemeData theme = Theme.of(context);
    final TextStyle? roundCounterStyle = theme.textTheme.titleMedium?.copyWith(
      color: EditorialMonoclePalette.accent,
      letterSpacing: QuickBattleScreen.roundCounterLetterSpacing,
    );
    return CtDialogShell(
      maxWidth: 400,
      maxHeight: 500,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.quickBattle_round(_round, widget.input.maxRounds),
            style: roundCounterStyle,
          ),
          const SizedBox(height: 12),
          QuickBattleDeploymentView(
            attackerDeployment: widget.input.attackerDeployment,
            defenderDeployment: widget.input.defenderDeployment,
            attackerName: widget.input.attackerFactionId,
            defenderName: widget.input.defenderFactionId,
          ),
          if (widget.interactive) ...[
            const SizedBox(height: 12),
            QuickBattleActionSelector(
              cpRemaining: 3,
              onActionSelected: _onActionSelected,
            ),
          ] else ...[
            const SizedBox(height: 12),
            CtNinePatchButton(
              onPressed: _runWithDefaults,
              child: Text(l10n.quickBattle_resolveAuto),
            ),
          ],
        ],
      ),
    );
  }
}
