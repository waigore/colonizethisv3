import 'player_view.dart';

/// For tiles in a province whose spy-reveal timer just reached 0: if stored
/// visibility is [VisibilityLevel.fullyVisible], set it to [VisibilityLevel.fogged];
/// leave `unknown` and `fogged` unchanged. SPEC/program/fog-and-exploration-resolution.md
/// (Spy fog decay).
void downgradeFullyVisibleTilesToFoggedAfterSpyTimerExpiry(
  Map<String, String> vis,
  List<String> tileKeys,
) {
  for (final tk in tileKeys) {
    final cur = vis[tk];
    if (cur == VisibilityLevel.fullyVisible.name) {
      vis[tk] = VisibilityLevel.fogged.name;
    }
  }
}

/// One end-of-turn decay step for a single player's spy-reveal timers.
///
/// Skips provinces owned by [playerId] (timers must not affect own provinces).
/// For each other-faction province entry, decrements the turn count; when the
/// count would reach 0 or below, applies [downgradeFullyVisibleTilesToFoggedAfterSpyTimerExpiry]
/// using [landTileKeysForProvince] and omits that province from the returned map.
/// Otherwise stores `turns - 1` for the province.
///
/// Mutates [playerVisibility] in place when a timer expires.
/// SPEC/program/fog-and-exploration-resolution.md (Spy fog decay).
Map<String, int> nextSpyRevealTimersByProvinceAfterDecayStep({
  required String playerId,
  required Map<String, int> byProvince,
  required Map<String, String?> ownerByProvinceId,
  required Map<String, String> playerVisibility,
  required List<String> Function(String provinceId) landTileKeysForProvince,
}) {
  final newByProvince = <String, int>{};
  for (final provEntry in byProvince.entries) {
    final provinceId = provEntry.key;
    final turns = provEntry.value;

    final ownerId = ownerByProvinceId[provinceId];
    if (ownerId == playerId) {
      continue;
    }

    final nextTurns = turns - 1;
    if (nextTurns <= 0) {
      final tileKeys = landTileKeysForProvince(provinceId);
      downgradeFullyVisibleTilesToFoggedAfterSpyTimerExpiry(
        playerVisibility,
        tileKeys,
      );
    } else {
      newByProvince[provinceId] = nextTurns;
    }
  }
  return newByProvince;
}
