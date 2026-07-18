/// Debug-console `/set_diplomacy` action tokens.
/// SPEC/ui/debug-console-panel.md, SPEC/program/debug-console-internals.md.
///
/// Concern split from former monolithic `diplomacy.dart` (Refs #4068).

/// Debug-console `/set_diplomacy` mutation actions. Debug tool only: maps to a
/// direct `Game`-state diplomacy mutation, bypassing normal turn resolution.
/// SPEC/ui/debug-console-panel.md, SPEC/program/debug-console-internals.md.
enum DebugDiplomacyAction {
  war,
  peace,
  alliance,
  noAlliance,
  consulate,
  embassy,
  nap,
  joinEmpire,
  clearOverture,
  ftp,
  noFtp,
}

/// Command-keyword binding for [DebugDiplomacyAction] (`/set_diplomacy`).
extension DebugDiplomacyActionTokens on DebugDiplomacyAction {
  /// Canonical lowercase command keyword (e.g. `no_alliance`, `join_empire`).
  String get keyword => switch (this) {
    DebugDiplomacyAction.war => 'war',
    DebugDiplomacyAction.peace => 'peace',
    DebugDiplomacyAction.alliance => 'alliance',
    DebugDiplomacyAction.noAlliance => 'no_alliance',
    DebugDiplomacyAction.consulate => 'consulate',
    DebugDiplomacyAction.embassy => 'embassy',
    DebugDiplomacyAction.nap => 'nap',
    DebugDiplomacyAction.joinEmpire => 'join_empire',
    DebugDiplomacyAction.clearOverture => 'clear_overture',
    DebugDiplomacyAction.ftp => 'ftp',
    DebugDiplomacyAction.noFtp => 'no_ftp',
  };

  /// Resolves a case-insensitive command keyword to its action, or `null`.
  static DebugDiplomacyAction? fromKeyword(String input) {
    final normalized = input.trim().toLowerCase();
    for (final action in DebugDiplomacyAction.values) {
      if (action.keyword == normalized) {
        return action;
      }
    }
    return null;
  }

  /// All supported keywords in stable ascending order (for `/help`).
  static List<String> get sortedKeywords =>
      DebugDiplomacyAction.values.map((a) => a.keyword).toList()..sort();
}
