// Scrollable tech-tree canvas assembly for [TechTreeWidget].
// Split from `tech_tree_widget.dart` to keep the host under the repo
// file-size target (Refs #3878).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'tech_tree_widget_canvas.dart';
import 'tech_tree_widget_constants.dart';
import 'tech_tree_widget_dialog.dart';
import 'tech_tree_widget_nodes.dart';
import 'tech_tree_widget_types.dart';

Widget buildTechTreeCanvas({
  required BuildContext context,
  required Game game,
  required Player player,
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
          painter: TechTreeEdgePainter(positions: positions),
        ),
        ...buildPositionedTechNodes(
          context: context,
          game: game,
          player: player,
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
  required Game game,
  required Player player,
  required List<TechNodePosition> positions,
  required Map<String, bool> unlocked,
  required Set<String> inProgress,
  required Set<String> researchable,
}) {
  return positions.map((pos) {
    final tech = techById(pos.techId);
    if (tech == null) return const SizedBox.shrink();
    final state = TechTreeNodeState(
      researched: unlocked[pos.techId] == true,
      inProgress: inProgress.contains(pos.techId),
      available: researchable.contains(pos.techId),
    );
    return Positioned(
      left: pos.x,
      top: pos.y,
      width: kTechTreeNodeWidth,
      height: kTechTreeNodeHeight,
      child: TechTreeNode(
        game: game,
        tech: tech,
        contextPlayerId: player.id,
        state: state,
        onTap: () => showTechTreeTechDialog(
          context,
          game: game,
          player: player,
          tech: tech,
        ),
      ),
    );
  }).toList();
}
