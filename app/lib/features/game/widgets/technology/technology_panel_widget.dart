// Technology panel screen widget. SPEC/ui/technology-panel.md.
//
// De-parted wave-9 cluster (Refs #4117): explicit-import libraries replace the
// former part library. Public surface: [TechnologyPanel].

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../config/ui_screen_ids.dart';
import '../../../../widgets/ct_spacing.dart';
import 'technology_panel_body.dart';

/// Technology panel (UXD 03k / GAME40001). Shows researched techs and
/// research slots for a player under the dark editorial-monocle theme.
class TechnologyPanel extends StatelessWidget {
  const TechnologyPanel({
    super.key,
    required this.game,
    required this.player,
    this.currentOrders = const Orders(),
    this.onOrdersChanged,
  });

  /// SPEC/ui/technology-panel.md — [UiScreenIds.technologyScreen]. Hosted by
  /// `TechnologyScreen`; shares its stable surface ID.
  static const screenId = UiScreenIds.technologyScreen;

  final Game game;
  final Player player;
  final Orders currentOrders;
  final void Function(Orders orders)? onOrdersChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final researchedIds = sortedResearchedTechIds();
    final progress = player.researchProgressByTechId ?? const <String, int>{};
    final slots = player.researchSlots ?? 3;
    final humanPlayerId = player.id;
    final researchOrdersForPlayer = this.researchOrdersForPlayer(humanPlayerId);
    final canEdit = onOrdersChanged != null;

    return Padding(
      padding: const EdgeInsets.all(CtSpacing.l),
      child: buildPanelBody(
        context: context,
        l10n: l10n,
        researchedIds: researchedIds,
        progress: progress,
        slots: slots,
        humanPlayerId: humanPlayerId,
        researchOrdersForPlayer: researchOrdersForPlayer,
        canEdit: canEdit,
      ),
    );
  }
}
