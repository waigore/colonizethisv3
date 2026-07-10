/// Diplomatic order submission and negotiation-mood handlers.
/// SPEC/ui/diplomacy-panel.md.

part of 'diplomacy_panel.dart';

mixin _DiplomacyOrderActions
    on State<DiplomacyPanel>, _DiplomacyOrderActionsMood {
  void submitOrDialog(DiplomaticOrder order) {
    final pending =
        widget.currentOrders.diplomaticOrdersByPlayerId[widget.humanPlayerId] ??
        [];
    final alreadyPending = pending.any(
      (o) => o.type == order.type && o.targetFactionId == order.targetFactionId,
    );
    if (alreadyPending) {
      removeOrder(order.type, order.targetFactionId);
      emitNegotiationMood(
        leaderId: order.targetFactionId,
        offerQualityDelta: -0.25,
        stallCounter: pending.length,
        discriminator: '${order.type.name}:cancel',
      );
      return;
    }
    final needsParams =
        order.type == DiplomaticOrderType.grantAid ||
        order.type == DiplomaticOrderType.setSubsidy ||
        (order.type == DiplomaticOrderType.establishOverture &&
            order.overtureStage != null);
    if (needsParams) {
      showDialogForOrder(order);
    } else {
      showConfirmDialog(order);
    }
  }

  void showConfirmDialog(DiplomaticOrder order) {
    final actionLabel = diplomacyActionLabel(order);
    widget.bus.emit(
      ConfirmDialogEvent(
        title: actionLabel,
        message:
            'Confirm $actionLabel against ${targetName(order.targetFactionId)}?',
        onResult: (confirmed) {
          if (confirmed) {
            if (order.type == DiplomaticOrderType.breakAlliance) {
              breakAllianceImmediately(order.targetFactionId);
            } else {
              appendOrder(order);
            }
            emitNegotiationMood(
              leaderId: order.targetFactionId,
              offerQualityDelta: offerQualityDeltaFor(order.type),
              stallCounter: pendingCountForTarget(order.targetFactionId),
              discriminator: order.type.name,
            );
          }
        },
      ),
    );
  }

  void breakAllianceImmediately(String targetFactionId) {
    widget.bus.emit(
      BreakAllianceImmediatelyEvent(
        playerId: widget.humanPlayerId,
        targetFactionId: targetFactionId,
      ),
    );
  }

  String targetName(String factionId) {
    final p = widget.game.playerById(factionId);
    if (p != null) return p.displayName;
    for (final m in widget.game.minorNations) {
      if (m.id == factionId) return m.displayName ?? factionId;
    }
    for (final t in widget.game.tribes) {
      if (t.id == factionId) return t.displayName ?? factionId;
    }
    return factionId;
  }

  void showDialogForOrder(DiplomaticOrder order) {
    if (order.type == DiplomaticOrderType.grantAid ||
        order.type == DiplomaticOrderType.setSubsidy) {
      widget.bus.emit(
        OpenDialogEvent(grantOrSubsidyDialogId, {
          'targetFactionId': order.targetFactionId,
          'isSubsidy': order.type == DiplomaticOrderType.setSubsidy,
        }),
      );
    } else if (order.type == DiplomaticOrderType.establishOverture &&
        order.overtureStage != null) {
      showConfirmDialog(order);
    }
  }

  void removeOrder(DiplomaticOrderType type, String targetFactionId) {
    widget.bus.emit(
      RemoveDiplomaticOrderRequestedEvent(
        playerId: widget.humanPlayerId,
        type: type,
        targetFactionId: targetFactionId,
      ),
    );
  }

  void openDetail(DiplomacyRowData row) {
    widget.bus.emit(
      NavigateToRouteEvent(Routes.diplomacyDetail, {
        'game': widget.game,
        'humanPlayerId': widget.humanPlayerId,
        'factionId': row.factionId,
        'factionDisplayName': row.displayName,
        'kind': row.kind,
        'relation': row.relation,
      }),
    );
  }

  void appendOrder(DiplomaticOrder order) {
    widget.bus.emit(
      AppendDiplomaticOrderRequestedEvent(
        playerId: widget.humanPlayerId,
        order: order,
      ),
    );
  }
}
