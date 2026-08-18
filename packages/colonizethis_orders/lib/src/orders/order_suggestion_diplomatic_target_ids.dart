import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';

/// Known diplomatic targets for one suggestion pass (Refs #3877).
final class DiplomaticSuggestionTargetIds {
  const DiplomaticSuggestionTargetIds({
    required this.knownFactionIds,
    required this.knownTargetIds,
    required this.otherGpIds,
  });

  final Set<String> knownFactionIds;
  final Set<String> knownTargetIds;
  final Set<String> otherGpIds;
}

/// Resolves visible GP / Minor / Tribe targets for diplomatic suggestion passes.
DiplomaticSuggestionTargetIds resolveDiplomaticSuggestionTargetIds({
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required DiplomacyFactionMembership factionMembership,
  required String playerId,
}) {
  final knownFactionIds = knownDiplomaticTargetFactionIds(
    view: view,
    game: game,
    topology: topology,
  );
  final otherGpIds = factionMembership.greatPowerIds.difference({playerId});
  final knownTargets = <String>{
    ...otherGpIds.where(knownFactionIds.contains),
    ...factionMembership.minorOrTribeIds.where(knownFactionIds.contains),
  };
  return DiplomaticSuggestionTargetIds(
    knownFactionIds: knownFactionIds,
    knownTargetIds: knownTargets,
    otherGpIds: otherGpIds,
  );
}

/// Per-target view inputs for diplomatic suggestion candidate builders.
final class DiplomaticSuggestionTargetView {
  const DiplomaticSuggestionTargetView({
    required this.targetId,
    required this.player,
    required this.knownTargetIds,
    required this.knownFactionIds,
    required this.playerOverturesByTargetId,
    required this.playerHoldsColony,
  });

  final String targetId;
  final Player player;
  final Set<String> knownTargetIds;
  final Set<String> knownFactionIds;
  final Map<String, OvertureState> playerOverturesByTargetId;
  final bool playerHoldsColony;

  int get treasury => player.treasury;
}
