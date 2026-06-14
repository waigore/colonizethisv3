import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'diplomacy_relation_lookup.dart';
import 'diplomacy_relation_updates.dart';

/// Outcome of applying GP–Tribe first-contact relations for one human GP.
/// SPEC/game/diplomacy.md § GP–Tribe first contact (issue #3341).
class GpTribeFirstContactResult {
  const GpTribeFirstContactResult({
    required this.game,
    required this.newlyContactedTribeIds,
  });

  final Game game;

  /// Tribe faction ids that received a new `AT_PEACE` / score-50 relation this pass.
  final List<String> newlyContactedTribeIds;
}

/// For each discovered Tribe without an existing GP–Tribe relation, persist the
/// default neutral first-contact standing (`AT_PEACE`, score 50, Neutral).
///
/// Discovery is intentionally **player-facing**: a Tribe counts as discovered
/// only when the GP holds non-`unknown` tile visibility into a province that
/// Tribe owns (see [discoveredTribeIdsForFirstContact]). Sea-reachable colonial
/// intel alone — which can connect Old World coasts to an unrevealed New World
/// at turn 0 — does **not** trigger the herald or persist a relation (#3463).
/// Broad targeting for the diplomacy panel / declare-war intel still lives in
/// `knownDiplomaticTargetFactionIds`. The [topology] parameter is retained for
/// call-site compatibility but is not consulted by herald discovery.
GpTribeFirstContactResult applyGpTribeFirstContactRelations({
  required Game game,
  required String gpId,
  required PlayerView view,
  required MapTopology topology,
}) {
  final tribeIds = {for (final t in game.tribes) t.id};
  if (tribeIds.isEmpty) {
    return GpTribeFirstContactResult(
      game: game,
      newlyContactedTribeIds: const [],
    );
  }

  final discovered = discoveredTribeIdsForFirstContact(view: view, game: game);
  final turn = game.worldState.turnState.turnNumber;
  var relations = List<DiplomacyRelation>.from(game.diplomacyRelations);
  final newlyContacted = <String>[];

  for (final factionId in discovered) {
    if (!tribeIds.contains(factionId)) continue;
    if (getRelation(game, gpId, factionId) != null) continue;

    final ids = canonicalPairIds(gpId, factionId);
    relations = upsertRelation(
      relations,
      gpId,
      factionId,
      (_) => DiplomacyRelation(
        factionId1: ids.id1,
        factionId2: ids.id2,
        score: relationScoreNeutral,
        level: RelationLevel.neutral,
        state: RelationState.atPeace,
        sinceTurn: turn,
        lastInteractionTurn: turn,
      ),
    );
    newlyContacted.add(factionId);
  }

  if (newlyContacted.isEmpty) {
    return GpTribeFirstContactResult(
      game: game,
      newlyContactedTribeIds: const [],
    );
  }

  newlyContacted.sort();
  return GpTribeFirstContactResult(
    game: game.copyWith(diplomacyRelations: relations),
    newlyContactedTribeIds: newlyContacted,
  );
}

/// Tribe faction ids the human GP has actually **discovered** for first-contact
/// purposes: the GP holds non-`unknown` tile visibility into at least one
/// province owned by that Tribe.
///
/// This is deliberately narrower than `knownDiplomaticTargetFactionIds`: it
/// omits the sea-reachable colonial-intel path so the first-contact herald and
/// the persisted GP–Tribe relation only fire once the New World is genuinely
/// revealed, matching the player-facing "Scouts return from the New World"
/// framing (SPEC/game/diplomacy.md § GP–Tribe first contact; #3463).
Set<String> discoveredTribeIdsForFirstContact({
  required PlayerView view,
  required Game game,
}) {
  final tribeIds = {for (final t in game.tribes) t.id};
  if (tribeIds.isEmpty) return const <String>{};

  final discovered = <String>{};
  final playerId = view.playerId;
  for (final entry in view.visibilityByTile.entries) {
    if (entry.value == VisibilityLevel.unknown) continue;
    final parsed = parseTileKeyCoordinates(entry.key);
    if (parsed == null) continue;
    final regionId = parsed.regionId;
    final provinceLocalId = parsed.provinceLocalId;
    final provinceId = ProvinceId.full(regionId, provinceLocalId);
    final province = view.provinceByRegionAndId(regionId, provinceId);
    final ownerId = province?.ownerId;
    if (ownerId == null || ownerId == playerId) continue;
    if (tribeIds.contains(ownerId)) discovered.add(ownerId);
  }
  return discovered;
}
