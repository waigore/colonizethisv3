import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_nine_patch_button.dart';

/// Quick Battle result summary view (Refs #4117 de-part).
class QuickBattleResultView extends StatelessWidget {
  const QuickBattleResultView({super.key, required this.result, required this.onDismiss});

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
