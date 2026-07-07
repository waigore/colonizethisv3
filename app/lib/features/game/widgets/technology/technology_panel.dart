import 'dart:async';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../config/editorial_monocle_palette.dart';
import '../../../../config/ui_screen_ids.dart';
import 'research_slot_preview.dart';
import '../../../../widgets/ct_brass_divider.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_spacing.dart';
import 'technology_panel_orders.dart';
import 'technology_panel_widgets.dart';

// Re-export the research slot-card widget family (extracted to keep this file
// under the `repo.game_widgets_file_size` cap) so existing importers and tests
// keep resolving `ResearchSlotCard`, `LockedResearchSlotCard`, the slot
// constants, `TechSectionHeading`, and `ResearchedTechChip` from this panel
// entrypoint.
export 'technology_panel_widgets.dart';

part 'technology_panel_body.dart';
part 'technology_panel_research_slots.dart';

/// Always-rendered slot count on the Slots tab.
///
/// SPEC/ui/technology-panel.md § Slot behaviour: "The Slots tab always
/// renders exactly four slot cards in slot-index order regardless of
/// `player.researchSlots`." Refs #2864 S0/S3.
const int kTechnologyResearchSlotCount = 4;

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
    final researchedIds = _sortedResearchedTechIds();
    final progress = player.researchProgressByTechId ?? const <String, int>{};
    final slots = player.researchSlots ?? 3;
    final humanPlayerId = player.id;
    final researchOrdersForPlayer = _researchOrdersForPlayer(humanPlayerId);
    final canEdit = onOrdersChanged != null;

    return Padding(
      padding: const EdgeInsets.all(CtSpacing.l),
      child: _buildPanelBody(
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
