// Tech tree graph widget. SPEC/ui/tech-tree-widget.md.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_spacing.dart';
import 'tech_tree_widget_canvas.dart';
import 'tech_tree_widget_layout.dart';
import 'tech_tree_widget_legend.dart';
import 'tech_tree_widget_types.dart';

export 'tech_tree_widget_types.dart' show TechNodePosition;
import 'package:colonizethis_world/colonizethis_world.dart';

/// Full-screen tech tree graph. Left-to-right layout, explicit edges, scrollable.
/// SPEC/ui/tech-tree-widget.md.
class TechTreeWidget extends StatelessWidget {
  const TechTreeWidget({super.key, required this.game, required this.player});

  final Game game;
  final Player player;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final positions = computeTechTreeLayout(techCatalog);
    if (positions.isEmpty) {
      return Center(child: Text(l10n.techTree_noTechsInCatalog));
    }
    final width = techTreeCanvasWidth(positions);
    final height = techTreeCanvasHeight(positions);
    final unlocked = player.techUnlocked ?? {};
    final inProgress = player.researchProgressByTechId?.keys.toSet() ?? {};
    final researchable = researchableTechIds(
      unlocked,
      hasDiscoveredResource: (r) =>
          hasRevealedResourceForPlayer(game, player.id, r),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CtSpacing.l,
            vertical: CtSpacing.m,
          ),
          child: TechTreeLegend(game: game, l10n: l10n),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: buildTechTreeCanvas(
                context: context,
                game: game,
                player: player,
                positions: positions,
                unlocked: unlocked,
                inProgress: inProgress,
                researchable: researchable,
                width: width,
                height: height,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Computes topological layout for [catalog]. Forwarded from
  /// [computeTechTreeLayout] for test and API stability.
  static List<TechNodePosition> computeLayout(
    Map<String, TechDefinition> catalog,
  ) =>
      computeTechTreeLayout(catalog);
}
