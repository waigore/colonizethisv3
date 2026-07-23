// Tech tree graph widget. SPEC/ui/tech-tree-widget.md.

import 'dart:math' as math;
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../config/app_assets.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'tech_gp_researchers.dart';
import 'tech_ui_helpers.dart';
import 'tech_gp_pennant_row.dart';
import 'tech_researchers_list_dialog.dart';
import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/gp_nation_color_pennant.dart';
import '../../../../widgets/strict_asset_icon.dart';
import 'package:colonizethis_app_l10n/tech_effect/tech_effect_summary_lookup.dart';

/// Node position for layout. Exposed for tests (column rule: A→B→C and A→C ⇒ gap between A and C).

part 'tech_tree_widget_canvas.dart';
part 'tech_tree_widget_catalog.dart';
part 'tech_tree_widget_dialog.dart';
part 'tech_tree_widget_layout.dart';
part 'tech_tree_widget_nodes.dart';
part 'tech_tree_widget_legend_chips.dart';
part 'tech_tree_widget_legend.dart';

class TechNodePosition {
  const TechNodePosition({
    required this.techId,
    required this.x,
    required this.y,
    required this.layer,
  });
  final String techId;
  final double x;
  final double y;
  final int layer;
}

/// Full-screen tech tree graph. Left-to-right layout, explicit edges, scrollable.
/// SPEC/ui/tech-tree-widget.md.
class TechTreeWidget extends StatelessWidget {
  const TechTreeWidget({super.key, required this.game, required this.player});

  final Game game;
  final Player player;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final positions = TechTreeWidgetLayout.computeLayout(techCatalog);
    if (positions.isEmpty) {
      return Center(child: Text(l10n.techTree_noTechsInCatalog));
    }
    final width = canvasWidth(positions);
    final height = canvasHeight(positions);
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
          child: _TechTreeLegend(game: game, l10n: l10n),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: buildTechTreeCanvas(
                context: context,
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
  /// [TechTreeWidgetLayout.computeLayout] for test and API stability.
  static List<TechNodePosition> computeLayout(
    Map<String, TechDefinition> catalog,
  ) =>
      TechTreeWidgetLayout.computeLayout(catalog);
}
