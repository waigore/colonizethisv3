import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_nine_patch_button.dart';

/// CP-based action selector for Quick Battle. SPEC/game/quick-battle.md.
class QuickBattleActionSelector extends StatelessWidget {
  const QuickBattleActionSelector({
    super.key,
    required this.cpRemaining,
    required this.onActionSelected,
  });

  final int cpRemaining;
  final ValueChanged<QuickBattleAction> onActionSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final TextStyle? titleSmall = Theme.of(context).textTheme.titleSmall;
    final TextStyle cpStyle = (titleSmall ?? const TextStyle()).copyWith(
      color: EditorialMonoclePalette.muted,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.quickBattle_commandPoints(cpRemaining),
          style: cpStyle,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _actionButton(
              context,
              QuickBattleAction.volleyFire,
              1,
              l10n.quickBattle_action_volleyFire,
            ),
            _actionButton(
              context,
              QuickBattleAction.defendEntrench,
              1,
              l10n.quickBattle_action_defend,
            ),
            _actionButton(
              context,
              QuickBattleAction.maneuver,
              1,
              l10n.quickBattle_action_maneuver,
            ),
            _actionButton(
              context,
              QuickBattleAction.fallBackRefuseFlank,
              2,
              l10n.quickBattle_action_fallBack,
            ),
            _actionButton(
              context,
              QuickBattleAction.assaultCharge,
              2,
              l10n.quickBattle_action_assault,
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButton(
    BuildContext context,
    QuickBattleAction action,
    int cost,
    String label,
  ) {
    final enabled = cpRemaining >= cost;
    return CtNinePatchButton(
      onPressed: enabled ? () => onActionSelected(action) : null,
      child: Text(
        appL10n(context).quickBattle_actionWithCost(label, cost),
      ),
    );
  }
}
