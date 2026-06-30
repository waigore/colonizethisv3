part of '../app_events.dart';

// ---------------------------------------------------------------------------
// SessionCommandEvent — applied by long-lived shell listeners, not AppEventHandler.
// ---------------------------------------------------------------------------

/// Session-scoped commands: listeners use a stable [ProviderScope] ref (e.g.
/// [AppEventHandlerScope]). **Do not** capture [WidgetRef] from widgets that
/// unmount when opening panels (side menus, sheets). SPEC/program/app-event-bus.md.
sealed class SessionCommandEvent extends AppEvent {
  const SessionCommandEvent();
}

/// Remove pending civilian work order at [index] for [playerId] in current-turn
/// draft. Shell listener applies the canonical mutation from colonizethis_logic.
class RemovePendingWorkOrderRequestedEvent extends SessionCommandEvent {
  RemovePendingWorkOrderRequestedEvent({
    required this.playerId,
    required this.index,
  });

  final String playerId;
  final int index;
}

/// Clear in-progress civilian work for [unitId] (no refund). Shell listener
/// applies the canonical mutation from colonizethis_logic and persists game.
class CancelInProgressCivilianWorkRequestedEvent extends SessionCommandEvent {
  CancelInProgressCivilianWorkRequestedEvent({required this.unitId});

  final String unitId;
}

/// Upsert one pending civilian [workOrder] for [playerId] in current-turn draft.
/// Replaces any existing pending work for the same unit and clears conflicting
/// pending move order for that unit (work-order draft xor rule).
class UpsertPendingCivilianWorkOrderRequestedEvent extends SessionCommandEvent {
  UpsertPendingCivilianWorkOrderRequestedEvent({
    required this.playerId,
    required this.workOrder,
  });

  final String playerId;
  final WorkOrder workOrder;
}

/// Naval panel produced an updated [game] (split/combine). Handler updates session game.
class NavalFleetsUpdatedEvent extends SessionCommandEvent {
  NavalFleetsUpdatedEvent({required this.game});

  final Game game;
}

/// Split fleet dialog confirm: shell applies split and emits [NavalFleetsUpdatedEvent]
/// (same pipeline as combine). SPEC/program/app-ui-wiring.md.
class NavalSplitFleetRequestedEvent extends SessionCommandEvent {
  NavalSplitFleetRequestedEvent({
    required this.humanPlayerId,
    required this.originalFleetId,
    required this.shipInstanceIdsToNewFleet,
  });

  final String humanPlayerId;
  final String originalFleetId;
  final List<String> shipInstanceIdsToNewFleet;
}

/// Transfer selected ship instances from one existing fleet into another.
/// Shell listener applies canonical fleet mutation and emits
/// [NavalFleetsUpdatedEvent]. SPEC/program/app-ui-wiring.md.
class NavalTransferShipsRequestedEvent extends SessionCommandEvent {
  NavalTransferShipsRequestedEvent({
    required this.humanPlayerId,
    required this.sourceFleetId,
    required this.targetFleetId,
    required this.shipInstanceIdsToTransfer,
  });

  final String humanPlayerId;
  final String sourceFleetId;
  final String targetFleetId;
  final List<String> shipInstanceIdsToTransfer;
}

/// Move fleet dialog confirm: shell merges [moveOrder] into current-turn draft orders.
/// SPEC/program/app-ui-wiring.md.
class NavalMoveFleetRequestedEvent extends SessionCommandEvent {
  NavalMoveFleetRequestedEvent({
    required this.humanPlayerId,
    required this.moveOrder,
  });

  final String humanPlayerId;
  final NavalMoveOrder moveOrder;
}

/// Military units panel: game state updated after army split/combine.
/// SPEC/program/app-ui-wiring.md.
class LandArmiesUpdatedEvent extends SessionCommandEvent {
  LandArmiesUpdatedEvent({required this.game});

  final Game game;
}

/// Combine selected armies in the same province (shell applies colonizethis_logic).
class ArmyCombineRequestedEvent extends SessionCommandEvent {
  ArmyCombineRequestedEvent({
    required this.humanPlayerId,
    required this.armyIds,
  });

  final String humanPlayerId;
  final List<String> armyIds;
}

/// Split confirmed from split-army dialog (shell applies colonizethis_logic).
class ArmySplitRequestedEvent extends SessionCommandEvent {
  ArmySplitRequestedEvent({
    required this.humanPlayerId,
    required this.sourceArmyId,
    required this.unitIdsToMove,
  });

