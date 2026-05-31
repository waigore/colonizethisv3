
part of 'tech_tree_widget.dart';

class _TechNodeState {
  const _TechNodeState({
    required this.researched,
    required this.inProgress,
    required this.available,
  });
  final bool researched;
  final bool inProgress;
  final bool available;
}

class _TechTreeEdgePainter extends CustomPainter {
  _TechTreeEdgePainter({required this.positions});

  final List<TechNodePosition> positions;

  static double get _centerY => _nodeHeight / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final posByTech = {for (final p in positions) p.techId: p};
    final paint = Paint()
      ..color = EditorialMonoclePalette.border
      ..strokeWidth = _edgeStrokeWidth
      ..style = PaintingStyle.stroke;

    for (final tech in techCatalog.values) {
      final toPos = posByTech[tech.id];
      if (toPos == null) continue;
      final toLeftX = toPos.x;
      final toCenterY = toPos.y + _centerY;
      for (final prereqId in tech.prerequisiteIds) {
        final fromPos = posByTech[prereqId];
        if (fromPos == null) continue;
        final fromRightX = fromPos.x + _nodeWidth;
        final fromCenterY = fromPos.y + _centerY;

        // Right-angled connector: horizontal into gap, vertical to target row, horizontal to target.
        // Layout reserves a row slot in intermediate columns so this segment does not pass through nodes.
        final bendX = fromRightX + _edgeBendOffset;
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
  bool shouldRepaint(covariant _TechTreeEdgePainter oldDelegate) => false;
}

class _TechNode extends StatelessWidget {
  const _TechNode({
    required this.tech,
    required this.state,
    required this.onTap,
  });

  final TechDefinition tech;
  final _TechNodeState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _nodeStyle();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: _nodeWidth,
          height: _nodeHeight,
          decoration: BoxDecoration(
            color: style.fillColor,
            border: Border.all(
              color: style.borderColor,
              width: style.borderWidth,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildNodeLabel(style.locked),
            ),
          ),
        ),
      ),
    );
  }

  _TechNodeStyle _nodeStyle() {
    final color = _categoryColors[tech.category] ?? EditorialMonoclePalette.muted;
    final locked = !state.researched && !state.inProgress && !state.available;
    if (state.researched) {
      return _TechNodeStyle(
        fillColor: color,
        borderColor: color.withValues(alpha: 0.8),
        borderWidth: 2,
        locked: locked,
      );
    }
    if (state.inProgress) {
      return _TechNodeStyle(
        fillColor: color.withValues(alpha: 0.4),
        borderColor: color,
        borderWidth: 3,
        locked: locked,
      );
    }
    if (state.available) {
      return _TechNodeStyle(
        fillColor: color.withValues(alpha: 0.15),
        borderColor: color,
        borderWidth: 2,
        locked: locked,
      );
    }
    return _TechNodeStyle(
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
        if (_categoryIcons.containsKey(tech.category))
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: StrictAssetIcon(
              assetPath: _categoryIcons[tech.category]!,
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

class _TechNodeStyle {
  const _TechNodeStyle({
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
