// Legend chip widgets for the tech tree graph.
//
// De-parted wave-9 cluster (Refs #4117).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'tech_tree_widget_constants.dart';
import 'tech_tree_widget_models.dart';
import 'tech_tree_widget_nodes.dart';

enum TechLegendStateKind { researched, inProgress, available, locked }

/// Static color-coded category swatch used by the tech tree legend.
///
/// Composed from palette-token primitives (`Container` + `Border.all`)
/// rather than Material `Chip` so the legend stays inside the
/// editorial-monocle token surface per `SPEC/ui/pixel-art-ui-catalog.md`
/// § Material design ban and the `repo.app_no_material_chip` rule
/// (Refs #2914 G2).
class TechLegendChip extends StatelessWidget {
  const TechLegendChip({super.key, required this.color, required this.label});

  static const double _horizontalPadding = 8;
  static const double _verticalPadding = 4;
  static const double _borderWidth = 1.5;
  static const double _backgroundAlpha = 0.2;

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: _backgroundAlpha),
        border: Border.all(color: color, width: _borderWidth),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _horizontalPadding,
          vertical: _verticalPadding,
        ),
        child: Text(label, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}

class TechLegendStateSample extends StatelessWidget {
  const TechLegendStateSample({
    super.key,
    required this.game,
    required this.kind,
    required this.state,
  });

  final Game game;
  final TechLegendStateKind kind;
  final TechNodeState state;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    const dummyTech = TechDefinition(
      id: 'legend_dummy',
      era: 1,
      category: 'gathering',
      cost: 0,
      prerequisiteIds: <String>[],
      regimentUnlockIds: <String>[],
      shipUnlockIds: <String>[],
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: kTechTreeNodeWidth,
          height: kTechTreeNodeHeight,
          child: TechTreeGraphNode(
            game: game,
            tech: dummyTech,
            contextPlayerId: game.players.isNotEmpty
                ? game.players.first.id
                : 'gp1',
            state: state,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 4),
        Text(
          _localizedLabel(l10n),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _localizedLabel(AppLocalizations l10n) {
    return switch (kind) {
      TechLegendStateKind.researched => l10n.techTree_stateResearched,
      TechLegendStateKind.inProgress => l10n.techTree_stateInProgress,
      TechLegendStateKind.available => l10n.techTree_stateAvailable,
      TechLegendStateKind.locked => l10n.techTree_stateLocked,
    };
  }
}
