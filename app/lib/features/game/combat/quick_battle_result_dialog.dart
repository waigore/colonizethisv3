import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_nine_patch_button.dart';

/// Displays Quick Battle result. SPEC/program/quick-battle-resolution.
class QuickBattleResultDialog extends StatelessWidget {
  const QuickBattleResultDialog({
    super.key,
    required this.result,
    this.attackerName = 'Attacker',
    this.defenderName = 'Defender',
  });

  final QuickBattleResult result;
  final String attackerName;
  final String defenderName;

  static Future<void> show(
    BuildContext context, {
    required QuickBattleResult result,
    String attackerName = 'Attacker',
    String defenderName = 'Defender',
  }) {
    return showDialog(
      context: context,
      builder: (context) => QuickBattleResultDialog(
        result: result,
        attackerName: attackerName,
        defenderName: defenderName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final winnerText = switch (result.winner) {
      QuickBattleWinner.attacker => '$attackerName wins',
      QuickBattleWinner.defender => '$defenderName holds',
      QuickBattleWinner.mutualExhaustion => 'Mutual exhaustion',
    };
    return CtDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Battle Result: $winnerText',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (result.provinceFlips)
            const Text(
              'Province captured.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 8),
          Text(
            '$attackerName casualties: ${result.attackerCasualties.length}',
          ),
          Text(
            '$defenderName casualties: ${result.defenderCasualties.length}',
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: CtNinePatchButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }
}
