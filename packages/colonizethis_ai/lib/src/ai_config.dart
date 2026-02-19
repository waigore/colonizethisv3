// AI configuration per nation: personality, hidden agenda, difficulty. SPEC/program/ai-systems-impl.md.

/// Configuration passed to full AI for one Great Power.
/// Holds leader personality id, assigned hidden agenda, and difficulty-derived modifiers.
class AIConfig {
  const AIConfig({
    required this.leaderId,
    required this.personalityId,
    required this.hiddenAgendaId,
    this.difficultyModifiers = const {},
  });

  /// Leader id (e.g. 'victoria', 'napoleon').
  final String leaderId;

  /// Personality archetype id for goal and utility weighting.
  final String personalityId;

  /// Assigned hidden agenda id (never exposed to player; used only for modifiers).
  final String hiddenAgendaId;

  /// Difficulty-derived modifiers (e.g. starting resources, ruleset modifiers).
  /// Keys are modifier names; values are numeric or per-ruleset.
  final Map<String, num> difficultyModifiers;
}
