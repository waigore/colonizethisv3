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
    this.parameterOverrides,
    this.profileId,
  });

  /// Canonical leader id (e.g. 'victoria', 'napoleon').
  /// Used as the key for personality config lookups and dossier/archetype display.
  final String leaderId;

  /// Archetype id for goal and utility weighting ([getDomainWeightsForLeader],
  /// etc.). Resolved from scenario [Player.personalityId] when set, else from
  /// [leaderId]. SPEC/ai/ai-personalities.md.
  final String personalityId;

  /// Assigned hidden agenda id (never exposed to player; used only for modifiers).
  final String hiddenAgendaId;

  /// Difficulty-derived modifiers (e.g. starting resources, ruleset modifiers).
  /// Keys are modifier names; values are numeric or per-ruleset.
  final Map<String, num> difficultyModifiers;

  /// Active `AiProfile` parameter overrides (registry-keyed `name -> num`), or
  /// `null` when no profile is active. When `null`, AI behavior is identical to
  /// the no-profile path. Applied per the override-resolution rule in
  /// `SPEC/ai/ai-profile-overrides.md` (Refs #3437).
  final Map<String, num>? parameterOverrides;

  /// Active profile id (`profile_id`) for trace provenance, or `null` when no
  /// profile is active. SPEC/ai/ai-profile-overrides.md (Refs #3437).
  final String? profileId;
}
