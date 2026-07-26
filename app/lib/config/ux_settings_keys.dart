/// Hive `settings` keys for player UX preferences (immediate apply).
abstract final class UxSettingsKeys {
  /// When `true` (default when missing), end-turn confirmation warns about
  /// idle human civilians with no work order. SPEC/ui/next-turn-confirmation.md.
  static const warnIdleCiviliansOnEndTurn = 'ux.warnIdleCiviliansOnEndTurn';
}
