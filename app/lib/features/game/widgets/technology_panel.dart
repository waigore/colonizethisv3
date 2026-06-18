import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../../../config/ui_screen_ids.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_brass_divider.dart';
import '../../../widgets/ct_section_label.dart';
import '../../../widgets/ct_spacing.dart';
import 'technology_panel_orders.dart';
import 'technology_panel_widgets.dart';

export 'technology_panel_widgets.dart';

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
      child: _buildPanelContent(
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

  Widget _buildPanelContent({
    required BuildContext context,
    required AppLocalizations l10n,
    required List<String> researchedIds,
    required Map<String, int> progress,
    required int slots,
    required String humanPlayerId,
    required List<ResearchOrder> researchOrdersForPlayer,
    required bool canEdit,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // No dev-only panel header block: the per-player title and the
        // research-slot count line are intentionally omitted so the Slots
        // tab body opens directly with the Researched Techs heading, matching
        // the mockup (`SPEC/ui/mockups/GAME40001-technology-panel.html` opens
        // with `.researched-heading`). Player identity and the `Technology`
        // title are carried by the `CtTopBar` chrome. Refs #3510.
        // Researched Techs renders ABOVE Research Slots per
        // SPEC/ui/technology-panel.md § Layout / wireframe > Body section
        // ordering and matches the mockup body markup in
        // SPEC/ui/mockups/GAME40001-technology-panel.html where
        // `.researched-heading` precedes `.slots-heading`. Refs #2864 S0/S6.
        // The two canonical Slots-tab headings use the mockup-faithful
        // accent display-font `TechSectionHeading` (mockup
        // `.researched-heading` / `.slots-heading`) rather than the small-caps
        // `CtSectionLabel` chrome; per the issue source-of-truth precedence
        // the mockup wins on this purely visual heading detail. Refs #3510.
        TechSectionHeading(l10n.technologyPanel_researchedTechsHeading),
        const SizedBox(height: 6),
        if (researchedIds.isEmpty)
          Text(
            l10n.technologyPanel_noneYet,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: EditorialMonoclePalette.muted,
                  fontStyle: FontStyle.italic,
                ),
          )
        else
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final id in researchedIds)
                ResearchedTechChip(techId: id),
            ],
          ),
        const SizedBox(height: 16),
        const CtBrassDivider(),
        const SizedBox(height: 12),
        TechSectionHeading(l10n.technologyPanel_researchSlotsHeading),
        const SizedBox(height: 6),
        // Stretch every slot card to the full panel content width so the
        // locked Slot 4 placeholder is the same width as the active Slots
        // 1–3 (mockup `.slot-card` is a full-width block element).
        // SPEC/ui/technology-panel.md § Slot behaviour > Locked slot 4.
        // Refs #3510.
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(
            kTechnologyResearchSlotCount,
            (index) => _buildResearchSlot(
              context: context,
              l10n: l10n,
              index: index,
              slots: slots,
              progress: progress,
              humanPlayerId: humanPlayerId,
              researchOrdersForPlayer: researchOrdersForPlayer,
              canEdit: canEdit,
            ),
          ),
        ),
        if (progress.isNotEmpty) ...[
          const SizedBox(height: 12),
          CtSectionLabel(l10n.technologyPanel_inProgress),
          const SizedBox(height: 4),
          ...progress.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l10n.technologyPanel_progressLine(
                  techDisplayName(entry.key),
                  entry.value,
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: EditorialMonoclePalette.muted,
                    ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<String> _sortedResearchedTechIds() {
    final techUnlocked = player.techUnlocked ?? const <String, bool>{};
    final researchedIds = techUnlocked.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    researchedIds.sort(_sortTechIdsByEraThenName);
    return researchedIds;
  }

  int _sortTechIdsByEraThenName(String a, String b) {
    final eraA = techById(a)?.era ?? 999;
    final eraB = techById(b)?.era ?? 999;
    final eraCmp = eraA.compareTo(eraB);
    if (eraCmp != 0) {
      return eraCmp;
    }
    return techDisplayName(a).compareTo(techDisplayName(b));
  }

  List<ResearchOrder> _researchOrdersForPlayer(String playerId) {
    return currentOrders.researchOrdersByPlayerId[playerId] ??
        const <ResearchOrder>[];
  }

  Widget _buildResearchSlot({
    required BuildContext context,
    required AppLocalizations l10n,
    required int index,
    required int slots,
    required Map<String, int> progress,
    required String humanPlayerId,
    required List<ResearchOrder> researchOrdersForPlayer,
    required bool canEdit,
  }) {
    final isLockedFourthSlot =
        index == kTechnologyResearchSlotCount - 1 && slots < 4;
    if (isLockedFourthSlot) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: LockedResearchSlotCard(slotNumber: index + 1),
      );
    }
    final order = _researchOrderForSlot(researchOrdersForPlayer, index);
    final techId = _slotTechId(order);
    final tech = techId == null ? null : techById(techId);
    final techProgress = techId == null ? 0 : (progress[techId] ?? 0);
    final cost = tech?.cost ?? 0;
    final hasTech = techId != null;
    final funding = order?.funding ?? ResearchFundingLevel.medium;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ResearchSlotCard(
        slotIndex: index,
        techId: techId,
        progress: techProgress,
        cost: cost,
        canEdit: canEdit,
        funding: funding,
        onFundingChanged: hasTech && canEdit
            ? (level) => onOrdersChanged!(
                  applySetSlotFunding(
                    currentOrders: currentOrders,
                    humanPlayerId: humanPlayerId,
                    slotIndex: index,
                    funding: level,
                  ),
                )
            : null,
        onCancel: hasTech && canEdit
            ? () {
                applyCancelSlotOrder(
                  context: context,
                  slotIndex: index,
                  humanPlayerId: humanPlayerId,
                  currentOrders: currentOrders,
                  onOrdersChanged: onOrdersChanged!,
                );
              }
            : null,
        onChooseTech: canEdit
            ? () {
                showChooseTechDialog(
                  context: context,
                  game: game,
                  slotIndex: index,
                  humanPlayerId: humanPlayerId,
                  currentOrders: currentOrders,
                  player: player,
                  onOrdersChanged: onOrdersChanged!,
                );
              }
            : null,
      ),
    );
  }

  ResearchOrder? _researchOrderForSlot(List<ResearchOrder> orders, int index) {
    for (final order in orders) {
      if (order.slotIndex == index) {
        return order;
      }
    }
    return null;
  }

  String? _slotTechId(ResearchOrder? order) {
    if (order == null || order.techId.isEmpty) {
      return null;
    }
    return order.techId;
  }
}

