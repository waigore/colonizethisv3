import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../../../widgets/ct_panel.dart';
import '../../../widgets/ct_spacing.dart';

/// Displays Quick Battle deployment (units per lane/line).
/// SPEC/game/quick-battle.md: LEFT/CENTER/RIGHT/RESERVE, FRONT/SUPPORT.
class QuickBattleDeploymentView extends StatelessWidget {
  const QuickBattleDeploymentView({
    super.key,
    required this.attackerDeployment,
    required this.defenderDeployment,
    this.attackerName = 'Attacker',
    this.defenderName = 'Defender',
  });

  final QuickBattleDeployment attackerDeployment;
  final QuickBattleDeployment defenderDeployment;
  final String attackerName;
  final String defenderName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(attackerName, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        _buildSideDeployment(context, attackerDeployment),
        const SizedBox(height: 16),
        Text(defenderName, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        _buildSideDeployment(context, defenderDeployment),
      ],
    );
  }

  Widget _buildSideDeployment(BuildContext context, QuickBattleDeployment d) {
    final TextStyle? bodySmall = Theme.of(context).textTheme.bodySmall;
    final TextStyle rowStyle = (bodySmall ?? const TextStyle()).copyWith(
      color: EditorialMonoclePalette.muted,
    );
    return CtPanel(
      padding: const EdgeInsets.all(CtSpacing.ml),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: d.groups.map((g) {
          final label = '${_laneLabel(g.lane)} ${_lineLabel(g.line)}';
          final text =
              '$label: ${g.unitIds.length} units${g.cohesion > 0 ? ' (Cohesion ${g.cohesion})' : ''}';
          return Text(text, style: rowStyle);
        }).toList(),
      ),
    );
  }

  String _laneLabel(QuickBattleLane lane) {
    switch (lane) {
      case QuickBattleLane.left:
        return 'Left';
      case QuickBattleLane.center:
        return 'Center';
      case QuickBattleLane.right:
        return 'Right';
      case QuickBattleLane.reserve:
        return 'Reserve';
    }
  }

  String _lineLabel(QuickBattleLine line) {
    switch (line) {
      case QuickBattleLine.front:
        return 'Front';
      case QuickBattleLine.support:
        return 'Support';
    }
  }
}
