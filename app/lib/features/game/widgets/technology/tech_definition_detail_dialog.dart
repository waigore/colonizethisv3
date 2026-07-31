// Full tech definition detail dialog (effects, prereqs, researched-by).
// Shared by the tech-tree node dialog and Choose-tech Details (Refs #4222).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/gp_nation_color_pennant.dart';
import 'tech_effect_summary.dart';
import 'tech_gp_researchers.dart';
import 'tech_researchers_list_dialog.dart';
import 'tech_ui_helpers.dart';

/// Opens Tree-parity tech detail content without assigning research.
void showTechDefinitionDetailDialog(
  BuildContext context, {
  required Game game,
  required Player player,
  required TechDefinition tech,
}) {
  final l10n = appL10n(context);
  final effects = buildTechEffectSummaryLines(l10n, tech);
  final theme = Theme.of(context);
  showDialog<void>(
    context: context,
    builder: (ctx) => CtDialogShell(
      maxWidth: 420,
      maxHeight: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(techDisplayName(tech.id), style: theme.textTheme.titleMedium),
          CtGap.m,
          Text(
            l10n.techTree_eraCategory(
              eraRoman(tech.era),
              techCategoryLabelL10n(l10n, tech.category),
            ),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.techTree_researchPoints(tech.cost),
            style: theme.textTheme.bodyMedium,
          ),
          if (tech.prerequisiteIds.isNotEmpty) ...[
            CtGap.m,
            Text(
              l10n.techTree_prerequisites,
              style: theme.textTheme.labelLarge,
            ),
            ...tech.prerequisiteIds.map(
              (id) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  l10n.techTree_prerequisiteBullet(techDisplayName(id)),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          ],
          if (effects.isNotEmpty) ...[
            CtGap.m,
            Text(l10n.techTree_effects, style: theme.textTheme.labelLarge),
            ...effects.map(
              (e) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  l10n.techTree_bulletItem(e),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          ],
          ..._researchedBySection(context, game, player, tech.id, l10n, theme),
          CtGap.ml,
          Align(
            alignment: Alignment.centerRight,
            child: CtNinePatchButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.common_close),
            ),
          ),
        ],
      ),
    ),
  );
}

List<Widget> _researchedBySection(
  BuildContext context,
  Game game,
  Player player,
  String techId,
  AppLocalizations l10n,
  ThemeData theme,
) {
  final researchers = orderGpResearchers(
    researchers: gpPlayersWithTechUnlocked(game, techId),
    contextPlayerId: player.id,
    game: game,
  );
  if (researchers.isEmpty) {
    return const [];
  }
  return [
    CtGap.m,
    GestureDetector(
      onLongPress: () => TechResearchersListDialog.show(
        context,
        game: game,
        techId: techId,
        contextPlayerId: player.id,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.techTree_researchedBy,
            style: theme.textTheme.labelLarge,
          ),
          for (final gp in researchers)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  GpNationColorPennant(
                    color: gpMapColorForPlayer(game, gp.id),
                    highlighted: gp.id == player.id,
                  ),
                  const SizedBox(width: CtSpacing.m),
                  Expanded(
                    child: Text(
                      gp.displayName,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  ];
}
