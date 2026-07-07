// Research-slot card builder and occupancy reconciliation for
// [TechnologyPanel]. Split from `technology_panel.dart` to keep the
// host file under the repo file-size target (Refs #3878).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
part of 'technology_panel.dart';

extension _TechnologyPanelResearchSlots on TechnologyPanel {
  Widget buildResearchSlot({
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
    final assignment = effectiveAssignmentForSlot(
      index,
      researchOrdersForPlayer,
    );
    final techId = assignment?.techId;
    final tech = techId == null ? null : techById(techId);
    final techProgress = techId == null ? 0 : (progress[techId] ?? 0);
    final cost = tech?.cost ?? 0;
    final hasTech = techId != null;
    final funding = assignment?.funding ?? ResearchFundingLevel.medium;
    // The turn preview accompanies the editable funding controls, so it renders
    // only on the editable (human, own-orders) panel; read-only panels keep the
    // simple committed-progress bar. Refs #3512.
    final turnPreview = (tech == null || !canEdit)
        ? null
        : computeResearchSlotTurnPreview(
            player: player,
            tech: tech,
            committedProgress: techProgress,
            funding: funding,
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ResearchSlotCard(
        slotIndex: index,
        techId: techId,
        progress: techProgress,
        cost: cost,
        canEdit: canEdit,
        funding: funding,
        turnPreview: turnPreview,
        onFundingChanged: hasTech && canEdit
            ? (level) => onOrdersChanged!(
                  applySetSlotFunding(
                    currentOrders: currentOrders,
                    humanPlayerId: humanPlayerId,
                    slotIndex: index,
                    funding: level,
                    techId: techId,
                  ),
                )
            : null,
        onCancel: hasTech && canEdit
            ? () {
                unawaited(
                  applyCancelSlotOrder(
                    context: context,
                    slotIndex: index,
                    humanPlayerId: humanPlayerId,
                    currentOrders: currentOrders,
                    onOrdersChanged: onOrdersChanged!,
                    techId: techId,
                    accruedProgress: techProgress,
                  ),
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

  /// Effective tech + funding occupying [index] this turn.
  ///
  /// Mirrors the resolver's reconciliation (`research_resolver.dart`
  /// `_effectiveSlotAssignments`): the durable `Player.researchSlotAssignments`
  /// entry for the slot is the baseline, then this turn's
  /// `Orders.researchOrdersByPlayerId` override it as the UI mutation surface —
  /// a non-empty order assigns/updates the slot, an empty-`techId` order (the
  /// Cancel signal) frees it. Returns `null` for an empty slot. Only
  /// catalog-known techs are surfaced so a stale persisted id never renders an
  /// unknown tech. SPEC/program/research-resolution.md § Slot occupancy
  /// persistence; SPEC/ui/technology-panel.md § Slot behaviour. Refs #3512.
  ResearchSlotAssignment? effectiveAssignmentForSlot(
    int index,
    List<ResearchOrder> orders,
  ) {
    ResearchOrder? order;
    for (final candidate in orders) {
      if (candidate.slotIndex == index) {
        order = candidate;
      }
    }
    if (order != null) {
      if (order.techId.isEmpty || techById(order.techId) == null) {
        return null;
      }
      return ResearchSlotAssignment(
        techId: order.techId,
        funding: order.funding,
      );
    }
    final persisted = player.researchSlotAssignments?[index];
    if (persisted == null ||
        persisted.techId.isEmpty ||
        techById(persisted.techId) == null) {
      return null;
    }
    return persisted;
  }
}
