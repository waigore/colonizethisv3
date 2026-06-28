import 'package:colonizethis_models/colonizethis_models.dart';

/// Parser output for one accepted debug slash command: validated verb + args.
///
/// Mapped to [SessionCommandEvent] by [DebugConsoleCommandExecutor]. Carries
/// only parser-validated data; [humanPlayerId] and persistence are applied in
/// the app session layer.
sealed class DebugConsoleParsedInvocation {
  const DebugConsoleParsedInvocation();

  const factory DebugConsoleParsedInvocation.spawnCivilianAtCapital({
    required String unitType,
    required int count,
  }) = DebugConsoleSpawnCivilianAtCapital;

  const factory DebugConsoleParsedInvocation.spawnRegimentAtCapital({
    required String regimentTypeId,
    required int count,
  }) = DebugConsoleSpawnRegimentAtCapital;

  const factory DebugConsoleParsedInvocation.spawnShipAtCapitalHomeFleet({
    required String shipTypeId,
    required int count,
  }) = DebugConsoleSpawnShipAtCapitalHomeFleet;

  const factory DebugConsoleParsedInvocation.treasuryCredit({
    required int requestedAmount,
    required int creditedAmount,
  }) = DebugConsoleTreasuryCredit;

  const factory DebugConsoleParsedInvocation.workerPoolCredit({
    required String workerTierId,
    required int requestedAmount,
    required int creditedAmount,
  }) = DebugConsoleWorkerPoolCredit;

  const factory DebugConsoleParsedInvocation.stockpileCredit({
    required String commodityId,
    required int requestedAmount,
    required int creditedAmount,
  }) = DebugConsoleStockpileCredit;

  const factory DebugConsoleParsedInvocation.flipProvince({
    String? fullProvinceId,
    String? regionId,
    String? provinceDisplayName,
  }) = DebugConsoleFlipProvince;

  const factory DebugConsoleParsedInvocation.revealProvince({
    required String target,
    required bool targetIsFullProvinceId,
  }) = DebugConsoleRevealProvince;

  const factory DebugConsoleParsedInvocation.getTileBasicInfo() =
      DebugConsoleGetTileBasicInfo;

  const factory DebugConsoleParsedInvocation.listPlayers() =
      DebugConsoleListPlayers;

  const factory DebugConsoleParsedInvocation.setObserveOff() =
      DebugConsoleSetObserveOff;

  const factory DebugConsoleParsedInvocation.setObserveGlobal() =
      DebugConsoleSetObserveGlobal;

  const factory DebugConsoleParsedInvocation.setObservePlayer({
    required String target,
  }) = DebugConsoleSetObservePlayer;

  const factory DebugConsoleParsedInvocation.setDiplomacy({
    String? factionA,
    required String factionB,
    required DebugDiplomacyAction action,
  }) = DebugConsoleSetDiplomacy;
}

final class DebugConsoleSpawnCivilianAtCapital
    extends DebugConsoleParsedInvocation {
  const DebugConsoleSpawnCivilianAtCapital({
    required this.unitType,
    required this.count,
  });

  final String unitType;
  final int count;
}

final class DebugConsoleSpawnRegimentAtCapital
    extends DebugConsoleParsedInvocation {
  const DebugConsoleSpawnRegimentAtCapital({
    required this.regimentTypeId,
    required this.count,
  });

  final String regimentTypeId;
  final int count;
}

final class DebugConsoleSpawnShipAtCapitalHomeFleet
    extends DebugConsoleParsedInvocation {
  const DebugConsoleSpawnShipAtCapitalHomeFleet({
    required this.shipTypeId,
    required this.count,
  });

  final String shipTypeId;
  final int count;
}

final class DebugConsoleTreasuryCredit extends DebugConsoleParsedInvocation {
  const DebugConsoleTreasuryCredit({
    required this.requestedAmount,
    required this.creditedAmount,
  });

  /// Raw integer from user input before upper-bound clamp.
  final int requestedAmount;

  /// Amount applied after clamp to the debug-console treasury credit cap (9999).
  final int creditedAmount;
}

final class DebugConsoleWorkerPoolCredit extends DebugConsoleParsedInvocation {
  const DebugConsoleWorkerPoolCredit({
    required this.workerTierId,
    required this.requestedAmount,
    required this.creditedAmount,
  });

  /// Canonical `WorkerPool` tier field name (`peasants`, `apprentices`, …).
  final String workerTierId;

  /// Raw integer from user input before upper-bound clamp.
  final int requestedAmount;

  /// Amount applied after clamp to the debug-console credit cap (9999).
  final int creditedAmount;
}

final class DebugConsoleStockpileCredit extends DebugConsoleParsedInvocation {
  const DebugConsoleStockpileCredit({
    required this.commodityId,
    required this.requestedAmount,
    required this.creditedAmount,
  });

  final String commodityId;

  /// Raw integer from user input before upper-bound clamp.
  final int requestedAmount;

  /// Amount applied after clamp to the debug-console stockpile credit cap (9999).
  final int creditedAmount;
}

final class DebugConsoleFlipProvince extends DebugConsoleParsedInvocation {
  const DebugConsoleFlipProvince({
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
         'flipProvince requires either fullProvinceId, or regionId + provinceDisplayName.',
       );

  final String? fullProvinceId;
  final String? regionId;
  final String? provinceDisplayName;
}

final class DebugConsoleRevealProvince extends DebugConsoleParsedInvocation {
  const DebugConsoleRevealProvince({
    required this.target,
    required this.targetIsFullProvinceId,
  });

  final String target;
  final bool targetIsFullProvinceId;
}

final class DebugConsoleGetTileBasicInfo extends DebugConsoleParsedInvocation {
  const DebugConsoleGetTileBasicInfo();
}

final class DebugConsoleListPlayers extends DebugConsoleParsedInvocation {
  const DebugConsoleListPlayers();
}

final class DebugConsoleSetObserveOff extends DebugConsoleParsedInvocation {
  const DebugConsoleSetObserveOff();
}

final class DebugConsoleSetObserveGlobal extends DebugConsoleParsedInvocation {
  const DebugConsoleSetObserveGlobal();
}

final class DebugConsoleSetObservePlayer extends DebugConsoleParsedInvocation {
  const DebugConsoleSetObservePlayer({required this.target});

  final String target;
}

/// `/set_diplomacy` invocation: set a diplomatic relation between two factions.
///
/// [factionA] is `null` for the one-faction form (the active human player is
/// the implicit initiator). [factionB] is always the second faction. Both
/// faction values are raw identifier inputs (id or display name) resolved in
/// the app apply layer. SPEC/ui/debug-console-panel.md.
final class DebugConsoleSetDiplomacy extends DebugConsoleParsedInvocation {
  const DebugConsoleSetDiplomacy({
    required this.factionB,
    required this.action,
    this.factionA,
  });

  final String? factionA;
  final String factionB;
  final DebugDiplomacyAction action;
}
