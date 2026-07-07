// Slots-tab body assembly for [TechnologyPanel].
// Split from `technology_panel.dart` to keep the host under the repo
// file-size target (Refs #3878).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
part of 'technology_panel.dart';

extension _TechnologyPanelBody on TechnologyPanel {
  Widget _buildPanelBody({
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
        CtGap.l,
        const CtBrassDivider(),
        CtGap.ml,
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
            (index) => buildResearchSlot(
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
        // The standalone "In progress" auxiliary block was removed (Refs
        // #3512): in-progress techs now keep occupying their slots via the
        // persisted `Player.researchSlotAssignments` and render exclusively
        // inside their slot cards, so there is no orphaned-progress list.
        // SPEC/ui/technology-panel.md § Slots tab — section ordering.
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
}
