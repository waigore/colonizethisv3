/// One row for the shared load-game list. SPEC/program/save-load.md § listLoadableSaves.
enum LoadableSaveKind {
  /// Manual named save under a Hive `gameId` from [GameSaveAdapter.listGameIds].
  manual,

  /// Crash-recovery slot keyed by [kAutoSaveSlotId].
  autoSave,
}

/// Structured load-list entry returned by [GameSaveAdapter.listLoadableSaves].
class LoadableSaveEntry {
  const LoadableSaveEntry({
    required this.storageId,
    required this.label,
    required this.kind,
    this.turnNumber,
  });

  /// Hive key used with [GameSaveAdapter.load] / [GameSaveAdapter.loadSession].
  final String storageId;

  /// User-facing label (`displayName`, id fallback, or fixed "Auto-save").
  final String label;

  final LoadableSaveKind kind;

  /// Turn number from the envelope `game` payload when readable; otherwise null.
  final int? turnNumber;
}
