import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/ui_screen_ids.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_nine_patch_button.dart';

/// Displays Quick Battle result. Open via `OpenDialogEvent('quick_battle_result', params)`.
/// SPEC/program/quick-battle-resolution.
class QuickBattleResultDialog extends StatelessWidget {
  const QuickBattleResultDialog({
    super.key,
    required this.result,
    this.attackerName = 'Attacker',
    this.defenderName = 'Defender',
  });

  static const screenId = UiScreenIds.quickBattleResultDialog;

  final QuickBattleResult result;
  final String attackerName;
  final String defenderName;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final winnerText = switch (result.winner) {
      QuickBattleWinner.attacker => l10n.quickBattle_attackerWins(attackerName),
      QuickBattleWinner.defender => l10n.quickBattle_defenderHolds(
        defenderName,
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
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (result.provinceFlips)
            Text(
              l10n.quickBattle_provinceCaptured,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 8),
          Text(
            l10n.quickBattle_casualties(
              attackerName,
              result.attackerCasualties.length,
            ),
          ),
          Text(
            l10n.quickBattle_casualties(
              defenderName,
              result.defenderCasualties.length,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: CtNinePatchButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.quickBattle_ok),
            ),
          ),
        ],
      ),
    );
  }
}
