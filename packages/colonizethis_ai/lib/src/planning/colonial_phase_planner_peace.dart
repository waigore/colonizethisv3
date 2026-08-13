import '../perception/perception_snapshot.dart';
import 'observer_goal_phase.dart' show primaryColonialGpBlocker;
import 'planning_helpers.dart' show gpFactionIdsAtWarWith;
import 'planning_imports.dart';

/// Returns at-war Great Powers the active player should `offerPeace` toward in
/// COLONIAL, excluding the primary colonial NW blocker and below-quota peers
/// (issue #2509 § planColonialPeace). Pure and deterministic.
List<String> planColonialPeace({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final gpWars = gpFactionIdsAtWarWith(game, snapshot);
  if (gpWars.isEmpty) {
    return const [];
  }

  final blocker = primaryColonialGpBlocker(game: game, snapshot: snapshot);

  final result = <String>[
    for (final factionId in gpWars)
      if (factionId != blocker &&
          !isBelowObserverConquestQuota(
            oldWorldProvinceCountOwnedBy(game, factionId),
          ))
        factionId,
  ]..sort();
  return result;
}
