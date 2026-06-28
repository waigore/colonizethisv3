import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Faction ids the player may target with diplomatic suggestions.
///
/// Diplomacy-domain visibility helper: derives the targetable faction set from
/// existing relations and non-`unknown` tile visibility only. This is the
/// single **first-contact** gate for all diplomatic consumers (panel, order
/// suggestions, AI declare-war targeting): a faction becomes a valid diplomatic
/// target once the GP holds a persisted relation with it **or** non-`unknown`
/// tile visibility into a province it owns.
///
/// Sea-reachable colonial intel alone — a topology path from Old World anchors
/// to an unrevealed New World tribe province with zero tile visibility — does
/// **not** make a Tribe a diplomatic target (Refs #3620, supersedes the
/// colonial-intel discovery path from #2509/#3341). Colonial intel still drives
/// non-diplomatic behaviour (Explorer explore prioritization, colonial military
/// scoring) via `reachableNonOwnedProvinceIdsViaSeas` at those call sites.
///
/// Relocated from `orders/order_suggestion_helpers.dart` so the diplomacy
/// domain owns its own targeting logic and never imports `orders/`
/// (one-way `orders -> diplomacy` edge, Refs #3290 Phase 2).
///
/// The [topology] parameter is retained for call-site compatibility (many
/// callers and re-exports pass it) but is no longer consulted for targeting.
///
/// SPEC/program/order-suggestions.md § Diplomatic orders (visibility);
/// SPEC/game/diplomacy.md § GP–Tribe first contact.
Set<String> knownDiplomaticTargetFactionIds({
  required PlayerView view,
  required Game game,
  required MapTopology topology,
}) {
  final knownFactionIds = <String>{};
  final playerId = view.playerId;

  for (final rel in game.diplomacyRelations) {
    if (rel.factionId1 == playerId) {
      knownFactionIds.add(rel.factionId2);
    } else if (rel.factionId2 == playerId) {
      knownFactionIds.add(rel.factionId1);
    }
  }

  for (final entry in view.visibilityByTile.entries) {
    if (entry.value == VisibilityLevel.unknown) continue;
    final parsed = parseTileKeyCoordinates(entry.key);
    if (parsed == null) continue;
    final regionId = parsed.regionId;
    final provinceLocalId = parsed.provinceLocalId;
    final provinceId = ProvinceId.full(regionId, provinceLocalId);
    final province = view.provinceByRegionAndId(regionId, provinceId);
    final ownerId = province?.ownerId;
    if (ownerId != null && ownerId != playerId) {
      knownFactionIds.add(ownerId);
    }
  }

  return knownFactionIds;
}
