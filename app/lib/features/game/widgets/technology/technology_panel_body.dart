// Slots-tab body assembly for [TechnologyPanel].
// Split from `technology_panel.dart` to keep the host under the repo
// file-size target (Refs #3878).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_brass_divider.dart';
import '../../../../widgets/ct_gap.dart';
import 'research_slot_preview.dart';
import 'research_slot_spy_insight.dart';
import 'research_turn_funding_header.dart';
import 'technology_panel_research_slots.dart';
import 'technology_panel_widgets.dart';

Widget buildTechnologyPanelSlotsBody({
  required BuildContext context,
  required AppLocalizations l10n,
  required Game game,
  required Player player,
  required Orders currentOrders,
  required void Function(Orders orders)? onOrdersChanged,
}) {
  final researchedIds = sortedResearchedTechIds(player);
  final progress = player.researchProgressByTechId ?? const <String, int>{};
  final slots = player.researchSlots ?? 3;
  final humanPlayerId = player.id;
  final researchOrdersForPlayer = researchOrdersForTechnologyPlayer(
    currentOrders,
    humanPlayerId,
  );
  final canEdit = onOrdersChanged != null;
  final occupiedPreviewInputs = <ResearchSlotPreviewInput>[];
  if (canEdit) {
    for (var index = 0; index < slots; index++) {
      final assignment = effectiveTechnologyAssignmentForSlot(
        player: player,
        index: index,
        researchOrdersForPlayer: researchOrdersForPlayer,
      );
      final techId = assignment?.techId;
      final tech = techId == null ? null : techById(techId);
      if (tech == null || assignment == null) {
        continue;
      }
      final insight = spyInsightForResearchPreview(
        game: game,
        playerId: humanPlayerId,
        techId: tech.id,
      );
      occupiedPreviewInputs.add(
        ResearchSlotPreviewInput(
          slotIndex: index,
          tech: tech,
          committedProgress: progress[techId] ?? 0,
          funding: assignment.funding,
          qualifyingRivalGpCount: insight.count,
          qualifyingRivalDisplayNames: insight.names,
        ),
      );
    }
  }
  final ResearchSlotsTurnPreview? slotsTurnPreview = canEdit
      ? computeResearchSlotsTurnPreview(
          player: player,
          occupiedSlots: occupiedPreviewInputs,
        )
      : null;

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
            for (final id in researchedIds) ResearchedTechChip(techId: id),
          ],
        ),
      CtGap.l,
      const CtBrassDivider(),
      CtGap.ml,
      TechSectionHeading(l10n.technologyPanel_researchSlotsHeading),
      const SizedBox(height: 6),
      if (slotsTurnPreview != null)
        ResearchTurnFundingHeader(preview: slotsTurnPreview),
      // Stretch every slot card to the full panel content width so the
      // locked Slot 4 placeholder is the same width as the active Slots
      // 1–3 (mockup `.slot-card` is a full-width block element).
      // SPEC/ui/technology-panel.md § Slot behaviour > Locked slot 4.
      // Refs #3510.
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(
          kTechnologyResearchSlotCount,
          (index) => buildTechnologyResearchSlot(
            context: context,
            l10n: l10n,
            index: index,
            slots: slots,
            progress: progress,
            humanPlayerId: humanPlayerId,
            researchOrdersForPlayer: researchOrdersForPlayer,
            canEdit: canEdit,
            game: game,
            player: player,
            currentOrders: currentOrders,
            onOrdersChanged: onOrdersChanged,
            turnPreview: slotsTurnPreview?.bySlotIndex[index],
          ),
        ),
      ),
      // The standalone "In progress" auxiliary block was removed (Refs
      // #3512): in-progress techs now keep occupying their slots via the
      // persisted `Player.researchSlotAssignments` and render exclusively
      // inside their slot cards, so there is no orphaned-progress list.
      // SPEC/ui/technology-panel.md § Slots tab — section ordering.
    ],
  );
}

List<String> sortedResearchedTechIds(Player player) {
  final techUnlocked = player.techUnlocked ?? const <String, bool>{};
  final researchedIds = techUnlocked.entries
      .where((entry) => entry.value)
      .map((entry) => entry.key)
      .toList();
  researchedIds.sort(sortTechnologyTechIdsByEraThenName);
  return researchedIds;
}

int sortTechnologyTechIdsByEraThenName(String a, String b) {
  final eraA = techById(a)?.era ?? 999;
  final eraB = techById(b)?.era ?? 999;
  final eraCmp = eraA.compareTo(eraB);
  if (eraCmp != 0) {
    return eraCmp;
  }
  return techDisplayName(a).compareTo(techDisplayName(b));
}

List<ResearchOrder> researchOrdersForTechnologyPlayer(
  Orders currentOrders,
  String playerId,
) {
  return currentOrders.researchOrdersByPlayerId[playerId] ??
      const <ResearchOrder>[];
}
