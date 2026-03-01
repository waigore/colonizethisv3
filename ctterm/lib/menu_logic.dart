// Pure logic for main menu state. Testable without Nocterm. SPEC/tui/ctterm.md.

/// Returns true when Load Game should be enabled (at least one save exists).
bool isLoadGameEnabled(List<String> gameIds) => gameIds.isNotEmpty;
