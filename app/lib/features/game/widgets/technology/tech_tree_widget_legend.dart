// Row label for tech tree legend samples (maps to [AppLocalizations] state strings).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/gp_nation_color_pennant.dart';
import 'tech_gp_researchers.dart';
import 'tech_tree_widget_constants.dart';
import 'tech_tree_widget_legend_chips.dart';
import 'tech_tree_widget_nodes.dart';
import 'tech_ui_helpers.dart';

class TechTreeLegend extends StatelessWidget {
  const TechTreeLegend({required this.game, required this.l10n, super.key});

  final Game game;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.techTree_legendTitle, style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        _buildCategoryLegendWrap(),
        CtGap.m,
        _buildStateLegendWrap(),
        CtGap.m,
        _buildGpPennantLegend(context),
      ],
    );
  }

  Widget _buildGpPennantLegend(BuildContext context) {
    final sampleColor = game.players.isNotEmpty
        ? gpMapColorForPlayer(game, game.players.first.id)
        : EditorialMonoclePalette.muted;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        GpNationColorPennant(color: sampleColor, highlighted: true),
        GpNationColorPennant(color: sampleColor),
        Text(
          l10n.techTree_legendGpPennants,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildCategoryLegendWrap() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: kTechTreeCategoryColors.entries
          .map(
            (e) => TechTreeLegendChip(
              color: e.value,
              label: techCategoryLabelL10n(l10n, e.key),
            ),
          )
          .toList(),
    );
  }

  Widget _buildStateLegendWrap() {
    return Wrap(spacing: 8, runSpacing: 4, children: _stateLegendSamples());
  }

  List<Widget> _stateLegendSamples() {
    return [
      TechTreeStateLegendSample(
        game: game,
        kind: TechLegendStateKind.researched,
        state: const TechTreeNodeState(
          researched: true,
          inProgress: false,
          available: false,
        ),
      ),
      TechTreeStateLegendSample(
        game: game,
        kind: TechLegendStateKind.inProgress,
        state: const TechTreeNodeState(
          researched: false,
          inProgress: true,
          available: false,
        ),
      ),
      TechTreeStateLegendSample(
        game: game,
        kind: TechLegendStateKind.available,
        state: const TechTreeNodeState(
          researched: false,
          inProgress: false,
          available: true,
        ),
      ),
      TechTreeStateLegendSample(
        game: game,
        kind: TechLegendStateKind.locked,
        state: const TechTreeNodeState(
          researched: false,
          inProgress: false,
          available: false,
        ),
      ),
    ];
  }
}
