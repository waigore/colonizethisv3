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

  const factory DebugConsoleParsedInvocation.treasuryCredit({
    required int requestedAmount,
    required int creditedAmount,
  }) = DebugConsoleTreasuryCredit;

  const factory DebugConsoleParsedInvocation.flipProvince({
    required String regionId,
    required String provinceDisplayName,
  }) = DebugConsoleFlipProvince;
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

final class DebugConsoleFlipProvince extends DebugConsoleParsedInvocation {
  const DebugConsoleFlipProvince({
    required this.regionId,
    required this.provinceDisplayName,
  });

  final String regionId;
  final String provinceDisplayName;
}
