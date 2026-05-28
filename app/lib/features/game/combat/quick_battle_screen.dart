import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/ui_screen_ids.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import 'quick_battle_action_selector.dart';
import 'quick_battle_deployment_view.dart';

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
      return _ResultView(
        result: _result!,
        onDismiss: () {
          widget.onComplete(_result!);
        },
      );
    }
    return CtDialogShell(
      maxWidth: 400,
      maxHeight: 500,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.quickBattle_round(_round, widget.input.maxRounds),
            style: Theme.of(context).textTheme.titleMedium,
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

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result, required this.onDismiss});

  final QuickBattleResult result;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    final winnerText = switch (result.winner) {
      QuickBattleWinner.attacker => l10n.quickBattle_attackerWins(
        l10n.quickBattle_attackerDefaultName,
      ),
      QuickBattleWinner.defender => l10n.quickBattle_defenderHolds(
        l10n.quickBattle_defenderDefaultName,
      ),
      QuickBattleWinner.mutualExhaustion => l10n.quickBattle_mutualExhaustion,
    };
    return CtDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.quickBattle_battleResult(winnerText),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          if (result.provinceFlips)
            Text(
              l10n.quickBattle_provinceCaptured,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            l10n.quickBattle_casualties(
              l10n.quickBattle_attackerDefaultName,
              result.attackerCasualties.length,
            ),
            style: theme.textTheme.bodySmall,
          ),
          Text(
            l10n.quickBattle_casualties(
              l10n.quickBattle_defenderDefaultName,
              result.defenderCasualties.length,
            ),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: CtNinePatchButton(
              onPressed: onDismiss,
              child: Text(l10n.game_intervention_continue),
            ),
          ),
        ],
      ),
    );
  }
}
