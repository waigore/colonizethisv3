import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/player_view.dart';

import '../orders/order_suggestion_helpers.dart';
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
/// Discovery uses [knownDiplomaticTargetFactionIds] (tile visibility, colonial
/// intel, or existing relation). Only Tribe targets are mutated.
GpTribeFirstContactResult applyGpTribeFirstContactRelations({
  required Game game,
  required String gpId,
  required PlayerView view,
  required MapTopology topology,
}) {
  final tribeIds = {for (final t in game.tribes) t.id};
  if (tribeIds.isEmpty) {
    return GpTribeFirstContactResult(game: game, newlyContactedTribeIds: const []);
  }

  final known = knownDiplomaticTargetFactionIds(
    view: view,
    game: game,
    topology: topology,
  );
  final turn = game.worldState.turnState.turnNumber;
  var relations = List<DiplomacyRelation>.from(game.diplomacyRelations);
  final newlyContacted = <String>[];

  for (final factionId in known) {
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
    return GpTribeFirstContactResult(game: game, newlyContactedTribeIds: const []);
  }

  newlyContacted.sort();
  return GpTribeFirstContactResult(
    game: game.copyWith(diplomacyRelations: relations),
    newlyContactedTribeIds: newlyContacted,
  );
}