  final String humanPlayerId;
  final String sourceArmyId;
  final List<String> unitIdsToMove;
}

/// Move army dialog confirm: merges [moveOrder] into current-turn draft orders.
///
/// When [declareWarTargetFactionId] is set, the shell appends a same-turn
/// `declareWar` on that faction before applying [moveOrder] (invasion path).
class ArmyMoveRequestedEvent extends SessionCommandEvent {
  ArmyMoveRequestedEvent({
    required this.humanPlayerId,
    required this.moveOrder,
    this.declareWarTargetFactionId,
  });

  final String humanPlayerId;
  final ArmyMoveOrder moveOrder;

  /// Great Power / Minor / Tribe id to declare war on when the move required
  /// the invasion confirmation flow. Null for normal moves and when already at war.
  final String? declareWarTargetFactionId;
}

/// Train civilians dialog close: shell merges into current-turn orders draft.
class TrainCivilianBuildOrdersCommittedEvent extends SessionCommandEvent {
  TrainCivilianBuildOrdersCommittedEvent({required this.orders});

  final List<BuildUnitOrder> orders;
}

/// Train military dialog close: shell merges into current-turn orders draft.
class TrainMilitaryBuildOrdersCommittedEvent extends SessionCommandEvent {
  TrainMilitaryBuildOrdersCommittedEvent({required this.orders});

  final List<BuildUnitOrder> orders;
}

/// Train naval dialog close: shell merges into current-turn orders draft.
///
/// Carries naval [BuildUnitOrder]s (`isMilitary: false`, ship unit types
/// spawned at the player's capital). The shell listener replaces only
/// dialog-managed naval build orders, leaving civilian build orders intact.
/// SPEC/ui/train-naval-dialog.md, SPEC/program/app-ui-wiring.md.
class TrainNavalBuildOrdersCommittedEvent extends SessionCommandEvent {
  TrainNavalBuildOrdersCommittedEvent({required this.orders});

  final List<BuildUnitOrder> orders;
}

/// Immediate debug spawn at the human player's capital tile.
class SpawnDebugCivilianAtCapitalEvent extends SessionCommandEvent {
  const SpawnDebugCivilianAtCapitalEvent({
    required this.humanPlayerId,
    required this.unitType,
    this.count = 1,
  });

  final String humanPlayerId;
  final String unitType;
  final int count;
}

/// Immediate debug military regiment spawn at the human player's capital.
class SpawnDebugRegimentAtCapitalEvent extends SessionCommandEvent {
  const SpawnDebugRegimentAtCapitalEvent({
    required this.humanPlayerId,
    required this.regimentTypeId,
    this.count = 1,
  });

  final String humanPlayerId;
  final String regimentTypeId;
  final int count;
}

/// Immediate debug ship spawn into the human player's home fleet at capital.
class SpawnDebugShipAtCapitalHomeFleetEvent extends SessionCommandEvent {
  const SpawnDebugShipAtCapitalHomeFleetEvent({
    required this.humanPlayerId,
    required this.shipTypeId,
    this.count = 1,
  });

  final String humanPlayerId;
  final String shipTypeId;
  final int count;
}

/// Immediate debug treasury credit for the human player (no economy modifiers).
class CreditDebugTreasuryEvent extends SessionCommandEvent {
  const CreditDebugTreasuryEvent({
    required this.humanPlayerId,
    required this.requestedAmount,
    required this.creditedAmount,
  });

  final String humanPlayerId;
  final int requestedAmount;
  final int creditedAmount;
}

/// Immediate debug industrial worker-pool credit for the human player.
///
/// [workerTierId] is one of `WorkerPool` JSON field names:
/// `peasants`, `apprentices`, `journeymen`, `masters`.
class CreditDebugWorkerPoolEvent extends SessionCommandEvent {
  const CreditDebugWorkerPoolEvent({
    required this.humanPlayerId,
    required this.workerTierId,
    required this.requestedAmount,
    required this.creditedAmount,
  });

  final String humanPlayerId;
  final String workerTierId;
  final int requestedAmount;
  final int creditedAmount;
}

/// Immediate debug stockpile commodity credit for the human player.
class CreditDebugStockpileCommodityEvent extends SessionCommandEvent {
  const CreditDebugStockpileCommodityEvent({
    required this.humanPlayerId,
    required this.commodityId,
    required this.requestedAmount,
    required this.creditedAmount,
  });

  final String humanPlayerId;
  final String commodityId;
  final int requestedAmount;
  final int creditedAmount;
}

