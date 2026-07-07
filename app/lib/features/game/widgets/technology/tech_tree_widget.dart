// Tech tree graph widget. SPEC/ui/tech-tree-widget.md.

import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../config/app_assets.dart';
import '../../../../config/editorial_monocle_palette.dart';
import '../../../../l10n/l10n.dart';
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
import 'tech_effect_summary_lookup.dart';

/// Node position for layout. Exposed for tests (column rule: A→B→C and A→C ⇒ gap between A and C).

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

/// Category color map. SPEC/ui/tech-tree-widget.md: color-coded by category.
const Map<String, Color> _categoryColors = {
  'gathering': Color(0xFF2E7D32),
  'transport': Color(0xFF1565C0),
  'labour': Color(0xFFF9A825),
  'civilian': Color(0xFF6A1B9A),
  'diplomacy': Color(0xFF00838F),
  'naval': Color(0xFF0D47A1),
  'military': Color(0xFFC62828),
  'new-world': Color(0xFF4E342E),
};

/// Category icon map. SPEC/ui/tech-tree-widget.md: one icon per category.
const Map<String, String> _categoryIcons = {
  'gathering': '${kAppIconAssetPrefix}ui_icon_tech_gathering.png',
  'new-world': '${kAppIconAssetPrefix}ui_icon_tech_new_world.png',
  'transport': '${kAppIconAssetPrefix}ui_icon_tech_transport.png',
  'labour': '${kAppIconAssetPrefix}ui_icon_tech_labour.png',
  'civilian': '${kAppIconAssetPrefix}ui_icon_tech_civilian.png',
  'diplomacy': '${kAppIconAssetPrefix}ui_icon_tech_diplomacy.png',
  'naval': '${kAppIconAssetPrefix}ui_icon_tech_naval.png',
  'military': '${kAppIconAssetPrefix}ui_icon_tech_military.png',
};

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
              child: _buildCanvas(
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

  Widget _buildCanvas({
    required BuildContext context,
    required List<TechNodePosition> positions,
    required Map<String, bool> unlocked,
    required Set<String> inProgress,
    required Set<String> researchable,
    required double width,
    required double height,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(width, height),
            painter: _TechTreeEdgePainter(positions: positions),
          ),
          ..._buildPositionedNodes(
            context: context,
            positions: positions,
            unlocked: unlocked,
            inProgress: inProgress,
            researchable: researchable,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPositionedNodes({
    required BuildContext context,
    required List<TechNodePosition> positions,
    required Map<String, bool> unlocked,
    required Set<String> inProgress,
    required Set<String> researchable,
  }) {
    return positions.map((pos) {
      final tech = techById(pos.techId);
      if (tech == null) return const SizedBox.shrink();
      final state = _TechNodeState(
        researched: unlocked[pos.techId] == true,
        inProgress: inProgress.contains(pos.techId),
        available: researchable.contains(pos.techId),
      );
      return Positioned(
        left: pos.x,
        top: pos.y,
        width: _nodeWidth,
        height: _nodeHeight,
        child: _TechNode(
          game: game,
          tech: tech,
          contextPlayerId: player.id,
          state: state,
          onTap: () => showTechDialog(context, tech),
        ),
      );
    }).toList();
  }

  /// Computes topological layout for [catalog]. Forwarded from
  /// [TechTreeWidgetLayout.computeLayout] for test and API stability.
  static List<TechNodePosition> computeLayout(
    Map<String, TechDefinition> catalog,
  ) =>
      TechTreeWidgetLayout.computeLayout(catalog);
}
