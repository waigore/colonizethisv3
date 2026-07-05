/// Diplomatic order submission and negotiation-mood handlers.
/// SPEC/ui/diplomacy-panel.md.

part of 'diplomacy_panel.dart';

mixin _DiplomacyOrderActions on State<DiplomacyPanel> {
  Map<String, String> get moodByLeaderId;

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

  int pendingCountForTarget(String targetFactionId) {
    final list =
        widget.currentOrders.diplomaticOrdersByPlayerId[widget.humanPlayerId] ??
        const <DiplomaticOrder>[];
    return list.where((o) => o.targetFactionId == targetFactionId).length;
  }

  double offerQualityDeltaFor(DiplomaticOrderType type) {
    switch (type) {
      case DiplomaticOrderType.declareWar:
        return -0.8;
      case DiplomaticOrderType.offerPeace:
        return 0.6;
      case DiplomaticOrderType.alliance:
        return 0.4;
      case DiplomaticOrderType.breakAlliance:
        return -0.4;
      case DiplomaticOrderType.establishOverture:
        return 0.5;
      case DiplomaticOrderType.grantAid:
        return 0.7;
      case DiplomaticOrderType.setSubsidy:
        return 0.5;
      case DiplomaticOrderType.establishFtp:
        return 0.5;
      case DiplomaticOrderType.boycott:
        return -0.6;
      case DiplomaticOrderType.revokeBoycott:
        return 0.3;
    }
  }

  int stableSeed({
    required String leaderId,
    required String discriminator,
    required int stallCounter,
  }) {
    final turn = widget.game.worldState.turnState.turnNumber;
    final base = widget.game.globalGameSeed ?? 0;
    final text = '$leaderId|$discriminator|$stallCounter|$turn';
    var hash = kFnv1aOffsetBasis32;
    for (final code in text.codeUnits) {
      hash ^= code;
      hash = (hash * kFnv1aPrime32) & kDeterministicLcg31Mask;
    }
    return base ^ hash;
  }

  void emitNegotiationMood({
    required String leaderId,
    required double offerQualityDelta,
    required int stallCounter,
    required String discriminator,
  }) {
    final currentMood = moodByLeaderId[leaderId] ?? kDefaultMood;
    widget.bus.emit(
      NegotiationMoodUpdateEvent(
        leaderId: leaderId,
        currentMood: currentMood,
        offerQualityDelta: offerQualityDelta,
        stallCounter: stallCounter,
        seed: stableSeed(
          leaderId: leaderId,
          discriminator: discriminator,
          stallCounter: stallCounter,
        ),
      ),
    );
  }
}
