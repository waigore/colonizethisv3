// Legend chip widgets for the tech tree graph.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'tech_tree_widget_constants.dart';
import 'tech_tree_widget_nodes.dart';

enum TechLegendStateKind { researched, inProgress, available, locked }

/// Static color-coded category swatch used by the tech tree legend.
///
/// Composed from palette-token primitives (`Container` + `Border.all`)
/// rather than Material `Chip` so the legend stays inside the
/// editorial-monocle token surface per `SPEC/ui/pixel-art-ui-catalog.md`
/// § Material design ban and the `repo.app_no_material_chip` rule
/// (Refs #2914 G2). The previous Material `Chip` implementation set
/// `backgroundColor: color.withValues(alpha: 0.2)`,
/// `side: BorderSide(color: color, width: 1.5)`,
/// `visualDensity: VisualDensity.compact`, and
/// `materialTapTargetSize: MaterialTapTargetSize.shrinkWrap`; this
/// `Container`-based replacement preserves that visual contract
/// (alpha-blended fill, 1.5 dp colored border, compact padding) without
/// Material chrome.
class TechTreeLegendChip extends StatelessWidget {
  const TechTreeLegendChip({required this.color, required this.label, super.key});

  /// Horizontal padding inside the legend chip — pinned to
  /// `CtSpacing.m` (8 dp) so it matches the canonical `CtChoiceChip`
  /// inner padding contract from `SPEC/ui/pixel-art-ui-catalog.md`
  /// § *Spacing tokens* without adopting toggle-chip behaviour.
  static const double _horizontalPadding = 8;

  /// Vertical padding inside the legend chip — pinned to `4` dp to
  /// reproduce Material `VisualDensity.compact` vertical density on the
  /// previous Material `Chip` implementation. The repo spacing scale
  /// intentionally skips `4` (see `CtSpacing` docstring), so the literal
  /// is kept locally as a per-component override anchored to this
  /// mockup-pinned value.
  static const double _verticalPadding = 4;

  /// Border width — pinned to the same `1.5` dp the previous Material
  /// `Chip.side` used so the legend's visual weight is preserved.
  static const double _borderWidth = 1.5;

  /// Background alpha applied to the category color — pinned to the
  /// same `0.2` the previous Material `Chip.backgroundColor` used so
  /// the swatch reads as a tinted fill rather than a saturated badge.
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

class TechTreeStateLegendSample extends StatelessWidget {
  const TechTreeStateLegendSample({
    required this.game,
    required this.kind,
    required this.state,
    super.key,
  });

  final Game game;
  final TechLegendStateKind kind;
  final TechTreeNodeState state;

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
          child: TechTreeNode(
            game: game,
            tech: dummyTech,
            contextPlayerId:
                game.players.isNotEmpty ? game.players.first.id : 'gp1',
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
