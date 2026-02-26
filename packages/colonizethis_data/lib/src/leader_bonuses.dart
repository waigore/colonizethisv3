/// Leader combat bonus multipliers. SPEC/game/leader-bonuses.md.
/// Applied to melee/effective strength in auto-resolve and Quick Battle.

/// Melee strength multiplier for a leader key. Unknown keys return 1.0.
/// Keys may be exact (e.g. 'napoleon') or variant ids (e.g. 'prussia_reserve_leader').
double leaderCombatBonusMultiplier(String? leaderKey) {
  if (leaderKey == null || leaderKey.isEmpty) return 1.0;
  final exact = _leaderMeleeBonus[leaderKey];
  if (exact != null) return exact;
  final lower = leaderKey.toLowerCase();
  if (lower.contains('napoleon')) return 1.25;
  if (lower.contains('frederick')) return 1.15;
  return 1.0;
}

const Map<String, double> _leaderMeleeBonus = {
  'napoleon': 1.25,
  'frederick': 1.15,
  'reserve': 1.0,
};
