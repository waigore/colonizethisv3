/// Combat resolution mode. SPEC/project/phase-4-project-tasks.md.
/// quick-battle.md: per-battle or settings default; capital sieges must use Quick Battle.
enum CombatMode {
  /// Auto-resolve: single formula, no tactical input.
  autoResolve,

  /// Quick Battle: deployment, up to 3 rounds, CP-based actions.
  quickBattle,
}
