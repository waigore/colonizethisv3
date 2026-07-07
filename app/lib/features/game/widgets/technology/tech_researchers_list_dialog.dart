// Modal listing GPs that have researched a tech (long-press pennant rows). Refs #3862.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../config/editorial_monocle_palette.dart';
import '../../../../l10n/l10n.dart';
import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/gp_nation_color_pennant.dart';
import 'tech_gp_researchers.dart';

/// Lists every GP that has fully unlocked [techId] with pennant + display name.
class TechResearchersListDialog extends StatelessWidget {
  const TechResearchersListDialog({
    super.key,
    required this.game,
    required this.techId,
    required this.contextPlayerId,
  });

  final Game game;
  final String techId;
  final String contextPlayerId;

  static Future<void> show(
    BuildContext context, {
    required Game game,
    required String techId,
    required String contextPlayerId,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => TechResearchersListDialog(
        game: game,
        techId: techId,
        contextPlayerId: contextPlayerId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    final researchers = orderGpResearchers(
      researchers: gpPlayersWithTechUnlocked(game, techId),
      contextPlayerId: contextPlayerId,
      game: game,
    );
    return CtDialogShell(
      maxWidth: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.techTree_researchersDialogTitle,
            style: theme.textTheme.titleMedium,
          ),
          CtGap.m,
          for (final player in researchers)
            Padding(
              padding: const EdgeInsets.only(bottom: CtSpacing.s),
              child: Row(
                children: [
                  GpNationColorPennant(
                    color: gpMapColorForPlayer(game, player.id),
                    highlighted: player.id == contextPlayerId,
                  ),
                  const SizedBox(width: CtSpacing.m),
                  Expanded(
                    child: Text(
                      player.displayName ?? player.id,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: EditorialMonoclePalette.fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          CtGap.ml,
          Align(
            alignment: Alignment.centerRight,
            child: CtNinePatchButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.common_close),
            ),
          ),
        ],
      ),
    );
  }
}
