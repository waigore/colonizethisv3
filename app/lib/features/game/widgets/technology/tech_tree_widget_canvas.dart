// Scrollable tech-tree canvas assembly for [TechTreeWidget].
// Split from `tech_tree_widget.dart` to keep the host under the repo
// file-size target (Refs #3878).

part of 'tech_tree_widget.dart';

extension _TechTreeWidgetCanvas on TechTreeWidget {
  Widget buildTechTreeCanvas({
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
          ...buildPositionedTechNodes(
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

  List<Widget> buildPositionedTechNodes({
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
}
