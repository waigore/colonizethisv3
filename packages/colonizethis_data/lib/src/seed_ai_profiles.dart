/// Seed [AiProfile]s for the 7 canonical leader personalities.
///
/// The human-editable source of truth is the JSON under `lib/src/profiles/`.
/// Those files are embedded (see [kSeedAiProfileJsonById]) so pure-Dart and
/// Flutter consumers can read seeds without runtime file IO; downstream tools
/// (Observer `--profiles` #3437, GA runner #3439) materialize them to disk from
/// these accessors. SPEC/ai/ai-parameter-registry.md. Refs #3436.
library;

import 'dart:convert';

import 'ai_profile.dart';
import 'seed_ai_profiles_embed.dart';

/// Canonical leader ids in deterministic seed order.
const List<String> seedAiProfileLeaderIds = <String>[
  'victoria',
  'napoleon',
  'isabella',
  'henry',
  'deruyter',
  'frederick',
  'gustavus',
];

final Map<String, AiProfile> _seedAiProfilesById =
    Map<String, AiProfile>.unmodifiable({
      for (final id in seedAiProfileLeaderIds)
        id: AiProfile.fromJson(
          jsonDecode(kSeedAiProfileJsonById[id]!) as Map<String, dynamic>,
        ),
    });

/// Seed profiles keyed by leader id (e.g. `victoria`).
Map<String, AiProfile> get seedAiProfilesById => _seedAiProfilesById;

/// Seed profiles in deterministic leader order.
List<AiProfile> get seedAiProfiles => List<AiProfile>.unmodifiable(
  seedAiProfileLeaderIds.map((id) => _seedAiProfilesById[id]!),
);
