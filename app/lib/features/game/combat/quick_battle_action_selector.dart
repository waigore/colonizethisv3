import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Command Points: $cpRemaining', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _actionButton(context, QuickBattleAction.volleyFire, 1, 'Volley Fire'),
            _actionButton(context, QuickBattleAction.defendEntrench, 1, 'Defend'),
            _actionButton(context, QuickBattleAction.maneuver, 1, 'Maneuver'),
            _actionButton(context, QuickBattleAction.fallBackRefuseFlank, 2, 'Fall Back'),
            _actionButton(context, QuickBattleAction.assaultCharge, 2, 'Assault'),
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
    return FilledButton.tonal(
      onPressed: enabled ? () => onActionSelected(action) : null,
      child: Text('$label ($cost CP)'),
    );
  }
}
