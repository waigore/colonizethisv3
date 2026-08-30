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
import 'tech_definition_detail_assign.dart';
import 'tech_definition_detail_sections.dart';
import 'tech_effect_summary.dart';
import 'tech_tree_finish_line.dart';

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
        TechDefinitionHeader(tech: tech, theme: theme, l10n: l10n),
        if (treeAssign != null)
          TechTreeFinishLine(
            game: game,
            player: player,
            tech: tech,
            currentOrders: treeAssign!.currentOrders,
          ),
        if (tech.prerequisiteIds.isNotEmpty)
          TechPrerequisiteList(tech: tech, theme: theme, l10n: l10n),
        if (effects.isNotEmpty)
          TechEffectList(effects: effects, theme: theme, l10n: l10n),
        ...techDefinitionResearchedBySection(
          context,
          game,
          player,
          tech.id,
          l10n,
          theme,
        ),
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
