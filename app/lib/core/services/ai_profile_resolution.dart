import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app/package_logger.dart';

final _log = packageLogger('data');

/// Resolves [game.aiProfileByGpId] names against [catalogByName].
///
/// Missing names log a warning and fall back to normal AI for that slot.
/// Returns `null` when no tuned profiles apply.
Map<String, AiProfile>? resolveAiProfilesForGame(
  Game game,
  Map<String, AiProfile> catalogByName,
) {
  if (game.aiProfileByGpId.isEmpty) {
    return null;
  }
  final resolved = <String, AiProfile>{};
  for (final entry in game.aiProfileByGpId.entries) {
    final name = entry.value;
    if (name == null || name.isEmpty) {
      continue;
    }
    final profile = catalogByName[name];
    if (profile == null) {
      _log.w(
        'app:ai_profile missing blessed profile "$name" for gpId=${entry.key}; '
        'using normal AI',
      );
      continue;
    }
    resolved[entry.key] = profile;
  }
  return resolved.isEmpty ? null : resolved;
}

/// Encodes resolved profiles for worker-isolate handoff (gpId → profile JSON).
Map<String, Map<String, dynamic>> encodeAiProfilesForIsolate(
  Map<String, AiProfile>? profiles,
) {
  if (profiles == null || profiles.isEmpty) {
    return const {};
  }
  return {
    for (final entry in profiles.entries) entry.key: entry.value.toJson(),
  };
}

/// Decodes [payload] from worker-isolate args back to [AiProfile] map.
Map<String, AiProfile>? decodeAiProfilesFromIsolate(
  Object? payload,
) {
  if (payload is! Map<Object?, Object?> || payload.isEmpty) {
    return null;
  }
  final decoded = <String, AiProfile>{};
  for (final entry in payload.entries) {
    final gpId = entry.key?.toString();
    final raw = entry.value;
    if (gpId == null || raw is! Map<Object?, Object?>) {
      continue;
    }
    decoded[gpId] = AiProfile.fromJson(
      Map<String, dynamic>.from(raw),
    );
  }
  return decoded.isEmpty ? null : decoded;
}
