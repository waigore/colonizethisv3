/// Debug console session commands (Refs #4136 Slice B).

import '../diplomacy.dart';
import 'session_command_event_base.dart';

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
