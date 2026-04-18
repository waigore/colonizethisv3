// AI configuration per nation: personality, hidden agenda, difficulty. SPEC/program/ai-systems-impl.md.

/// Configuration passed to full AI for one Great Power.
/// Holds canonical leader id for personality lookups, optional personality archetype
/// id for future ruleset overrides, assigned hidden agenda, and difficulty-derived
/// modifiers.
class AIConfig {
  const AIConfig({
    required this.leaderId,
    required this.personalityId,
    required this.hiddenAgendaId,
    this.difficultyModifiers = const {},
  });

  /// Canonical leader id (e.g. 'victoria', 'napoleon').
  /// Used as the key for personality config lookups and dossier/archetype display.
  final String leaderId;

  /// Optional personality archetype id for goal and utility weighting.
  ///
  /// In MVP, colonizethis_ai does not read this field; callers should typically
  /// pass the same canonical id as [leaderId]. Future ruleset-configurable
  /// personality bundles may use this as an override handle.
  final String personalityId;

  /// Assigned hidden agenda id (never exposed to player; used only for modifiers).
  final String hiddenAgendaId;

  /// Difficulty-derived modifiers (e.g. starting resources, ruleset modifiers).
  /// Keys are modifier names; values are numeric or per-ruleset.
  final Map<String, num> difficultyModifiers;
}
