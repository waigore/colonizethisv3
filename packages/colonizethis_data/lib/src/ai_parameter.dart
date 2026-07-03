/// Tunable AI-parameter declaration and its category metadata.
///
/// Extracted from `ai_parameter_registry.dart` so the registry assembly and the
/// large victory-config parameter list (`ai_parameter_victory_config_params.dart`)
/// share these types through ordinary `import`s rather than a `part` fragment,
/// keeping each file under the repo non-comment line-size gate
/// (SPEC/program/dart-file-non-comment-line-size.md). SPEC/ai/ai-parameter-registry.md.
library;

/// Parameter categories. Metadata only — never part of the canonical key.
abstract final class AiParameterCategory {
  static const String personalityDomain = 'personality_domain';
  static const String personalityGoal = 'personality_goal';
  static const String personalityThreshold = 'personality_threshold';
  static const String victoryConfig = 'victory_config';
}

/// A single tunable AI parameter declaration.
class AiParameter {
  const AiParameter({
    required this.name,
    required this.category,
    required this.isInteger,
    required this.minValue,
    required this.maxValue,
    required this.defaultValue,
    required this.description,
  });

  /// Canonical key. Personality params: `<sourceMapName>.<fieldName>`.
  /// Victory-config params: the flat Dart constant identifier.
  final String name;

  /// One of [AiParameterCategory]; metadata only, not part of [name].
  final String category;

  /// True for `int`-typed source constants, false for `double`.
  final bool isInteger;

  /// Inclusive lower bound used when clamping profile values.
  final num minValue;

  /// Inclusive upper bound used when clamping profile values.
  final num maxValue;

  /// Current hardcoded value of the source constant.
  final num defaultValue;

  /// Human-readable summary of what this parameter controls.
  final String description;
}
