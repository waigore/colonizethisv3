// Full tech definition detail dialog (effects, prereqs, researched-by).
// Shared by the tech-tree node dialog and Choose-tech Details (Refs #4222).
// Tree-opened dialog may assign via [TechTreeAssignConfig] (Refs #4498).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/gp_nation_color_pennant.dart';
import 'tech_definition_detail_assign.dart';
import 'tech_effect_summary.dart';
import 'tech_gp_researchers.dart';
import 'tech_researchers_list_dialog.dart';
import 'tech_ui_helpers.dart';

export 'tech_definition_detail_assign.dart' show TechTreeAssignConfig;

/// Opens Tree-parity tech detail content. When [treeAssign] is non-null,
/// shows Research this / replace-seat / refusal copy (Refs #4498).
void showTechDefinitionDetailDialog(
  BuildContext context, {
  required Game game,
  required Player player,
  required TechDefinition tech,
  TechTreeAssignConfig? treeAssign,
}) {
  final l10n = appL10n(context);
  final effects = buildTechEffectSummaryLines(l10n, tech);
  final theme = Theme.of(context);
  showDialog<void>(
    context: context,
    builder: (ctx) => CtDialogShell(
      maxWidth: 420,
      maxHeight: 560,
      child: _TechDefinitionDetailBody(
        game: game,
        player: player,
        tech: tech,
        effects: effects,
        theme: theme,
        l10n: l10n,
        treeAssign: treeAssign,
        dialogContext: ctx,
      ),
    ),
  );
}

class _TechDefinitionDetailBody extends StatelessWidget {
  const _TechDefinitionDetailBody({
    required this.game,
    required this.player,
    required this.tech,
    required this.effects,
    required this.theme,
    required this.l10n,
    required this.treeAssign,
    required this.dialogContext,
  });

  final Game game;
  final Player player;
  final TechDefinition tech;
  final List<String> effects;
  final ThemeData theme;
  final AppLocalizations l10n;
  final TechTreeAssignConfig? treeAssign;
  final BuildContext dialogContext;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TechDefinitionHeader(tech: tech, theme: theme, l10n: l10n),
        if (tech.prerequisiteIds.isNotEmpty)
          _TechPrerequisiteList(tech: tech, theme: theme, l10n: l10n),
        if (effects.isNotEmpty)
          _TechEffectList(effects: effects, theme: theme, l10n: l10n),
        ..._researchedBySection(context, game, player, tech.id, l10n, theme),
        if (treeAssign != null) ...[
          CtGap.m,
          TechTreeAssignSection(
            game: game,
            player: player,
            tech: tech,
            config: treeAssign!,
            l10n: l10n,
            theme: theme,
            dialogContext: dialogContext,
          ),
        ],
        CtGap.ml,
        Align(
          alignment: Alignment.centerRight,
          child: CtNinePatchButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.common_close),
          ),
        ),
      ],
    );
  }
}

class _TechDefinitionHeader extends StatelessWidget {
  const _TechDefinitionHeader({
    required this.tech,
    required this.theme,
    required this.l10n,
  });

  final TechDefinition tech;
  final ThemeData theme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
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
      ],
    );
  }
}

class _TechPrerequisiteList extends StatelessWidget {
  const _TechPrerequisiteList({
    required this.tech,
    required this.theme,
    required this.l10n,
  });

  final TechDefinition tech;
  final ThemeData theme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CtGap.m,
        Text(l10n.techTree_prerequisites, style: theme.textTheme.labelLarge),
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
    );
  }
}

class _TechEffectList extends StatelessWidget {
  const _TechEffectList({
    required this.effects,
    required this.theme,
    required this.l10n,
  });

  final List<String> effects;
  final ThemeData theme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    );
  }
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
