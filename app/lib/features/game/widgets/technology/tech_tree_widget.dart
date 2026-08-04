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
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart';
import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart';
import 'package:colonizethis_logic/debug_console_api.dart';
import 'package:colonizethis_orders/src/orders/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_orders/src/orders/civilian_projected_tile.dart';
import 'package:colonizethis_logic/src/turn_to_year.dart';
import 'package:colonizethis_logic/src/civilians/spy_relocate_intel.dart';
import 'package:colonizethis_logic/src/civilians/civilians_missing_work_orders.dart';

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
