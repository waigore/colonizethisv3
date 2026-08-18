// Muted finish-time sentence on the Tree-opened tech dialog (Refs #4511).
//
// SPEC: SPEC/ui/tech-tree-widget.md § Description dialog (Finish-time);
// SPEC/ui/technology-panel.md § Slot turn preview (Finish-time line).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'research_slot_preview_inputs.dart';
import 'research_slot_turn_preview_view.dart';

/// At-current-funding finish line for a Tree-opened seated tech.
class TechTreeFinishLine extends StatelessWidget {
  const TechTreeFinishLine({
    super.key,
    required this.game,
    required this.player,
    required this.tech,
    required this.currentOrders,
  });

  /// Stable test key for the Tree dialog finish-time sentence.
  static const Key lineKey = Key('techTreeFinishLine');

  final Game game;
  final Player player;
  final TechDefinition tech;
  final Orders currentOrders;

  @override
  Widget build(BuildContext context) {
    final finish = researchFinishForSeatedTech(
      game: game,
      player: player,
      currentOrders: currentOrders,
      techId: tech.id,
    );
    if (finish == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        researchFinishLineLabel(
          l10n: appL10n(context),
          estimate: finish.estimate,
          calendarYear: finish.calendarYear,
        ),
        key: lineKey,
        style: TextStyle(
          color: EditorialMonoclePalette.muted,
          fontSize: 10,
          height: 1.25,
        ),
      ),
    );
  }
}