/// Immediate debug province ownership transfer for the active human player.
class FlipDebugProvinceOwnershipEvent extends SessionCommandEvent {
  const FlipDebugProvinceOwnershipEvent({
    required this.humanPlayerId,
    this.fullProvinceId,
    this.regionId,
    this.provinceDisplayName,
  }) : assert(
         (fullProvinceId != null &&
                 regionId == null &&
                 provinceDisplayName == null) ||
             (fullProvinceId == null &&
                 regionId != null &&
                 provinceDisplayName != null),
         'FlipDebugProvinceOwnershipEvent requires fullProvinceId OR regionId+provinceDisplayName.',
       );

  final String humanPlayerId;
  final String? fullProvinceId;
  final String? regionId;
  final String? provinceDisplayName;
}

/// Immediate debug province visibility reveal for the active human player.
class RevealDebugProvinceEvent extends SessionCommandEvent {
  const RevealDebugProvinceEvent({
    required this.humanPlayerId,
    required this.target,
    required this.targetIsFullProvinceId,
  });

  final String humanPlayerId;
  final String target;
  final bool targetIsFullProvinceId;
}

/// Immediate debug diplomacy relation mutation between two factions.
///
/// When [factionA] is `null`, the active human player ([humanPlayerId]) is the
/// first faction. [factionB] and the optional [factionA] are raw identifier
/// inputs (faction id or display name) resolved by the app apply handler.
/// Directly mutates `Game` state (bypasses normal diplomacy resolution).
/// SPEC/ui/debug-console-panel.md, SPEC/program/debug-console-internals.md.
class SetDebugDiplomacyRelationEvent extends SessionCommandEvent {
  const SetDebugDiplomacyRelationEvent({
    required this.humanPlayerId,
    required this.factionB,
    required this.action,
    this.factionA,
  });

  final String humanPlayerId;

  /// First faction (initiator) raw input; `null` means the active human player.
  final String? factionA;

  /// Second faction (target) raw input. Never empty.
  final String factionB;

  final DebugDiplomacyAction action;
}

/// Exit in-app observe mode. SPEC/ui/observe-mode.md.
class SetObserveModeOffEvent extends SessionCommandEvent {
  const SetObserveModeOffEvent();
}

/// Enter global (omniscient) in-app observe mode. SPEC/ui/observe-mode.md.
class SetObserveModeGlobalEvent extends SessionCommandEvent {
  const SetObserveModeGlobalEvent();
}

/// Enter player-scoped in-app observe mode for [targetPlayerId].
class SetObserveModePlayerEvent extends SessionCommandEvent {
  const SetObserveModePlayerEvent({required this.targetPlayerId});

  final String targetPlayerId;
}

/// Request to append one diplomatic order for [playerId] in current-turn draft.
class AppendDiplomaticOrderRequestedEvent extends SessionCommandEvent {
  AppendDiplomaticOrderRequestedEvent({
    required this.playerId,
    required this.order,
  });

  final String playerId;
  final DiplomaticOrder order;
}

/// Request to remove one pending diplomatic order by [type] and [targetFactionId]
/// for [playerId] in current-turn draft.
class RemoveDiplomaticOrderRequestedEvent extends SessionCommandEvent {
  RemoveDiplomaticOrderRequestedEvent({
    required this.playerId,
    required this.type,
    required this.targetFactionId,
  });

  final String playerId;
  final DiplomaticOrderType type;
  final String targetFactionId;
}

/// Immediate voluntary Break Alliance from the diplomacy panel (Refs #3811).
///
/// Applies break penalties inline during Orders phase without queuing a
/// pending `DiplomaticOrder`. SPEC/ui/diplomacy-panel.md § Submitting an action.
class BreakAllianceImmediatelyEvent extends SessionCommandEvent {
  BreakAllianceImmediatelyEvent({
    required this.playerId,
    required this.targetFactionId,
  });

  final String playerId;
  final String targetFactionId;
}

/// Negotiation UI mood input for portrait transitions.
///
/// UI supplies deterministic negotiation inputs; session listeners compute the
/// next mood and emit [PortraitMoodEvent] when the mood changes.
class NegotiationMoodUpdateEvent extends SessionCommandEvent {
  const NegotiationMoodUpdateEvent({
    required this.leaderId,
    required this.currentMood,
    required this.offerQualityDelta,
    required this.stallCounter,
    required this.seed,
    this.durationMs = 1200,
  });

  final String leaderId;
  final String currentMood;
  final double offerQualityDelta;
  final int stallCounter;
  final int seed;
  final int durationMs;
}
