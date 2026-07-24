import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/strict_asset_icon.dart';
import 'tech_gp_pennant_row.dart';
import 'tech_tree_widget_constants.dart';
import 'tech_tree_widget_types.dart';

class TechTreeNodeState {
  const TechTreeNodeState({
    required this.researched,
    required this.inProgress,
    required this.available,
  });

  final bool researched;
  final bool inProgress;
  final bool available;
}

class TechTreeEdgePainter extends CustomPainter {
  TechTreeEdgePainter({required this.positions});

  final List<TechNodePosition> positions;

  static double get _centerY => kTechTreeNodeHeight / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final posByTech = {for (final p in positions) p.techId: p};
    final paint = Paint()
      ..color = EditorialMonoclePalette.border
      ..strokeWidth = kTechTreeEdgeStrokeWidth
      ..style = PaintingStyle.stroke;

    for (final tech in techCatalog.values) {
      final toPos = posByTech[tech.id];
      if (toPos == null) continue;
      final toLeftX = toPos.x;
      final toCenterY = toPos.y + _centerY;
      for (final prereqId in tech.prerequisiteIds) {
        final fromPos = posByTech[prereqId];
        if (fromPos == null) continue;
        final fromRightX = fromPos.x + kTechTreeNodeWidth;
        final fromCenterY = fromPos.y + _centerY;

        final bendX = fromRightX + kTechTreeEdgeBendOffset;
        final path = Path()
          ..moveTo(fromRightX, fromCenterY)
          ..lineTo(bendX, fromCenterY)
          ..lineTo(bendX, toCenterY)
          ..lineTo(toLeftX, toCenterY);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant TechTreeEdgePainter oldDelegate) => false;
}

class TechTreeNode extends StatelessWidget {
  const TechTreeNode({
    required this.game,
    required this.tech,
    required this.contextPlayerId,
    required this.state,
    required this.onTap,
    super.key,
  });

  final Game game;
  final TechDefinition tech;
  final String contextPlayerId;
  final TechTreeNodeState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _nodeStyle();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: kTechTreeNodeWidth,
          height: kTechTreeNodeHeight,
          decoration: BoxDecoration(
            color: style.fillColor,
            border: Border.all(
              color: style.borderColor,
              width: style.borderWidth,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNodeLabel(style.locked),
                TechGpPennantRow(
                  game: game,
                  techId: tech.id,
                  contextPlayerId: contextPlayerId,
                  compact: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _TechTreeNodeStyle _nodeStyle() {
    final color =
        kTechTreeCategoryColors[tech.category] ?? EditorialMonoclePalette.muted;
    final locked = !state.researched && !state.inProgress && !state.available;
    if (state.researched) {
      return _TechTreeNodeStyle(
        fillColor: color,
        borderColor: color.withValues(alpha: 0.8),
        borderWidth: 2,
        locked: locked,
      );
    }
    if (state.inProgress) {
      return _TechTreeNodeStyle(
        fillColor: color.withValues(alpha: 0.4),
        borderColor: color,
        borderWidth: 3,
        locked: locked,
      );
    }
    if (state.available) {
      return _TechTreeNodeStyle(
        fillColor: color.withValues(alpha: 0.15),
        borderColor: color,
        borderWidth: 2,
        locked: locked,
      );
    }
    return _TechTreeNodeStyle(
      fillColor: EditorialMonoclePalette.surface,
      borderColor: EditorialMonoclePalette.border,
      borderWidth: 1,
      locked: locked,
    );
  }

  Widget _buildNodeLabel(bool locked) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (kTechTreeCategoryIcons.containsKey(tech.category))
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: StrictAssetIcon(
              assetPath: kTechTreeCategoryIcons[tech.category]!,
              width: 16,
              height: 16,
            ),
          ),
        Flexible(
          child: Text(
            techDisplayName(tech.id),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: locked ? EditorialMonoclePalette.muted : null,
              fontWeight: state.researched ? FontWeight.w600 : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _TechTreeNodeStyle {
  const _TechTreeNodeStyle({
    required this.fillColor,
    required this.borderColor,
    required this.borderWidth,
    required this.locked,
  });

  final Color fillColor;
  final Color borderColor;
  final double borderWidth;
  final bool locked;
}
