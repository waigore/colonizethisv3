/// A resolved per-leader AI parameter set, serializable to/from JSON profiles.
///
/// Couples to [AiParameterRegistry] as the single source of truth for keys,
/// defaults, bounds, and integer flags. SPEC/ai/ai-parameter-registry.md.
/// Refs #3436.
library;

import 'package:colonizethis_data/package_logger.dart';

import 'ai_parameter_registry.dart';
import 'ai_personality_config.dart';

final _log = packageLogger('ai_profile');

/// The only JSON `schema_version` this loader supports.
const int kAiProfileSchemaVersion = 1;

/// One resolved parameter set for a single leader / Great Power.
class AiProfile {
  const AiProfile({
    required this.schemaVersion,
    required this.profileId,
    required this.displayName,
    required this.parameters,
  });

  /// Supported value: [kAiProfileSchemaVersion].
  final int schemaVersion;

  /// Stable profile identifier (`profile_id`).
  final String profileId;

  /// Human-readable name (`display_name`).
  final String displayName;

  /// Complete parameter set: exactly the [AiParameterRegistry] key set,
  /// defaults-filled, bounds-clamped, and integer-rounded.
  final Map<String, num> parameters;

  /// Builds a profile from decoded JSON.
  ///
  /// - Unsupported `schema_version` → [FormatException].
  /// - Each registered parameter is taken from `parameters[name]` when present,
  ///   else the registry default; the value is clamped to the parameter bounds
  ///   and rounded to an int when the parameter is integer-typed.
  /// - Keys present in JSON but absent from the registry are ignored and logged
  ///   once at `warning` (prefix `data:`).
  factory AiProfile.fromJson(Map<String, dynamic> json) {
    final rawVersion = json['schema_version'];
    if (rawVersion is! int || rawVersion != kAiProfileSchemaVersion) {
      throw FormatException(
        'AiProfile: unsupported schema_version '
        '${rawVersion ?? 'null'} (expected $kAiProfileSchemaVersion)',
      );
    }

    final profileId = json['profile_id'];
    final displayName = json['display_name'];
    if (profileId is! String || profileId.isEmpty) {
      throw const FormatException('AiProfile: missing profile_id string');
    }
    if (displayName is! String || displayName.isEmpty) {
      throw const FormatException('AiProfile: missing display_name string');
    }

    final rawParams = json['parameters'];
    final inputParams = rawParams is Map
        ? rawParams
        : const <String, dynamic>{};

    final resolved = <String, num>{};
    for (final param in AiParameterRegistry.allParams) {
      final raw = inputParams[param.name];
      final source = raw is num ? raw : param.defaultValue;
      resolved[param.name] = _clampAndRound(param, source);
    }

    for (final key in inputParams.keys) {
      if (key is String && AiParameterRegistry.byName(key) == null) {
        _log.warning(
          'profile "$profileId" ignoring unknown parameter key "$key"',
        );
      }
    }

    return AiProfile(
      schemaVersion: rawVersion,
      profileId: profileId,
      displayName: displayName,
      parameters: Map<String, num>.unmodifiable(resolved),
    );
  }

  static num _clampAndRound(AiParameter param, num value) {
    final clamped = value.clamp(param.minValue, param.maxValue);
    return param.isInteger ? clamped.round() : clamped.toDouble();
  }

  /// Serializes to a JSON-encodable map. `fromJson(toJson())` round-trips.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'schema_version': schemaVersion,
    'profile_id': profileId,
    'display_name': displayName,
    'parameters': Map<String, num>.from(parameters),
  };

  /// Registry-keyed value lookup. Throws [ArgumentError] for unknown keys.
  num valueOf(String name) {
    final value = parameters[name];
    if (value == null) {
      throw ArgumentError.value(name, 'name', 'not a registered parameter');
    }
    return value;
  }

  /// Domain weights resolved from this profile (Refs #3437 applies these).
  PersonalityDomainWeights toDomainWeights() => PersonalityDomainWeights(
    economy: valueOf('personalityDomainWeights.economy').round(),
    military: valueOf('personalityDomainWeights.military').round(),
    diplomacy: valueOf('personalityDomainWeights.diplomacy').round(),
    research: valueOf('personalityDomainWeights.research').round(),
  );

  /// Goal weights resolved from this profile.
  PersonalityGoalWeights toGoalWeights() => PersonalityGoalWeights(
    defend: valueOf('personalityGoalWeights.defend').round(),
    expand: valueOf('personalityGoalWeights.expand').round(),
    conquer: valueOf('personalityGoalWeights.conquer').round(),
    trade: valueOf('personalityGoalWeights.trade').round(),
    tech: valueOf('personalityGoalWeights.tech').round(),
    diplomacy: valueOf('personalityGoalWeights.diplomacy').round(),
  );

  /// Thresholds resolved from this profile.
  PersonalityThresholds toThresholds() => PersonalityThresholds(
    warLikelihood: valueOf('personalityThresholds.warLikelihood').round(),
    peaceTendency: valueOf('personalityThresholds.peaceTendency').round(),
    allianceTendency: valueOf('personalityThresholds.allianceTendency').round(),
    researchNaval: valueOf('personalityThresholds.researchNaval').round(),
    researchMilitary: valueOf('personalityThresholds.researchMilitary').round(),
    researchEconomic: valueOf('personalityThresholds.researchEconomic').round(),
    researchExploration: valueOf(
      'personalityThresholds.researchExploration',
    ).round(),
  );

  /// Victory-config override value for [constName] (flat Dart constant key).
  num victoryConfigOverride(String constName) => valueOf(constName);
}
