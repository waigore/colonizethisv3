// Compact GP nation-color pennant row for tech surfaces. Refs #3862.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/gp_nation_color_pennant.dart';
import 'tech_gp_researchers.dart';
import 'tech_researchers_list_dialog.dart';

/// Ordered GP pennants for GPs that have fully unlocked [techId].
///
/// Long-press opens [TechResearchersListDialog]. Returns [SizedBox.shrink]
/// when no GP has researched the tech.
class TechGpPennantRow extends StatelessWidget {
  const TechGpPennantRow({
    super.key,
    required this.game,
    required this.techId,
    required this.contextPlayerId,
    this.compact = false,
  });

  final Game game;
  final String techId;
  final String contextPlayerId;
  final bool compact;

  static const double _pennantGap = 2;

  @override
  Widget build(BuildContext context) {
    final researchers = orderGpResearchers(
      researchers: gpPlayersWithTechUnlocked(game, techId),
      contextPlayerId: contextPlayerId,
      game: game,
    );
    if (researchers.isEmpty) {
      return const SizedBox.shrink();
    }
    final pennantSize = compact ? const Size(8, 10) : const Size(10, 12);
    final row = Wrap(
      spacing: _pennantGap,
      runSpacing: _pennantGap,
      alignment: WrapAlignment.center,
      children: [
        for (final player in researchers)
          GpNationColorPennant(
            key: ValueKey<String>('tech_gp_pennant_${techId}_${player.id}'),
            color: gpMapColorForPlayer(game, player.id),
            highlighted: player.id == contextPlayerId,
            size: pennantSize,
          ),
      ],
    );
    return GestureDetector(
      onLongPress: () => TechResearchersListDialog.show(
        context,
        game: game,
        techId: techId,
        contextPlayerId: contextPlayerId,
      ),
      child: Padding(
        padding: EdgeInsets.only(top: compact ? 2 : 3),
        child: row,
      ),
    );
  }
}
