import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/gp_nation_color_pennant.dart';
import 'tech_gp_researchers.dart';
import 'tech_researchers_list_dialog.dart';
import 'tech_ui_helpers.dart';

class TechDefinitionHeader extends StatelessWidget {
  const TechDefinitionHeader({
    super.key,
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

class TechPrerequisiteList extends StatelessWidget {
  const TechPrerequisiteList({
    super.key,
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

class TechEffectList extends StatelessWidget {
  const TechEffectList({
    super.key,
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

List<Widget> techDefinitionResearchedBySection(
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
          Text(l10n.techTree_researchedBy, style: theme.textTheme.labelLarge),
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
