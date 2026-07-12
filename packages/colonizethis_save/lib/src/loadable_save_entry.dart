/// One row for the shared load-game list.
/// SPEC/program/save-load.md § listLoadableSaves; SPEC/program/save-load-list-metadata.md.
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
    this.calendarYear,
    this.humanNation,
    this.lastSavedAt,
  });

  /// Hive key used with [GameSaveAdapter.load] / [GameSaveAdapter.loadSession].
  final String storageId;

  /// User-facing label (`displayName`, id fallback, or fixed "Auto-save").
  final String label;

  final LoadableSaveKind kind;

  /// Turn number from envelope `listMeta` when present.
  final int? turnNumber;

  /// Calendar year from envelope `listMeta` when present.
  final int? calendarYear;

  /// Human GP nation label from envelope `listMeta` when present.
  final String? humanNation;

  /// Last-saved wall-clock time (UTC) from envelope `listMeta`.
  final DateTime? lastSavedAt;
}
